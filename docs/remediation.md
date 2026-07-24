# Remediation Guide — Rootpath

This document explains, for each mandatory vulnerability, the root cause,
the impact, the correction applied, and any residual risk. Corresponding
script: `scripts/harden.sh`.

## 1. OS Command Injection (web application)

**Root cause**: user input (`host` parameter) was concatenated into a shell
string and executed with `subprocess.run(..., shell=True)`, allowing shell
metacharacters (`;`, `&&`, `|`) to inject arbitrary commands.

**Impact**: any unauthenticated visitor could execute arbitrary commands as
the `websvc` user, providing the initial foothold for the entire attack
chain.

**Correction**: the vulnerable `app.py` is replaced with the pre-existing
secure implementation (`app_secure.py`), which passes arguments as a list
to `subprocess.run` (no shell interpretation) and validates the input
against a strict hostname/IP regex before use.

**Residual risk**: the underlying `ping` binary itself is not sandboxed;
if a future feature accepted more complex input, the same class of bug
could reappear. Input validation should be re-reviewed for any new
feature added to this service.

## 2. Privilege Escalation A — Group-writable scheduled task

**Root cause**: `cleanup.sh`, executed every minute by root via cron, was
owned by `root:websvc` with group-write permission (`774`), allowing the
low-privilege `websvc` account to modify a script that root would
subsequently execute.

**Impact**: `websvc` could rewrite the script's contents to execute
arbitrary commands as root (demonstrated via a SUID copy of `/bin/bash`),
achieving full privilege escalation from a web-application foothold.

**Correction**: ownership and permissions are corrected to `root:root` with
mode `755` — no other user or group can write to the file, while root
(via cron) can still read and execute it, preserving the legitimate
cleanup task.

**Residual risk**: none identified for this specific script; however, any
other script referenced by a root-owned cron/timer entry must follow the
same ownership discipline, or the same class of vulnerability could be
reintroduced elsewhere.

## 3. Privilege Escalation B — Unsafe sudo rule (path traversal)

**Root cause**: `backup.sh`, callable as root by `operator` via a scoped
sudoers rule, used its filename argument directly in a `cp` command
without validating it, allowing path traversal sequences (`../../../etc/passwd`)
to reference files outside the intended `/opt/rootpath/data` directory.

**Impact**: `operator` could cause root to read and copy arbitrary
files on the filesystem (subject to the target file's own read
permissions), well beyond the single intended backup function.

**Correction**: the sudoers rule itself is left unchanged (scoped to this
one script only, never `ALL`); instead, `backup.sh` is replaced with a
version that rejects any filename containing `/` or starting with `..`,
restricting operation strictly to plain filenames inside the data
directory.

**Residual risk**: the fix relies on a denylist-style check (`/` and
`..`) rather than a strict allowlist regex; a more defensive
implementation could further restrict filenames to `^[A-Za-z0-9._-]+$`
for stronger guarantees.

