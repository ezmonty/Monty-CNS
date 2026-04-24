# User-scope Claude instructions

This file is loaded by every Claude Code session on this user account (any
project). It's tracked in [Monty-CNS](https://github.com/ezmonty/Monty-CNS) so
every machine sees the same baseline.

## Fleet & remote access

If you need to deploy, test, or run something that requires a real server —
especially **E2E, integration, or soak tests** against a running stack —
see **[`~/src/Monty-CNS/MACHINES.md`](../src/Monty-CNS/MACHINES.md)**.

It documents:
- Every host in the fleet (currently `valor-vm` — Oracle Cloud A1, 24/7)
- How to reach each one (`ssh valor-vm` is pre-wired on any CNS-installed machine)
- What services are running, on what ports, behind what proxy
- How to deploy, restart, tail logs, and run tests on each host
- How to onboard a new machine as a full CNS-Secrets recipient (~60 seconds)

**Before asking the user for credentials, a hostname, or "how do I run X
against the real stack"**, check that file. It's the intended answer.

## Secrets

Secrets live in the private `Monty-CNS-Secrets` repo (sops + age encrypted)
and are loaded into `$CLAUDE_ENV_FILE` at session start on any machine that's
been added as a recipient. Do not ask the user to paste keys into the chat —
if a var isn't in the environment, the right fix is usually to run
`~/src/Monty-CNS/rekey-new-machine.sh` to admit this machine.
