---
name: tdd
description: Test-driven development. Use when the user wants to build features or fix bugs test-first, mentions "red-green-refactor", or wants integration tests.
---

Read [Myst's local integration contract](../agentic-workflow/LOCAL-INTEGRATION.md)
before the upstream workflow. Apply its project glossary mapping for reads and
writes, including legacy CONTEXT.md paths, and the project's workflow rules.

Required Myst dependencies for copy installs: agentic-workflow, codebase-design,
review-and-submit, and code-review. Use the Myst namespace or the explicit
sibling entries below when the source reaches those references:

- `codebase-design` means Myst [codebase-design](../codebase-design/SKILL.md).
  Consult its vocabulary when the interface shape is in question.
- The review-stage `code-review` reference maps to Myst
  [review-and-submit](../review-and-submit/SKILL.md), whose review engine is
  [myst-dev-kit:code-review](../code-review/SKILL.md).

Read SKILL.md inside the complete [upstream source](upstream.zip), then follow
it with those local mappings. Read tests.md and mocking.md when the source
calls for them. Resolve source-relative links inside the archive from the
referring member's directory; keep the original member names.

Use a local ZIP reader, substituting this entry's directory and the requested
member (SKILL.md first):

```text
python -c "import sys,zipfile; sys.stdout.buffer.write(zipfile.ZipFile(sys.argv[1]).read(sys.argv[2]))" "<skill-directory>/upstream.zip" "SKILL.md"
```

On Windows without Python, set sourceMember to the requested member:

```powershell
Add-Type -AssemblyName System.IO.Compression.FileSystem
$sourceMember = 'SKILL.md'
$sourceZip = [IO.Compression.ZipFile]::OpenRead('<skill-directory>/upstream.zip')
try {
    $sourceReader = [IO.StreamReader]::new($sourceZip.GetEntry($sourceMember).Open())
    try { $sourceReader.ReadToEnd() } finally { $sourceReader.Dispose() }
} finally { $sourceZip.Dispose() }
```
