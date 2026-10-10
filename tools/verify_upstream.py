"""Verify imported skill bytes against independently acquired pinned sources."""

import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import stat
import subprocess
import sys
import tempfile
from urllib.parse import quote, unquote, urlsplit
import urllib.request
import zipfile


NAME = r'[a-z0-9]+(?:-[a-z0-9]+)*'
HASH = r'[0-9a-f]{64}'
REPOSITORY = r'https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+'


class VerificationError(ValueError):
    pass


def require(condition, message):
    if not condition:
        raise VerificationError(message)


def read_json(path):
    return json.loads(path.read_text(encoding='utf-8'))


def relative_path(value):
    require(isinstance(value, str) and value and '\\' not in value and ':' not in value,
            f'Invalid relative path: {value!r}')
    path = PurePosixPath(value)
    require(not path.is_absolute() and all(p not in ('', '.', '..') for p in value.split('/')),
            f'Unsafe relative path: {value!r}')
    return value


def skill_names(value):
    require(isinstance(value, list) and all(isinstance(n, str) and re.fullmatch(NAME, n)
                                          for n in value), 'Expected a list of skill names')
    require(len(set(value)) == len(value), 'Duplicate skill name')
    return set(value)


def validate_record(record):
    require(isinstance(record, dict), 'Source record must be an object')
    version = record.get('schemaVersion')
    require(type(version) is int and version in (1, 2),
            'Unsupported source-record schemaVersion')
    fields = {'schemaVersion', 'provider', 'root', 'source', 'files', 'dependencies'}
    require(set(record) == fields | ({'pathMap'} if version == 2 else set()),
            'Source record has missing or unknown fields')
    if version == 2:
        require(record['pathMap'] == {'SKILL.md': 'UPSTREAM.md'},
                'Version 2 pathMap must map only SKILL.md to UPSTREAM.md')
    relative_path(record['root'])
    skill_names(record['dependencies'])
    source = record['source']
    require(isinstance(source, dict), 'Source must be an object')
    required = {'url', 'revision', 'subtree'}
    require(record['provider'] in ('git', 'github-release-zip'), 'Unsupported source provider')
    if record['provider'] == 'github-release-zip':
        required |= {'assetId'}
    allowed = required | ({'archiveSha256'} if record['provider'] == 'github-release-zip' else set())
    require(required <= set(source) <= allowed, 'Source has missing or unknown fields')
    require(isinstance(source['url'], str) and re.fullmatch(REPOSITORY, source['url']),
            'Source URL must be an HTTPS GitHub repository URL')
    relative_path(source['subtree'])
    require(isinstance(source['revision'], str), 'Source revision must be a string')
    if record['provider'] == 'git':
        require(re.fullmatch(r'[0-9a-f]{40}', source['revision']), 'Git revision must be a full commit SHA')
    else:
        require(source['revision'] and type(source['assetId']) is int and source['assetId'] > 0,
                'Archive source needs a release tag and positive assetId')
        if 'archiveSha256' in source:
            require(isinstance(source['archiveSha256'], str) and
                    re.fullmatch(HASH, source['archiveSha256']), 'Invalid archive SHA-256')
    files = record['files']
    require(isinstance(files, dict) and 'SKILL.md' in files, 'Source file inventory must include SKILL.md')
    require(len({p.casefold() for p in files}) == len(files), 'Case-colliding source paths')
    for path, digest in files.items():
        relative_path(path)
        require(isinstance(digest, str) and re.fullmatch(HASH, digest), f'Invalid SHA-256: {path}')
    if version == 2:
        mapped = [record['pathMap'].get(path, path) for path in files]
        require(len({path.casefold() for path in mapped}) == len(mapped),
                'Case-colliding packaged paths after mapping')
        require(not any(PurePosixPath(path).name.casefold() == 'skill.md' for path in mapped),
                'Mapped source contains another discoverable SKILL.md; review packaging separately')


def regular_tree(directory):
    require(directory.is_dir() and not directory.is_symlink() and not directory.is_junction(),
            f'Expected a regular source directory: {directory}')
    files = {}
    for path in directory.rglob('*'):
        require(not path.is_symlink() and not path.is_junction(), f'Source link is not a file: {path}')
        if path.is_file():
            files[relative_path(path.relative_to(directory).as_posix())] = path
    return files


