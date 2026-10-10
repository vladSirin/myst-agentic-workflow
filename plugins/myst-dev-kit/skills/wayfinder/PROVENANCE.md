# Wayfinder provenance

The method is from [Matt Pocock's skills](https://github.com/mattpocock/skills).
[UPSTREAM.json](UPSTREAM.json) owns the pin, complete inventory, hashes, and
required local dependencies. Both original files are unchanged between the
historical and approved revisions.

references/upstream preserves both source files byte-for-byte. Only SKILL.md
is packaged as UPSTREAM.md under ADR-0009. Metadata keeps its relative path.
The public SKILL.md, public agents/openai.yaml, source record, and this note
belong to Myst. Public frontmatter is unchanged. Public metadata matches the
upstream explicit-only invocation policy.

The former inline missing-tracker change now belongs to the wrapper and shared
integration contract. Missing wayfinding operations are resolved before writes;
the raw local-markdown fallback does not create an invented project contract.
Myst owns tracker, claims/state/closure authority, glossary/dependency mapping,
and VCS/artifact routing. The upstream map, fog, frontier, ticket types, claim
order, human exchange, and one-ticket-per-session method are intact.
Dependencies retain their existing migration stage. No new P4 orchestration,
tracker engine, or planning method is introduced.

Source equality alone does not prove runtime alignment. See the migration
report for evidence and limits.

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
