# Hammer skill update evidence — 2026-10-06

## Result

Hammer's latest release is **v0.30.0**, published on 2026-10-06 at 02:36:25 UTC
(10:36:25 Asia/Shanghai). Myst's two Hammer skills record **v0.19.0**.
The latest extracted `deep-dive` and `roundtable` bodies match Myst's current
bodies after removing frontmatter and normalizing CRLF to LF. There is no body
update to adopt for either skill. Restore complete upstream files, move Myst's
frontmatter choices into wrappers, and advance the provenance pin.

The GitHub web cache returned v0.24.0 for `/releases/latest`. A live REST API
request returned v0.30.0. The fixed release and actual ZIP entries below are the
evidence used here; app release notes are not evidence of skill changes.

Sources: [fixed release](https://github.com/dreamwords/hammer-releases/releases/tag/v0.30.0),
[release API](https://api.github.com/repos/dreamwords/hammer-releases/releases/tags/v0.30.0),
[repository tree at this tag](https://api.github.com/repos/dreamwords/hammer-releases/git/trees/v0.30.0?recursive=1).

## Package and extracted content

| Asset | Size in bytes | SHA-256 reported by GitHub |
| --- | ---: | --- |
| `Hammer-0.30.0-mac.zip` | 355242551 | `1532f24e8ae95f9606a9ad4bb2916acfcb6fa0dff9f1496cca216c93c26f72be` |
| `Hammer-0.30.0-arm64-mac.zip` | 348323651 | `8601b18b49aa271fc1982a9ab8ea83db20038150f6ab6d1efdda65335945e22f` |

Inspected asset: [Intel Mac ZIP](https://github.com/dreamwords/hammer-releases/releases/download/v0.30.0/Hammer-0.30.0-mac.zip).
Its GitHub asset ID is `614238989`:
[asset API](https://api.github.com/repos/dreamwords/hammer-releases/releases/assets/614238989).
The other release assets are corresponding DMGs, blockmaps, and `latest-mac.yml`.
Only the Intel Mac ZIP was inspected for skill content.

Method: use small HTTP Range requests to read the ZIP end record and central
directory; read each skill's local header and compressed payload; decompress
with Python's standard `zlib`; check each entry's uncompressed size and CRC32.
No downloaded app code was run or installed. The complete archive was not
downloaded, so its full SHA-256 is reported release metadata, not a locally
verified archive hash. The hashes below were computed from extracted bytes.

Both paths start with `Hammer.app/Contents/Resources/advanced-capabilities/`:

| File | Uncompressed bytes | SHA-256 computed from source bytes | Body versus Myst |
| --- | ---: | --- | --- |
| `deep-dive/SKILL.md` | 3579 | `bbb960312b72e2bf1c3b6a98f2dba96bf62dbb0e7dcc9ad382fd91a9659fb9ff` | Equal after frontmatter removal and newline normalization |
| `roundtable/SKILL.md` | 5348 | `44531a16d1662a831562de8d5e58f27e2821bea5c541c3a56c94e1507681a358` | Equal after frontmatter removal and newline normalization |

Verified entry CRC32 values are `d8778061` and `3553d183`, respectively.
Complete raw files, including upstream frontmatter, were retained in this local
temporary evidence folder:

`C:\Users\Shado\AppData\Local\Temp\myst-hammer-20261006-v0300\{deep-dive,roundtable}\SKILL.md`

The complete directory inventory contains only these two skill folders and a
431-byte `README.md`. It exposes no additional advanced-capability skill to
adopt. This is a directory inventory claim; it does not claim that the app has
no other prompts elsewhere in its package. The bundled README's content was not
read during this check.

Upstream frontmatter has `name` and a Chinese `description`. It has no
`argument-hint` or `disable-model-invocation` field. Myst supplies English
descriptions and argument hints. Myst also makes `deep-dive` explicitly
user-invoked. Those are local choices and should move out of the source copy.

## Attribution and authorization

The extracted bodies still credit 卡兹克 for `deep-dive` and 李继刚 for
`roundtable`; the latter still carries its 2025-11-12 revision date. The public
repository tree at v0.30.0 has no LICENSE file. Neither advanced-capability
folder contains a license file. This does not establish a new public license.

Both current Myst `PROVENANCE.md` files record owner authorization from sxc on
2026-08-27 for vendoring and redistribution, and explicitly extend it to
re-vendoring. Preserve that record. This update does not require a repeated
owner-permission question on the same scope.

Local sources:

- [deep-dive provenance](../plugins/myst-dev-kit/skills/deep-dive/PROVENANCE.md)
- [roundtable provenance](../plugins/myst-dev-kit/skills/roundtable/PROVENANCE.md)
- [deep-dive skill](../plugins/myst-dev-kit/skills/deep-dive/SKILL.md)
- [roundtable skill](../plugins/myst-dev-kit/skills/roundtable/SKILL.md)

## Proposed update gates

1. Adopt the repository's common wrapper layout first. Keep the whole upstream
   `SKILL.md`, including frontmatter, byte-for-byte. Put local discovery text,
   invocation policy, and argument hints in a separate Myst entry point that
   explicitly loads that source file.
2. Extract these two files from the pinned v0.30.0 asset. Check their recorded
   source hashes. Record the asset URL, archive entry, hash, attribution, and
   existing authorization in the provenance manifest. Include required adjacent
   material after inspecting the bundled README.
3. Check exact byte equality of the source copy, including frontmatter and line
   endings. Fail validation if local text appears inside it.
4. Test each wrapper in a fresh host session. `deep-dive` must accept the initial
   question, ask one decisive question, and stop. `roundtable` must accept the
   topic, stop after a round, and retain its warning against invented real
   quotations. Check explicit invocation and discovery against Myst's stated
   policies. Do not infer runtime success from file equality.
5. Review each skill migration separately under the repository's contribution
   process. Keep source restoration, local-wrapper behavior, and release
   evidence clear in each review record.

No skills, manifests, installed plugins, or provenance files were changed by
this research. The v0.19.0 binary was not separately extracted; the comparison
above is between the latest verified source and current Myst content.
