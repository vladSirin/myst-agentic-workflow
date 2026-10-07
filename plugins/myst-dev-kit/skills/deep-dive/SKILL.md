---
name: deep-dive
description: "A two-step decision interview built on bidirectional steel-manning (双向钢人论证): restate the real question, strengthen BOTH sides to their strongest form, surface the true crux and key variables, ask ONE decisive question and stop — then, only after the user answers, give a clear verdict with boundary conditions and concrete next actions."
disable-model-invocation: true
argument-hint: "<the decision or question you keep going back and forth on>"
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
