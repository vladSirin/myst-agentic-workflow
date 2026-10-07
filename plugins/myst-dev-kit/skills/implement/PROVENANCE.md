# Implement provenance

The upstream method is from [Matt Pocock's skills](https://github.com/mattpocock/skills).
[UPSTREAM.json](UPSTREAM.json) records the exact revision, complete subtree,
original file hashes, and required local skill dependencies.

upstream.zip preserves SKILL.md and agents/openai.yaml byte-for-byte. Myst owns
this directory's public SKILL.md, public agents/openai.yaml, source record, and
this provenance note. The public metadata retains the implement name and explicit
user invocation; its current values match the archived upstream metadata.

The local entry loads agentic-workflow's shared contract. It maps upstream TDD
and review calls to Myst's entries, retains review-and-submit as coordinator,
and applies the target project's tracker, Git/Perforce, and publication rules.
The source still says to commit; the local entry limits that instruction to
Git target work within user authorization. No TDD or orchestration rewrite is
part of this migration. Copy installs need all declared sibling dependencies.

The ZIP follows the discovery-safe handoff layout. Its original files are not
loose discoverable skills. Source equality does not prove runtime behavior;
loading and bounded implementation evidence are recorded separately in the
repository's implement migration report.

## Upstream MIT notice

Copied from the upstream root LICENSE at the revision in UPSTREAM.json.

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
