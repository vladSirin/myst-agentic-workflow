"""Acceptance tests for the repository verifier, using disposable source repos."""

import contextlib
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
import urllib.request
from unittest.mock import patch
import zipfile


SCRIPT = Path(__file__).resolve().parents[1] / 'tools' / 'verify_upstream.py'
spec = importlib.util.spec_from_file_location('verify_upstream', SCRIPT)
verifier = importlib.util.module_from_spec(spec)
spec.loader.exec_module(verifier)


class VerifyUpstreamTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name) / 'consumer'
        self.package = self.root / 'plugins/myst-dev-kit/skills/example'
        self.raw = self.package / 'upstream'
        self.raw.mkdir(parents=True)
        self.original = {'SKILL.md': b'---\nname: example\n---\nRead companion.\n',
                         'companion.md': b'Original companion.\n'}
        self.origin = Path(self.temp.name) / 'origin'
        source = self.origin / 'skills/example'
        source.mkdir(parents=True)
        for name, data in self.original.items():
            (source / name).write_bytes(data)
            (self.raw / name).write_bytes(data)
        self.run_git('init', str(self.origin))
        self.run_git('-C', str(self.origin), 'config', 'core.autocrlf', 'false')
        self.run_git('-C', str(self.origin), 'add', '.')
        self.run_git('-C', str(self.origin), '-c', 'user.name=Fixture',
                     '-c', 'user.email=fixture@example.invalid', 'commit', '-m', 'source')
        revision = self.run_git('-C', str(self.origin), 'rev-parse', 'HEAD').strip()
        self.record = {'schemaVersion': 1, 'provider': 'git', 'root': 'upstream',
                       'source': {'url': 'https://github.com/example/skills',
                                  'revision': revision, 'subtree': 'skills/example'},
                       'files': {name: hashlib.sha256(data).hexdigest()
                                 for name, data in self.original.items()},
                       'dependencies': []}
        self.save_record()
        (self.package / 'SKILL.md').write_text('[Source](upstream/SKILL.md)\n')
        (self.package / 'PROVENANCE.md').write_text('[Record](UPSTREAM.json)\n')
        (self.root / 'upstream-policy.json').write_text(json.dumps(
            {'localSkills': [], 'pendingImports': []}))

    @staticmethod
    def run_git(*args):
        return subprocess.run(['git', *args], check=True, capture_output=True,
                              text=True).stdout

    def save_record(self):
        (self.package / 'UPSTREAM.json').write_text(json.dumps(self.record))

    def verify(self, *args):
        run = subprocess.run

        def transport(command, **kwargs):
            # Stub only the external Git transport. Git object reads remain real.
            command = [str(self.origin) if x == self.record['source']['url'] else x
                       for x in command]
            return run(command, **kwargs)

        output = io.StringIO()
        with patch.object(subprocess, 'run', side_effect=transport), \
                contextlib.redirect_stdout(output), contextlib.redirect_stderr(output):
            status = verifier.main(['--root', str(self.root), *args])
        return status, output.getvalue()

    def test_valid_bundle_and_wrapper_edit_pass(self):
        status, output = self.verify()
        self.assertEqual(status, 0, output)
        with (self.package / 'SKILL.md').open('a') as file:
            file.write('\nA local wrapper clarification.\n')
        status, output = self.verify('--require-complete')
        self.assertEqual(status, 0, output)

    def package_zip(self, files=None):
        with zipfile.ZipFile(self.package / 'upstream.zip', 'w') as archive:
            for name, data in (self.original if files is None else files).items():
                archive.writestr(name, data)
        self.record['root'] = 'upstream.zip'
        self.save_record()
        (self.package / 'SKILL.md').write_text('Read SKILL.md in [Source](upstream.zip).\n')

    def test_packaged_zip_verifies_original_members_and_loading_link(self):
        self.package_zip()
        status, output = self.verify('--require-complete')
        self.assertEqual(status, 0, output)
        (self.package / 'SKILL.md').write_text('Missing archive pointer.\n')
        status, output = self.verify()
        self.assertEqual(status, 1, output)
        self.assertIn('entry point must link', output)

    def test_packaged_zip_cannot_hide_changed_missing_or_extra_members(self):
        cases = [dict(self.original, **{'SKILL.md': b'Changed'}),
                 {'SKILL.md': self.original['SKILL.md']},
                 dict(self.original, **{'extra.txt': b'Extra'})]
        for files in cases:
            with self.subTest(files=files):
                self.package_zip(files)
                status, output = self.verify()
                self.assertEqual(status, 1, output)

    def test_packaged_zip_rehashed_edit_fails_independent_comparison(self):
        changed = dict(self.original, **{'SKILL.md': b'Changed'})
        self.package_zip(changed)
        self.record['files']['SKILL.md'] = hashlib.sha256(b'Changed').hexdigest()
        self.save_record()
        status, output = self.verify()
        self.assertEqual(status, 1, output)
        self.assertIn('independently acquired source', output)

    def test_packaged_zip_rejects_unsafe_duplicate_and_link_members(self):
        self.package_zip()
        cases = [('escape', '../SKILL.md', b'escape'),
                 ('duplicate', 'SKILL.md', self.original['SKILL.md']),
                 ('link', 'link.md', b'SKILL.md')]
        for kind, name, data in cases:
            with self.subTest(kind=kind):
                self.package_zip()
                with zipfile.ZipFile(self.package / 'upstream.zip', 'a') as archive:
                    member = zipfile.ZipInfo(name)
                    if kind == 'link':
                        member.create_system = 3
                        member.external_attr = 0o120777 << 16
                    with self.assertWarns(UserWarning) if kind == 'duplicate' else contextlib.nullcontext():
                        archive.writestr(member, data)
                status, output = self.verify()
                self.assertEqual(status, 1, output)
                self.assertRegex(output, 'Unsafe relative path|Duplicate packaged member|regular file')

    def test_packaged_zip_rejects_corruption(self):
        self.package_zip()
        (self.package / 'upstream.zip').write_bytes(b'not a zip')
        status, output = self.verify()
        self.assertEqual(status, 1, output)
        self.assertIn('zip', output.lower())

    def test_changed_source_is_rejected(self):
        (self.raw / 'SKILL.md').write_bytes(b'Locally rewritten source.\n')
        status, output = self.verify()
        self.assertEqual(status, 1, output)
        self.assertIn('recorded hash', output)

    def test_missing_companion_is_rejected(self):
        (self.raw / 'companion.md').unlink()
        status, output = self.verify()
        self.assertEqual(status, 1, output)
        self.assertIn('inventory', output)

    def test_extra_source_file_is_rejected(self):
        (self.raw / 'extra.md').write_text('not upstream')
        status, output = self.verify()
        self.assertEqual(status, 1, output)
        self.assertIn('inventory', output)

    def test_rehashed_edit_cannot_bless_modified_source(self):
        data = b'Locally rewritten and rehashed.\n'
        (self.raw / 'SKILL.md').write_bytes(data)
        self.record['files']['SKILL.md'] = hashlib.sha256(data).hexdigest()
        self.save_record()
        status, output = self.verify()
        self.assertEqual(status, 1, output)
        self.assertIn('independently acquired source', output)

    def test_omitting_companion_from_record_cannot_bless_incomplete_import(self):
        (self.raw / 'companion.md').unlink()
        del self.record['files']['companion.md']
        self.save_record()
        status, output = self.verify()
        self.assertEqual(status, 1, output)
        self.assertIn('pinned source inventory', output)

    def test_wrapper_must_link_to_source_and_provenance_to_record(self):
        for name in ('SKILL.md', 'PROVENANCE.md'):
            with self.subTest(file=name):
                file = self.package / name
                original = file.read_text()
                file.write_text('No loading pointer.\n')
                status, output = self.verify()
                self.assertEqual(status, 1, output)
                self.assertIn('link', output)
                file.write_text(original)

    def test_missing_declared_dependency_is_rejected(self):
        self.record['dependencies'] = ['absent-skill']
        self.save_record()
        status, output = self.verify()
        self.assertEqual(status, 1, output)
        self.assertIn('dependency', output)

    def test_record_rejects_unknown_version_mutable_pin_and_escaping_root(self):
        for field, value in [('schemaVersion', 3), ('root', '../outside'), ('extra', True)]:
            with self.subTest(field=field):
                original = dict(self.record)
                self.record[field] = value
                self.save_record()
                status, output = self.verify()
                self.assertEqual(status, 1, output)
                self.record = original
        self.record['source']['revision'] = 'main'
        self.save_record()
        status, output = self.verify()
        self.assertEqual(status, 1, output)

    def test_pending_import_is_explicit_debt_and_blocks_release(self):
        (self.package / 'UPSTREAM.json').unlink()
        policy = self.root / 'upstream-policy.json'
        status, output = self.verify()
        self.assertEqual(status, 1, output)
        policy.write_text(json.dumps({'localSkills': [], 'pendingImports': ['example']}))
        status, output = self.verify()
        self.assertEqual(status, 0, output)
        self.assertIn('0 imported bundles', output)
        self.assertIn('1 declared pending', output)
        status, output = self.verify('--require-complete')
        self.assertEqual(status, 1, output)
        self.assertIn('Migration debt', output)

    def package_mapped(self):
        (self.raw / 'SKILL.md').rename(self.raw / 'UPSTREAM.md')
        self.record.update(schemaVersion=2, pathMap={'SKILL.md': 'UPSTREAM.md'})
        self.save_record()
        (self.package / 'SKILL.md').write_text('[Source](upstream/UPSTREAM.md)\n')

    def test_mapped_directory_preserves_original_inventory(self):
        self.package_mapped()
        status, output = self.verify('--require-complete')
        self.assertEqual(status, 0, output)
        self.assertEqual((self.raw / 'UPSTREAM.md').read_bytes(), self.original['SKILL.md'])
        (self.package / 'SKILL.md').write_text('[Companion](upstream/companion.md)\n')
        status, output = self.verify()
        self.assertEqual(status, 1, output)
        self.assertIn('entry point must link', output)

    def test_mapped_directory_rejects_changed_missing_extra_and_rehashed_source(self):
        self.package_mapped()
        entry = self.raw / 'UPSTREAM.md'
        entry.write_bytes(b'changed')
        status, output = self.verify()
        self.assertEqual(status, 1, output)
        self.assertIn('recorded hash', output)
        self.record['files']['SKILL.md'] = hashlib.sha256(b'changed').hexdigest()
        self.save_record()
        status, output = self.verify()
        self.assertEqual(status, 1, output)
        self.assertIn('independently acquired source', output)
        entry.unlink()
        status, output = self.verify()
        self.assertEqual(status, 1, output)
        self.assertIn('inventory', output)
        entry.write_bytes(self.original['SKILL.md'])
        (self.raw / 'SKILL.md').write_bytes(self.original['SKILL.md'])
        status, output = self.verify()
        self.assertEqual(status, 1, output)
        self.assertIn('inventory', output)

    def test_mapped_directory_cannot_omit_a_companion_from_both_record_and_package(self):
        self.package_mapped()
        (self.raw / 'companion.md').unlink()
        del self.record['files']['companion.md']
        self.save_record()
        status, output = self.verify()
        self.assertEqual(status, 1, output)
        self.assertIn('pinned source inventory', output)

    def test_mapping_rejects_missing_unsafe_or_unapproved_renames(self):
        self.package_mapped()
        for mapping in [None, {}, {'SKILL.md': '../UPSTREAM.md'},
                        {'SKILL.md': 'C:/UPSTREAM.md'}, {'SKILL.md': 'companion.md'},
                        {'SKILL.md': 'UPSTREAM.md', 'companion.md': 'elsewhere.md'}]:
            with self.subTest(mapping=mapping):
                self.record['pathMap'] = mapping
                self.save_record()
                status, output = self.verify()
                self.assertEqual(status, 1, output)
                self.assertIn('pathMap', output)
        del self.record['pathMap']
        self.save_record()
        status, output = self.verify()
        self.assertEqual(status, 1, output)
        self.assertIn('missing or unknown fields', output)

    def test_mapping_rejects_collision_with_unmapped_source_path(self):
        self.package_mapped()
        for name in ['UPSTREAM.md', 'upstream.md']:
            with self.subTest(name=name):
                self.record['files'][name] = hashlib.sha256(b'other source').hexdigest()
                self.save_record()
                status, output = self.verify()
                self.assertEqual(status, 1, output)
                self.assertIn('Case-colliding packaged paths', output)
                del self.record['files'][name]

    def test_mapping_rejects_nested_discovery_entry(self):
        self.package_mapped()
        self.record['files']['nested/SKILL.md'] = self.record['files']['SKILL.md']
        self.save_record()
        status, output = self.verify()
        self.assertEqual(status, 1, output)
        self.assertIn('discoverable SKILL.md', output)

    def test_mapping_is_not_accepted_in_version_one_or_zip_packages(self):
        self.package_mapped()
        self.record['schemaVersion'] = 1
        self.save_record()
        status, output = self.verify()
        self.assertEqual(status, 1, output)
        self.assertIn('missing or unknown fields', output)
        self.record['schemaVersion'] = 2
        self.package_zip()
        status, output = self.verify()
        self.assertEqual(status, 1, output)
        self.assertIn('mapped source must be a directory', output)

    def archive_fixture(self):
        buffer = io.BytesIO()
        with zipfile.ZipFile(buffer, 'w') as archive:
            for name, data in self.original.items():
                archive.writestr('bundle/example/' + name, data)
            archive.writestr('bundle/other.txt', 'outside the selected skill')
        payload = buffer.getvalue()
        self.record['provider'] = 'github-release-zip'
        self.record['source'] = {'url': 'https://github.com/example/releases',
                                 'revision': 'v1.0.0', 'assetId': 17,
                                 'subtree': 'bundle/example',
                                 'archiveSha256': hashlib.sha256(payload).hexdigest()}
        self.save_record()
        metadata = {'tag_name': 'v1.0.0', 'assets': [{
            'id': 17, 'browser_download_url':
                'https://github.com/example/releases/releases/download/v1.0.0/bundle.zip'}]}

        def network(request, **kwargs):
            if request.full_url.startswith('https://api.github.com/repos/'):
                return io.BytesIO(json.dumps(metadata).encode())
            return io.BytesIO(payload)

        return metadata, network

    def test_release_asset_and_complete_zip_are_verified(self):
        metadata, network = self.archive_fixture()
        with patch.object(urllib.request, 'urlopen', side_effect=network):
            status, output = self.verify()
            self.assertEqual(status, 0, output)
            self.record['source']['archiveSha256'] = '0' * 64
            self.save_record()
            status, output = self.verify()
            self.assertEqual(status, 1, output)
            self.assertIn('archive digest', output)

    def test_wrong_release_asset_is_rejected(self):
        metadata, network = self.archive_fixture()
        metadata['assets'][0]['id'] = 18
        with patch.object(urllib.request, 'urlopen', side_effect=network):
            status, output = self.verify()
            self.assertEqual(status, 1, output)
            self.assertIn('asset', output)

    def test_archive_source_also_rejects_rehashed_edits(self):
        metadata, network = self.archive_fixture()
        data = b'Local replacement with fresh hash.\n'
        (self.raw / 'SKILL.md').write_bytes(data)
        self.record['files']['SKILL.md'] = hashlib.sha256(data).hexdigest()
        self.save_record()
        with patch.object(urllib.request, 'urlopen', side_effect=network):
            status, output = self.verify()
            self.assertEqual(status, 1, output)
            self.assertIn('independently acquired source', output)

    def test_unavailable_source_is_a_failure_not_a_skipped_pass(self):
        metadata, network = self.archive_fixture()
        with patch.object(urllib.request, 'urlopen', side_effect=OSError('offline fixture')):
            status, output = self.verify()
        self.assertEqual(status, 1, output)
        self.assertIn('offline fixture', output)
        self.assertNotIn('Verified 1', output)


if __name__ == '__main__':
    unittest.main()
