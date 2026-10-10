# Domain-modeling provenance

The method is from [Matt Pocock's skills](https://github.com/mattpocock/skills).
[UPSTREAM.json](UPSTREAM.json) records the approved pin, complete inventory,
original hashes, and required agentic-workflow dependency.

All four approved files remain byte-for-byte intact in references/upstream.
SKILL.md alone is packaged as UPSTREAM.md under ADR-0009. GLOSSARY-FORMAT.md,
ADR-FORMAT.md and agents/openai.yaml retain their original relative names.
The old root CONTEXT-FORMAT.md is retired with the upstream companion rename;
ADR-FORMAT.md moves beside the raw source. Consumer glossaries are not renamed.

All three former local files matched the historical source. The upstream method
update is the CONTEXT-to-GLOSSARY naming change, including the renamed format
guide and its map heading. ADR format and source host metadata are unchanged.

The public entry, public host metadata, source record, and this note belong to
Myst. The local trigger names legacy and new glossaries and remains model-invoked.
Public host metadata retains upstream fields except for
Myst's display-name prefix. Myst's shared contract selects authoritative
root/scoped/custom domain paths and handles conflicts or missing ownership. The
wrapper applies that mapping to the source and companion defaults. Direct links
expose both companions. No domain modeling, questioning, or ADR method is rewritten.

Source equality is not runtime equivalence. The migration report records the
path and behavior checks and their limits.

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
