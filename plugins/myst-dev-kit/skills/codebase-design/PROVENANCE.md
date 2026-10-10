# Codebase design provenance

The upstream method is from [Matt Pocock's skills](https://github.com/mattpocock/skills).
[UPSTREAM.json](UPSTREAM.json) records the exact revision, complete subtree,
original file hashes, packaged filename mapping, and required local dependencies.

The references/upstream directory preserves all four source files byte-for-byte.
The original SKILL.md is packaged as UPSTREAM.md; both companions and
agents/openai.yaml retain their names and relative layout. Myst owns the
public SKILL.md, public agents/openai.yaml,
source record, and this provenance note. The public entry retains the existing
name, trigger, and automatic invocation; the public host metadata omits display_name to use
Codex default labels; its other upstream fields are unchanged.

The local entry loads agentic-workflow's shared contract to map upstream domain
vocabulary references to the project's selected files. It also explains how to
read the plain source and map companion back-links from SKILL.md to UPSTREAM.md.
Literal back-links remain unresolved in a normal Markdown viewer. Copy installs need
the declared sibling dependency. The architecture method, parallel design
briefs, and comparison steps remain in the upstream source.

Source equality does not prove runtime behavior. The repository's plain-source
pilot report records Codex/OpenCode loading and bounded workflow evidence;
Claude runtime remains deferred. No upstream method or source pin changed in
the plain-file conversion.

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
