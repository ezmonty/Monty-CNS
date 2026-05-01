# Lens - Agent and System Design

Questions:
- what are the invariants — what must never break, what is load-bearing
- what compounds vs what decays (which decisions get more valuable over time, which become debt)
- what is the real contract between components (not what the name implies, what the code enforces)
- where is the claim-reality gap (what does the doc say vs what does the system actually do)
- what breaks first under load, under change, under a new contributor
- what pattern is being established here that will repeat 10 more times — is it the right pattern
- what would a DriftGuardAgent flag in 6 months if this decision stands unchanged
- is this a real capability or a stub dressed up as one (H-Scale question)