def packaged_source(path):
    """Read a plain subtree or its discovery-safe ZIP without extracting it."""
    require(not path.is_symlink() and not path.is_junction(),
            f'Source root must not be a link: {path}')
    if path.is_dir():
        return {name: file.read_bytes() for name, file in regular_tree(path).items()}
    require(path.is_file() and path.suffix == '.zip',
            f'Expected a source directory or ZIP: {path}')
    files = {}
    with zipfile.ZipFile(path) as archive:
        for entry in archive.infolist():
            name = relative_path(entry.filename)
            require(name not in files, 'Duplicate packaged member: ' + name)
            mode = stat.S_IFMT(entry.external_attr >> 16)
            require(not entry.is_dir() and mode in (0, stat.S_IFREG),
                    'Packaged member must be a regular file: ' + name)
            files[name] = archive.read(entry)
    return files


def local_links(file, root):
    text = file.read_text(encoding='utf-8')
    # Only actual inline Markdown links; examples in fenced blocks are not loading pointers.
    text = re.sub(r'(?ms)^```[^\n]*\n.*?^```\s*$', '', text)
    links = set()
    for target in re.findall(r'\]\(([^\s)]+)\)', text):
        parsed = urlsplit(target.strip('<>'))
        if parsed.scheme or parsed.netloc or not parsed.path:
            continue
        destination = (file.parent / unquote(parsed.path)).resolve()
        require(destination.is_relative_to(root) and destination.exists(),
                f'{file.name}: broken or escaping local link {target}')
        links.add(destination)
    return links


def git(*args):
    environment = dict(os.environ, GIT_TERMINAL_PROMPT='0')
    result = subprocess.run(['git', *args], capture_output=True, check=False,
                            env=environment, timeout=180)
    require(result.returncode == 0,
            'Git source acquisition failed: ' + result.stderr.decode('utf-8', errors='replace').strip())
    return result.stdout


class Sources:
    """Acquire each pinned repository once per invocation, never at skill runtime."""

    def __init__(self, directory):
        self.directory = Path(directory)
        self.repositories = {}
        self.archives = {}

    def files(self, record):
        source = record['source']
        if record['provider'] == 'github-release-zip':
            return self.archive_files(source)
        key = (source['url'], source['revision'])
        if key not in self.repositories:
            repository = self.directory / str(len(self.repositories))
            git('init', '--bare', str(repository))
            git('-C', str(repository), 'fetch', '--no-tags', '--depth=1',
                source['url'], source['revision'])
            actual = git('-C', str(repository), 'rev-parse', 'FETCH_HEAD').decode().strip()
            require(actual == source['revision'], 'Fetched revision differs from source record')
            self.repositories[key] = repository
        repository = self.repositories[key]
        prefix = source['subtree'] + '/'
        tree = git('-C', str(repository), '--literal-pathspecs', 'ls-tree', '-rz',
                   source['revision'], '--', prefix)
        files = {}
        for entry in tree.split(b'\0'):
            if not entry:
                continue
            metadata, raw_path = entry.split(b'\t', 1)
            mode, kind, object_id = metadata.split()
            require(mode in (b'100644', b'100755') and kind == b'blob',
                    'Source contains a symlink or non-regular file')
            path = raw_path.decode('utf-8')
            require(path.startswith(prefix), 'Source path outside selected subtree')
            name = relative_path(path[len(prefix):])
            files[name] = git('-C', str(repository), 'cat-file', 'blob', object_id.decode())
        return files

    def archive_files(self, source):
        key = (source['url'], source['revision'], source['assetId'])
        if key not in self.archives:
            repository = source['url'].removeprefix('https://github.com/').removesuffix('.git')
            api = (f'https://api.github.com/repos/{repository}/releases/tags/'
                   + quote(source['revision'], safe=''))
            request = urllib.request.Request(api, headers={
                'Accept': 'application/vnd.github+json', 'User-Agent': 'myst-source-verifier'})
            with urllib.request.urlopen(request, timeout=60) as response:
                release = json.load(response)
            require(release.get('tag_name') == source['revision'], 'Release tag differs from record')
            assets = [a for a in release.get('assets', []) if a['id'] == source['assetId']]
            require(len(assets) == 1, 'Pinned asset is absent from the recorded release')
            download = assets[0]['browser_download_url']
            require(download.startswith(f'https://github.com/{repository}/releases/download/'),
                    'Unexpected release asset download URL')
            archive_path = self.directory / f'archive-{len(self.archives)}.zip'
            request = urllib.request.Request(download, headers={'User-Agent': 'myst-source-verifier'})
            with urllib.request.urlopen(request, timeout=60) as response, archive_path.open('wb') as file:
                shutil.copyfileobj(response, file)
            with archive_path.open('rb') as file:
                digest = hashlib.file_digest(file, 'sha256').hexdigest()
            self.archives[key] = (archive_path, digest)
        archive_path, digest = self.archives[key]
        if 'archiveSha256' in source:
            require(digest == source['archiveSha256'], 'Downloaded archive digest differs from record')
        prefix = source['subtree'] + '/'
        files = {}
        with zipfile.ZipFile(archive_path) as archive:
            for entry in archive.infolist():
                if not entry.filename.startswith(prefix) or entry.is_dir():
                    continue
                name = relative_path(entry.filename[len(prefix):])
                require(name not in files, 'Duplicate archive member: ' + name)
                require(not stat.S_ISLNK(entry.external_attr >> 16), 'Archive source contains a symlink')
                files[name] = archive.read(entry)  # ZipFile checks member CRCs on read.
        return files


