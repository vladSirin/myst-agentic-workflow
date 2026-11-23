# Myst review input mapping

## Project and spec

Use the project's tracker. Honor a verified spec supplied by the caller;
otherwise follow upstream lookup. Report a Spec skip only after user confirmation.

## Pin one review input

Load only the target's [Git](GIT-INPUTS.md) or [Perforce](PERFORCE-INPUTS.md)
inputs. Give both axes the same scope, revisions, file actions and diff. Verify
caller evidence before dispatch. Stop on stale, incomplete, empty or unverifiable
input. For an explicitly requested snapshot, identify its source, age, limits
and available hashes.

Keep pin checks, inventory and context in the coordinator's ledger. Add in-scope
ticket changes missing from the Git range. If a reviewer needs an observation
outside the change, quote it with its source and test conditions. Mark unknown
conditions and leave interpretation to the reviewer.
