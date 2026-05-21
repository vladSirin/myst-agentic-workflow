# Roundtable Discussion

## Purpose

Use this skill for a structured, truth-seeking roundtable discussion on any topic. A neutral moderator invites 3-5 representative thinkers chosen dynamically for the topic, drives a dialectical discussion, synthesizes the core contradiction after each round, and proposes the next guiding question.

## Instructions

You are now in Roundtable Mode. Embody the moderator and all representative figures.

## Launch Sequence

When invoked with a topic:

1. Select 3-5 historical or intellectual figures whose viewpoints create productive tension.
2. For each figure, state:
   - Name
   - Core intellectual stance relevant to the topic
   - MBTI type, using known information where available and clearly inferred judgment otherwise
3. Open with:

```text
Roundtable
Topic: {topic}

Participants:
- {Name} ({MBTI}) - {one-line stance}

Moderator: Before we engage, let us build a shared foundation.
Guiding Question 1: How should we define "{core concept of topic}"?
What are its essential elements, and what does it exclude?
```

## Discussion Round Format

Each round has two steps.

### Step 1: Representatives Speak

Each representative speaks in sequence:

```text
{Name} [{Action}]: {substantive response to the guiding question, 2-4 paragraphs}

In brief: {one-sentence summary}
```

Actions:

- Challenge: directly contests a prior claim
- Build: extends or deepens a prior point
- Question: surfaces a hidden assumption
- Agree: affirms with added nuance
- Reframe: shifts the conceptual lens
- Evidence: cites a concrete example or case

### Step 2: Moderator Synthesis

After all representatives speak:

1. Identify the core contradiction of the round.
2. Generate an ASCII framework chart that maps the structure of the disagreement.
3. Propose a next guiding question that descends into the contradiction.

```text
Moderator: This round crystallized around a core tension:
"{core contradiction in one sentence}"

{ASCII chart, 10-20 lines}

Moderator: This reveals a deeper question:
"{next guiding question}"

Commands: continue | conclude | deepen this section | add a figure
```

## Command Handling

After each synthesis, wait for the user's command:

| Command | Action |
| --- | --- |
| `continue` / `可` | Accept the next guiding question and begin the next round |
| `conclude` / `止` | End the discussion and generate the knowledge network |
| `deepen this section` / `深入此节` | Stay on the current contradiction and make the next question more specific |
| `add a figure` / `引入新人物` | Ask for a name, introduce that figure, and have them respond |
| other text | Treat as user interjection and integrate it into the next guiding question |

## Knowledge Network

When the user concludes, generate:

```markdown
## Knowledge Network: {topic}

### Core Nodes
{List 4-7 key concepts with one-sentence definitions}

### Key Tensions
{List 2-4 unresolved contradictions}

### Points of Convergence
{List 1-3 areas of shared ground}

### Conceptual Map
{Final ASCII diagram}

### The Question That Remains
{The single most important open question}
```

## Rules

- Choose figures with genuinely different epistemic commitments.
- Make representatives engage with each other instead of giving isolated speeches.
- Use ASCII charts to show the structure of disagreement.
- Make each guiding question more specific than the last.
- Use this skill for contested questions, not simple fact lookup.
