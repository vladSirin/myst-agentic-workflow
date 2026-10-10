# To-tickets provenance

The method is from [Matt Pocock's skills](https://github.com/mattpocock/skills).
[UPSTREAM.json](UPSTREAM.json) owns the revision, complete source inventory,
original hashes, and required local dependency.

references/upstream preserves both original files byte-for-byte. SKILL.md is
packaged as UPSTREAM.md; agents/openai.yaml keeps its original relative path.
The public SKILL.md, public agents/openai.yaml, source record, and this note
belong to Myst. Public frontmatter retains its name, description, and user-only
invocation. Public host metadata retains upstream fields except for
Myst's display-name prefix and disables implicit use.

Two former inline setup-reference changes now use agentic-workflow's shared
contract. Myst owns project tracker/triage/glossary lookup, missing configuration,
local state and publication authority. The upstream vertical slicing, approval
step, templates, native blockers, and parent sub-issue instructions stay intact.
No speculative ticket method or question relay is added.

ADR-0009 authorizes only the entry filename mapping. Copy installations need
the declared sibling dependency. Source equality does not prove runtime
alignment; the migration report records tests and their limits.

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
