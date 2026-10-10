# Implement Spec provenance

The complete skill comes from [Matt Pocock's skills](https://github.com/mattpocock/skills).
[UPSTREAM.json](UPSTREAM.json) records the approved pin, original paths, hashes,
and Myst copy dependencies. This is a new import; no earlier Myst method exists.
Both selected files remain intact under references/upstream. Only SKILL.md maps
to UPSTREAM.md under ADR-0009. Public host metadata retains upstream fields except for
Myst's display-name prefix.

Myst owns the public entry, local description, source record, and this note.
The entry adds target-VCS eligibility, project/tracker/vocabulary selection,
explicit Myst dependency identity, existing changeset/human-ticket rules, and
review/publication routing. It preserves upstream task graph, worker/worktree,
merger, integration and cleanup behavior. User-only invocation remains intact.
No Perforce counterpart, task-to-changeset mapping procedure, TDD question relay,
or speculative scheduler is added. P4 targets never execute this upstream method.

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
