# Diagnosing-bugs provenance

The method is from [Matt Pocock's skills](https://github.com/mattpocock/skills).
[UPSTREAM.json](UPSTREAM.json) records the approved pin, complete inventory,
original hashes, and required agentic-workflow dependency.

All three approved files remain byte-for-byte intact in references/upstream.
SKILL.md alone is packaged as UPSTREAM.md under ADR-0009. The HITL script and
agents/openai.yaml retain their original relative names. The former root script
moves beside the raw source after a byte comparison.

Both previous local files matched the historical source. The upstream update
changes only the CONTEXT.md reference to GLOSSARY.md. The six diagnosis phases,
HITL template, and source host metadata are unchanged across the approved pins.

The public entry, public host metadata, source record, and this note belong to
Myst. The trigger and automatic invocation remain unchanged; public metadata retains upstream fields except for
Myst's display-name prefix. Myst's shared contract selects domain paths, ADR location,
target VCS, and publication authority. The wrapper links the source and HITL
companion directly. No diagnosis method or script behavior is rewritten.

Source equality is not runtime equivalence. The migration report records the
behavior checks and their limits.

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
