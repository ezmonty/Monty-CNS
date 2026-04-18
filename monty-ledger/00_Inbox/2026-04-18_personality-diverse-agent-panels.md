---
title: "Personality-diverse agent panels for genuine creative tension"
type: learning
origin_type: ai-proposed
confidence: 3
status: review
access: private
truth_layer: working
created: 2026-04-18
tags: ["agents", "personality", "creativity", "methodology", "Monty-CNS"]
---

**Project:** Monty-CNS / Valor
**Tags:** agents, personality, creativity, methodology
**Confidence:** suspected (theoretically grounded, not yet tested in Valor)
**Context:** Emerged from session discussion about agent panel design and the limits of the adversarial-reviewer pattern

Personality-diverse agent panels create genuine creative tension, not just simulated disagreement. When agents share the same task but operate under different personality frameworks (Big Five, DISC, Jungian archetypes — see Jordan Peterson's work on personality and creative output), the structural differences in how they weight risk, openness, agreeableness, and conscientiousness produce actually different evaluations — not rephrased agreement.

This differs from the adversarial-reviewer skill (which forces hostile personas as a review technique). This is about cognitive diversity creating real synthesis through genuine tension in the evaluation criteria themselves.

**Application:** A 4-agent panel where:
- Agent A: high-openness, low-conscientiousness (creative, exploratory, messy)
- Agent B: low-openness, high-conscientiousness (rigorous, conservative, thorough)
- Agent C: high-agreeableness (integrator, finds common ground)
- Agent D: low-agreeableness (challenger, finds fault lines)

The tension between them produces output none would produce alone.

**Key insight:** The LLM's tendency toward agreeable consensus is the enemy of this pattern. The personality must create STRUCTURAL disagreement in the evaluation criteria and weighting, not just tone differences in the prose. Personality profiles should change what the agent LOOKS FOR and how it SCORES, not just how it WRITES.

**Connection to existing systems:**
- The vault's Pod system could define personality profiles that agents load
- The access model's `role_mode` field already supports role-based behavior (self/owner/executive/veteran/student/strategist)
- Valor's `provider="agent:<name>"` mesh dispatch could route the same task to 4 differently-configured agents
- The `/adversarial-review` skill is a degenerate case of this pattern (3 hostile personas, same evaluation criteria)

**Research threads:**
- Jordan Peterson: Big Five personality and creative output
- DISC assessment: Dominance, Influence, Steadiness, Conscientiousness
- Jung/MBTI: cognitive function stacks as agent configuration
- Dialectical method: thesis + antithesis → synthesis requires genuine opposition
