---
name: handoff
description: Use when the user asks to compact the current conversation into a handoff document for another agent.
argument-hint: "What will the next session be used for?"
disable-model-invocation: true
---

Read `SKILL.md` inside the bundled [upstream source](upstream.zip), then follow
its instructions for the user's request. The ZIP preserves the original files
and prevents hosts from registering a second skill.

Use a local ZIP reader. For example, replace `<skill-directory>` with this
entry's directory and run:

```text
python -c "import sys,zipfile; sys.stdout.buffer.write(zipfile.ZipFile(sys.argv[1]).read('SKILL.md'))" "<skill-directory>/upstream.zip"
```

On Windows without Python, read the member with PowerShell:

```powershell
Add-Type -AssemblyName System.IO.Compression.FileSystem
$sourceZip = [IO.Compression.ZipFile]::OpenRead('<skill-directory>/upstream.zip')
try {
    $sourceReader = [IO.StreamReader]::new($sourceZip.GetEntry('SKILL.md').Open())
    try { $sourceReader.ReadToEnd() } finally { $sourceReader.Dispose() }
} finally { $sourceZip.Dispose() }
```
