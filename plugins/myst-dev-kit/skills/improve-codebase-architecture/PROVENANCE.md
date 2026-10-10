# Improve-codebase-architecture provenance

The method is from [Matt Pocock's skills](https://github.com/mattpocock/skills).
[UPSTREAM.json](UPSTREAM.json) records the approved pin, complete inventory,
original hashes, and required Myst dependencies.

All three approved files remain byte-for-byte intact in references/upstream.
SKILL.md alone is packaged as UPSTREAM.md under ADR-0009. HTML-REPORT.md and
agents/openai.yaml retain their original relative names. The old root report
guide moves beside the raw source after a byte comparison.

Both previous local files match the historical source. The upstream update
only replaces CONTEXT.md references with GLOSSARY.md. The report guide and
source host metadata are unchanged across pins.

The public entry, public host metadata, source record, and this note belong to
Myst. The trigger and user-only invocation remain unchanged; public metadata retains upstream fields except for
Myst's display-name prefix. The wrapper selects project domain and ADR paths, target VCS
history, and Myst dependency entries. It links the report guide directly. The
exploration, visual report, and grilling methods are not rewritten.

Hosts must preserve user-only invocation. OpenCode requires an explicit local
skill permission rule as recorded in the migration report; copying this folder
does not install host configuration. Source equality is not runtime equivalence.

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
