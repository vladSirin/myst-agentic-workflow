# Local integration contract

Read this reference before a Myst wrapper dispatches another skill, changes
tracker state, resolves domain docs, or follows upstream VCS instructions.
These rules belong to Myst. Apply them while running the source; do not edit
the archived source to encode them.

## Resolve the target and project pointers

Use the repository and work area the user is changing, not the devkit checkout
or a reference repository. Read its applicable AGENTS.md / CLAUDE.md and the
project docs they identify. Honor a path base stated by the project. Resolve
relative Markdown links from their declaring doc. If a plain-text path's base
is unclear, confirm it before dependent writes rather than guessing.
Use explicit project pointers for the team docs root, workflow guide, tracker,
triage model, domain docs, and ADRs. Read only those needed for the current step.

If a pointer is absent, locate existing project docs and confirm their scope.
`docs/agents/` and `Docs/agents/` are search hints, not required paths. A feature
spec can define a scoped Markdown tracker. Do not replace live project docs
with the devkit's starter templates. If config is missing or conflicting,
report the exact gap and establish the relevant contract with the user before
dependent writes. Continue independent read-only work. Never invoke the
excluded setup-matt-pocock-skills as a fallback.

Determine the VCS for that target from project instructions and repository or
workspace evidence. A Perforce target stays Perforce when it contains a Git
mirror or Git is installed. If ownership is unclear, resolve it before VCS
actions or VCS-specific skill dispatch.

## Load the intended dependency

Each wrapper using this contract lists its required Myst skills and links to
this reference before its upstream workflow. For copy installs, include
agentic-workflow with this reference and the wrapper's declared dependencies.
Check that required files
and wrappers are available before the dependent step; a partial copy is not a
reason to load another vendor's skill or bypass the wrapper.

Use the host's explicit skill mechanism with the Myst namespace when supported.
For review, select `myst-dev-kit:code-review`. In copy hosts without namespaces,
resolve the installed Myst entry by its full path and read that SKILL.md.
Do not dispatch an ambiguous bare name. If the correct entry cannot be resolved,
report the missing dependency before proceeding with that step.

Preserve the entry's invocation contract. A user-only skill cannot be invoked
automatically or through another skill; suggest its explicit command to the
user. A host that ignores that metadata still needs the local restriction.
Never evade it by reading the raw source directly. Automatic dependencies must
permit model invocation. Explicit user invocation still obeys target VCS rules.

`pr` and `implement-spec` are Git-only. Check the target before loading their
upstream workflow on direct, automatic, and cross-skill routes. For a Perforce
target, explain the restriction and use the existing Perforce workflow; do not
invoke either skill. Their adoption is staged: a name in this contract does not
mean that the skill is already installed.

## Resolve domain vocabulary for reads and writes

Read the project's domain-doc pointer first. An explicit authoritative pointer
wins, including a custom filename. A broken or conflicting pointer requires
clarification before dependent writes; do not silently fall back to another file.

Without a pointer, apply this table at the root and at each relevant scope:

| Available files | Read/write target |
| --- | --- |
| Only CONTEXT.md / CONTEXT-MAP.md | Keep the existing legacy files |
| Only GLOSSARY.md / GLOSSARY-MAP.md | Use the existing new files |
| Both naming families | Read to identify the conflict; obtain an authoritative mapping before writing vocabulary |
| Neither | Preserve the project's established convention during staged migration; if none is established, ask before creating vocabulary files |

Follow the selected context map's links to scoped glossaries. Those links are
explicit pointers for their scopes, even if the files use mixed names. Resolve
them relative to the map; do not infer scoped names from the root filename.
Apply the same rules to each unreferenced scope needed for the task. Map files
and root glossaries can coexist; they serve different purposes, but conflicting
ownership still needs clarification.

Only default a new project to GLOSSARY.md / GLOSSARY-MAP.md once the complete
reader/writer migration is verified and recorded for that project. The staged
devkit refresh alone does not establish readiness. Map upstream glossary
references to the selected local paths for both reads and writes. Do not rename
consumer files, create a second glossary, or change the source instructions.
Keep vocabulary in glossaries and durable design decisions in the project's ADRs.

## Keep workflow and publication authority

Use the project's tracker and triage model for specs, tickets, and state changes.
Check its completion evidence before closing work. Upstream instructions to
commit, create a PR, or close an issue do not grant authority or change that model.
In Perforce, do not create Git commits. In Git, local commits stay within the
user's authorized scope. Reviewers report; they never publish.

Before shared publication (including submit, push, PR, merge, or release), load
the Myst [review-and-submit](../review-and-submit/SKILL.md) entry and follow its
review, preflight, and approval protocol. This reference does not authorize any
publication or replace its current description format. Formatter adoption and
Review Record retirement are separate migration steps.
