# SkillRoster.ps1 -- ONE source of truth for which plugin skills are local-origin.
#
# Two scripts need this list and must never disagree about it:
#   - vendored-hashes.ps1   excludes local-origin skills from the vendored sweep
#   - run-provenance-tests  asserts local-origin skills survived a re-vendor (ADR-0004)
#
# When the lists were duplicated, a skill added to one and not the other did not error --
# it silently fell through vendored-hashes.ps1's local-addition branch, i.e. exactly the
# laundering path that branch was hardened against. Hence one function, dot-sourced by both.
#
# Local-origin = package-invented, never vendored from mattpocock/skills, and re-vendor-safe
# by construction (ADR-0004). A skill belongs here if it has NO upstream counterpart.

function Get-LocalOriginSkills {
    @(
        'agentic-workflow'
        'auto-plan-mode'
        'changelist-verification'
        'design'
        'pre-implementation-gate'
        'review-and-submit'
        'review-changes'
        'roundtable'
        'setup-agentic-workflow'
    )
}
