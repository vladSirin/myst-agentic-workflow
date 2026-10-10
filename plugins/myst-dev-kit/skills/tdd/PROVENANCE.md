# TDD provenance

The upstream method is from [Matt Pocock's skills](https://github.com/mattpocock/skills).
[UPSTREAM.json](UPSTREAM.json) owns the source revision, complete subtree,
original hashes, and required local skill dependencies.

references/upstream preserves all four original files byte-for-byte. SKILL.md is
packaged as UPSTREAM.md; tests.md, mocking.md, and agents/openai.yaml retain
their original names. Myst owns the public entry, public host metadata, source record,
and this provenance note. The public name, trigger, and automatic invocation
are retained. Public host metadata omits display_name to use
Codex default labels; its other upstream fields are unchanged.

The local entry loads agentic-workflow's shared contract for project glossary
and workflow mapping. It resolves the codebase-design reference to Myst's
wrapper. It retains Myst's review-and-submit coordinator for the review-stage
reference; that coordinator uses Myst's code-review engine. The prior inline
review-reference change is no longer inside the source.

The seam-confirmation rule, red-green loop, test guidance, and refactoring-stage
rule stay in the upstream files. This migration adds no question relay, worker
orchestration, or change to user confirmation. The companions live beside
UPSTREAM.md in the plain source directory under ADR-0009. Copy installs need
the declared siblings.
Loading and bounded behavior evidence are in the repository's TDD migration
and plain-source conversion reports; source equality alone does not prove runtime equivalence.

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
