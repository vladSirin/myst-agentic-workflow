# TDD

<command-name>tdd</command-name>

## Purpose

Use red-green-refactor with one vertical slice at a time.

## Project setup

- Domain docs: `Docs/agents/domain.md`
- Status labels: `Docs/agents/triage-labels.md`

## Instructions

When invoked, follow this repo's project-local TDD workflow:

1. Prefer behavior tests through public interfaces over implementation-detail tests.
2. Work one test and one implementation slice at a time.
3. Treat Unreal Editor-only checks, gameplay feel, LD usability, and asset validation as HITL unless an automated check exists.
4. Mark an issue `closed` only when every required verification is agent-runnable and passed.
5. Mark an issue `resolved` when code/tests pass but human verification remains.