def verify(root, require_complete):
    skills = root / 'plugins/myst-dev-kit/skills'
    policy = read_json(root / 'upstream-policy.json')
    require(isinstance(policy, dict) and set(policy) == {'localSkills', 'pendingImports'},
            'Migration policy has missing or unknown fields')
    local = skill_names(policy['localSkills'])
    pending = skill_names(policy['pendingImports'])
    require(not local & pending, 'A skill cannot be both local and pending import')
    require(not require_complete or not pending, 'Migration debt remains: ' + ', '.join(sorted(pending)))
    names = {p.name for p in skills.iterdir() if p.is_dir()}
    require((local | pending) <= names, 'Policy names a missing skill')
    verified = 0
    with tempfile.TemporaryDirectory(prefix='myst-upstream-') as directory:
        sources = Sources(directory)
        for name in sorted(names):
            package = skills / name
            record_file = package / 'UPSTREAM.json'
            if not record_file.exists():
                require(name in local | pending, f'{name}: undeclared import or local skill')
                continue
            require(name not in local | pending, f'{name}: remove stale local/pending classification')
            record = read_json(record_file)
            validate_record(record)
            raw_root = package / relative_path(record['root'])
            expected = record['files']
            require(raw_root.resolve().is_relative_to(package.resolve()), f'{name}: source root escapes package')
            if record['schemaVersion'] == 2:
                require(raw_root.is_dir(), f'{name}: mapped source must be a directory')
            paths = {path: record.get('pathMap', {}).get(path, path) for path in expected}
            actual = packaged_source(raw_root)
            require(set(actual) == set(paths.values()), f'{name}: imported file inventory differs')
            loading_target = raw_root / paths['SKILL.md'] if raw_root.is_dir() else raw_root
            require(loading_target.resolve() in local_links(package / 'SKILL.md', root),
                    f'{name}: entry point must link to the packaged upstream entry or its source ZIP')
            require(record_file.resolve() in local_links(package / 'PROVENANCE.md', root),
                    f'{name}: provenance must link to UPSTREAM.json')
            for dependency in record['dependencies']:
                require(dependency != name and (skills / dependency / 'SKILL.md').is_file(),
                        f'{name}: missing or self-referencing dependency {dependency}')
            for path, packaged_path in paths.items():
                data = actual[packaged_path]
                require(hashlib.sha256(data).hexdigest() == expected[path],
                        f'{name}/{path}: imported bytes differ from recorded hash')
            original = sources.files(record)
            require(set(original) == set(expected), f'{name}: pinned source inventory differs')
            for path, data in original.items():
                require(hashlib.sha256(data).hexdigest() == expected[path],
                        f'{name}/{path}: recorded hash differs from independently acquired source')
            verified += 1
    print(f'Verified {verified} imported bundles against pinned source; '
          f'{len(pending)} declared pending imports; {len(local)} local skills.')
    if pending:
        print('Migration debt: ' + ', '.join(sorted(pending)))


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--require-complete', action='store_true',
                        help='Release gate: reject all remaining declared migration debt')
    args = parser.parse_args(argv)
    try:
        verify(args.root.resolve(), args.require_complete)
    except (VerificationError, OSError, ValueError, KeyError, TypeError,
            zipfile.BadZipFile, subprocess.TimeoutExpired) as error:
        print(f'FAIL: {error}', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
