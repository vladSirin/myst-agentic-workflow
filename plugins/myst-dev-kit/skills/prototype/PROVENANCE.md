# Prototype provenance

The complete skill is from [Matt Pocock's skills](https://github.com/mattpocock/skills)
at the approved pin in [UPSTREAM.json](UPSTREAM.json). All four selected files are
byte-for-byte intact under references/upstream. Only SKILL.md maps to UPSTREAM.md
under ADR-0009. The former Myst entry and both companions match this pinned
source, so there is no method delta. Previously omitted Codex metadata is included.

Myst owns the public entry, public metadata, source record, and this note. The
entry resolves project pointers, corrects the packaged entry reference for the
companions, and maps capture/publication to the target VCS. It preserves the logic
and UI branches, throwaway scope, and primary-source capture method. Perforce
uses the existing project workflow rather than Git branches or a nested Git mirror.
Validation and publication retain their existing authority; no orchestration or
prototype test suite was added to the source. Copy installs require agentic-workflow.

## Upstream MIT notice

Copied from the upstream root LICENSE at the recorded revision.

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
