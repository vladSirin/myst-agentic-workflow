# Wait-what provenance

The method is from [Matt Pocock's skills](https://github.com/mattpocock/skills).
[UPSTREAM.json](UPSTREAM.json) records the approved pin, complete inventory,
original hashes, and required agentic-workflow dependency.

Both approved files remain byte-for-byte intact in references/upstream.
SKILL.md alone is packaged as UPSTREAM.md under ADR-0009. The source metadata
keeps its original agents/openai.yaml path. No method companion is omitted.

The previous local entry matches historical source. The upstream update only
changes CONTEXT.md and CONTEXT-MAP.md to GLOSSARY.md and GLOSSARY-MAP.md.
The source metadata is unchanged across pins.

The public entry, public metadata, source record, and this note belong to Myst.
The trigger and user-only invocation remain unchanged; public metadata omits display_name to use
Codex default labels; its other upstream fields are unchanged. The wrapper maps project domain documents and scoped links through
Myst's shared contract. The re-explanation method is not rewritten.

OpenCode needs its explicit local permission rule to retain user-only invocation;
copying this folder does not install host configuration. The migration report
records checks and limits. Source equality alone is not runtime equivalence.

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
