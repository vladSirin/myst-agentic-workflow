# Handoff provenance

The upstream method is from [Matt Pocock's skills](https://github.com/mattpocock/skills),
under the MIT terms reproduced below for standalone copy installs.
The exact source identity, original subtree, and raw-file hashes are recorded in
[UPSTREAM.json](UPSTREAM.json).

The complete selected subtree is preserved inside upstream.zip, including its
original SKILL.md frontmatter and agents/openai.yaml. Myst owns this directory's
root SKILL.md, root agents/openai.yaml, this note, and the source record.

The local entry delegates the method without rewriting it. Public metadata keeps
the existing handoff name and explicit user invocation. No new handoff behavior
or required skill dependency is added. Packaging and runtime evidence belongs
to the repository's handoff pilot; byte equality alone does not prove loading.

Loose source folders caused duplicate registration in Codex 0.160.1 and wrapper
bypass in OpenCode 1.18.35, including with a hidden .upstream/ folder. The ZIP
keeps original member filenames and bytes intact while leaving one discoverable
SKILL.md. The local entry reads its instructions with a local ZIP reader;
Python and Windows PowerShell examples are supplied. No runtime download or
extraction into a skill-discovery directory is needed.

## Upstream MIT notice

Copied from upstream root LICENSE at the revision in UPSTREAM.json.

```text
MIT License

Copyright (c) 2026 Matt Pocock

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
