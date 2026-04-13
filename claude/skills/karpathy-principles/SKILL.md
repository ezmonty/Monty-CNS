---
name: karpathy-principles
description: Apply Karpathy's 4 coding principles to in-flight work — think before coding, keep it simple, make surgical changes, define verifiable goals. Use before committing, when a feature feels bloated, or when the model might be over-coding. Prompt-only — reads the diff directly via git.
---

<!--
Source of principles: Andrej Karpathy — https://x.com/karpathy/status/2015883857489522876
Skill content is original (Monty-CNS), prompt-only, with no external scripts.
For a richer bundle with Python detectors + pre-commit hook, see
alirezarezvani/claude-skills → engineering/karpathy-coder.
-->

# Karpathy Principles — Active Coding Discipline

A short, enforceable checklist derived from Andrej Karpathy's observations on how LLMs (and humans) over-code. Use it as a self-review before committing, or as a framing lens during a feature.

> "The models make wrong assumptions on your behalf and just run along with them without checking. They don't manage their confusion, don't seek clarifications, don't surface inconsistencies, don't present tradeoffs, don't push back when they should."
>
> "They really like to overcomplicate code and APIs, bloat abstractions, don't clean up dead code... implement a bloated construction over 1000 lines when 100 would do."
>
> "LLMs are exceptionally good at looping until they meet specific goals... Don't tell it what to do, give it success criteria and watch it go."
>
> — Andrej Karpathy

## The Four Principles

### 1. Think Before Coding — surface assumptions, don't run on them

**Bad:** Start editing, infer behavior from filenames, pattern-match to "looks similar".
**Good:** Before writing code, explicitly state:

- What is the actual goal? (Not the task name — the outcome.)
- What are you assuming about inputs, contracts, invariants, data shapes?
- Which of those assumptions did you *verify* vs *guess*?
- What tradeoffs does this change involve?

**Self-check questions:**

- Can I write one sentence stating the goal in my own words?
- Have I listed 2+ assumptions I'm making?
- For each assumption: did I read the code, run a probe, or just pattern-match?
- Is there an unresolved ambiguity I should ask about instead of guessing?

### 2. Keep It Simple — the boring solution is usually the right one

**Bad:** New abstraction, configuration surface, factory, interface hierarchy, options bag, or design pattern introduced "for flexibility."
**Good:** The simplest code that solves the actual problem. Abstractions emerge from three uses, not one.

**Warning signs in the diff:**

- New config knob with only one caller setting it
- `BaseFooManagerFactoryStrategy` pattern for a function called once
- New utility module for a 3-line helper
- Deep nesting (`if ... if ... if`) — usually means hidden state or missing abstraction, not the need for another layer
- Premature generalization: "this might be useful later"
- Rewrote working code "while we're in here"

**Self-check questions:**

- If I deleted this change entirely, what would actually break?
- Could three fewer lines do the same thing?
- Is there a function name doing the explaining because the code can't?
- Did I add a feature flag for a feature the user didn't ask for?

### 3. Make Surgical Changes — the diff should read like a scalpel, not a sander

**Bad:** "While I was in here, I also reformatted...", "renamed this variable to match my preference...", "cleaned up some unused imports in an unrelated file."
**Good:** Every hunk in the diff is necessary for the stated goal. Unrelated cleanup lives in a separate commit (or just in your editor, not committed).

**Warning signs:**

- Lots of whitespace / formatting noise in files you didn't intentionally touch
- Comment-only changes in unrelated files
- Style drift (semicolons added/removed, quote style flipped)
- Rename touching files far from the change
- Variable renamed "because it's clearer now" without necessity

**Self-check questions:**

- Does every changed file directly serve the stated goal?
- If a reviewer asked "why is this line in the diff?", can I answer for every line?
- Could I split this into a "feature" commit and a "cleanup" commit?

### 4. Define Verifiable Goals — success criteria, not instructions

**Bad:** "Make this function work." "Fix the bug."
**Good:** "When input X arrives, function returns Y. When input X' arrives, it returns error Z. Add a test that fails now and passes after the fix."

**Self-check questions:**

- Do I have a test or reproducible command that proves this works?
- Would an independent person know *exactly* what "done" looks like?
- Did I verify the fix actually fixes the stated problem, or just stopped seeing the error?
- Does the code behave correctly on the adjacent inputs I didn't explicitly think about?

## Workflow

Run this skill against a diff — staged changes by default.

### Step 1: Gather the diff

```bash
git diff --cached        # staged changes (default)
git diff HEAD~1          # last commit
git diff main...HEAD     # full branch
```

Use whichever matches the current context. If nothing is staged, fall back to unstaged then last commit.

### Step 2: Apply each principle

For each of the four principles, score the diff on a **1–5 scale** and list concrete evidence:

- **1** — Violates the principle outright.
- **3** — Mixed; some hunks obey, some don't.
- **5** — Fully aligned; a human reviewer would compliment it.

### Step 3: Report

```
## Karpathy Principles Review

Scope: <files touched, lines changed>

1. Think — <score>/5
   <what assumptions are present / missing, where>

2. Simple — <score>/5
   <what's over-engineered, where>

3. Surgical — <score>/5
   <what's noise vs. signal in the diff>

4. Goals — <score>/5
   <is there a test / verification step?>

Overall: <lowest score>

Must-fix before commit:
- <specific hunk, specific action>
- ...

Nice-to-have:
- <specific hunk, specific action>
```

## Rules

- **Score honestly.** A "3" is not a failure — it's information. Pretending a 2 is a 4 is the failure.
- **Cite the hunk.** Every finding must point at a file and line so the author can jump to it.
- **No drive-by nitpicks.** Findings must tie back to one of the four principles, not personal style.
- **Call out what's good too.** If the diff is a strong 5 on "surgical", say so — reinforcement is part of the loop.

## When to Use

- **Before `git commit -m`** — catches over-engineering and noise early.
- **After finishing a feature** — sanity check before opening a PR.
- **When the diff feels "too big"** — almost always means principle 2 or 3 was violated.
- **Pair with `adversarial-reviewer`** for a full critical pass on high-stakes changes.
