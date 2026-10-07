---
name: codebase-design
description: Shared vocabulary for designing deep modules. Use when the user wants to design or improve a module's interface, find deepening opportunities, decide where a seam goes, make code more testable or AI-navigable, or when another skill needs the deep-module vocabulary.
---

Read [Myst's local integration contract](../agentic-workflow/LOCAL-INTEGRATION.md)
before the upstream vocabulary. Copy installs require agentic-workflow with
that reference. Map upstream glossary references to the project's authoritative
domain files, including legacy CONTEXT.md paths, through the shared contract.

Read SKILL.md inside the complete [upstream source](upstream.zip), then follow
it with that local mapping. Load its DEEPENING.md and DESIGN-IT-TWICE.md
companions when the source calls for them. Resolve relative source links inside
the archive from the referring member's directory; keep their original names.

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
