# Triage provenance

The method is from [Matt Pocock's skills](https://github.com/mattpocock/skills).
[UPSTREAM.json](UPSTREAM.json) owns the pinned revision, complete source inventory,
original hashes, and required local dependencies.

references/upstream preserves all four original files byte-for-byte. Only
SKILL.md is packaged as UPSTREAM.md. Companion and metadata paths are unchanged
within that source directory. The former root companion copies are removed;
the raw entry's relative links resolve to the preserved source companions.

The public SKILL.md, public agents/openai.yaml, source record, and this note
belong to Myst. Public frontmatter is unchanged; public host metadata matches
upstream and disables implicit invocation. The former inline setup-reference
change moves into the shared integration contract. Myst maps tracker labels,
glossary reads/writes, dependency routing, and authority. It retains the upstream
state machine, recommendation pause, verification, grilling, briefs, disclaimer,
and out-of-scope method. No speculative method or question relay is introduced.

The approved upstream update names GLOSSARY.md instead of CONTEXT.md in the
grilling step. Local domain pointers remain authoritative, including legacy
names and custom paths. Dependencies are still at their current migration stage;
this changeset does not migrate grilling or domain-modeling.

ADR-0009 authorizes the entry filename mapping. Source equality alone does not
prove runtime alignment; the migration report records evidence and limits.

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
