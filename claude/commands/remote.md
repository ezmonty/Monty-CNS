---
description: Execute commands on fleet machines via SSH or MontyCore HTTP API.
---

# /remote — Run commands on fleet machines

Execute commands on any machine listed in MACHINES.md.

Target: $ARGUMENTS (command to run, optionally prefixed with hostname)

## Steps

### 1. Parse input

If input starts with a hostname (e.g., `valor-vm df -h`), use that host.
If no hostname, default to `valor-vm` (the primary fleet machine).
The remainder is the command to execute.

If no command given, ask: "What should I run on <host>?"

### 2. Choose connection method

**Method A — SSH (preferred, terminal sessions):**
Check if SSH is available: `command -v ssh`
Check if the host is reachable: `timeout 3 bash -c 'echo > /dev/tcp/<ip>/22' 2>/dev/null`
If both: use `ssh <hostname> '<command>'`

**Method B — MontyCore HTTP API (fallback, web sessions):**
Check if the host's MontyCore is reachable: `curl -s --connect-timeout 3 http://<ip>/health`
If reachable: POST to `http://<ip>:8090/ask` with:
```json
{
  "command": "shell",
  "data": {"cmd": "<command>"},
  "session_id": "remote-exec"
}
```

**Method C — Neither available:**
Print the command the user should run manually:
"I can't reach <host> from this session. Run this on a terminal with SSH access:"
```
ssh <hostname> '<command>'
```

### 3. Look up host details

Read `~/src/Monty-CNS/MACHINES.md` (or the repo's `MACHINES.md`) for:
- IP address
- SSH user
- SSH config name (e.g., `valor-vm`)
- Available services and ports

### 4. Execute

Run the command via the chosen method. Capture stdout and stderr.
Report the output and exit code.

### 5. Safety checks

Before executing, verify:
- The command is NOT destructive (`rm -rf`, `DROP`, `shutdown`, `reboot`)
  without explicit user confirmation
- The command does NOT contain secrets or passwords in plain text
- For database commands, prefer read-only queries unless the user
  explicitly asks for writes

### 6. Common patterns

```
/remote status              → ssh valor-vm 'sudo systemctl is-active valor-montycore valor-agents nginx postgresql'
/remote logs                → ssh valor-vm 'journalctl -fu valor-montycore --no-pager -n 50'
/remote health              → ssh valor-vm 'curl -s http://localhost/health'
/remote psql SELECT ...     → ssh valor-vm 'sudo -u postgres psql -d valor_db -c "SELECT ..."'
/remote deploy              → ssh valor-vm 'cd ~/valor2.0 && git pull && sudo systemctl restart valor-montycore valor-agents'
/remote df                  → ssh valor-vm 'df -h'
```
