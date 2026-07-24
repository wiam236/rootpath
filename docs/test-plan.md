# Test Plan — Rootpath

Automated tests live under `tests/`. Each script prints `[PASS]`/`[FAIL]`
per check and exits non-zero if any check fails.

## 1. `tests/test_deployment.sh`

Verifies the base deployment succeeded, independent of vulnerable/hardened
state.

| Test case            | Expected result |
|----------------------|----------------------------------------------------|
| User `websvc` exists | `id websvc` succeeds |
| User `operator` exists | `id operator` succeeds |
| User `student` exists | `id student` succeeds |
| `rootpath-web.service` is active | `systemctl is-active` returns `active` |
| Web application responds | HTTP GET on `/` returns status `200` |

**Run**: `sudo bash /vagrant/tests/test_deployment.sh` (or `make validate`)

## 2. `tests/test_vulnerable.sh`

Verifies that both mandatory vulnerabilities are present and exploitable.
Should be run after `make reset`, before `make harden`.

| Test case                                  | Expected result |
|--------------------------------------------|---------------------------------------------------------|
| Command injection via `host` parameter | Response contains `websvc` (output of injected `whoami`) |
| `cleanup.sh` is group-writable by `websvc` | Group is `websvc`, permission mode matches `77x`/`76x` |
| `backup.sh` allows path traversal | A file is created outside `/opt/rootpath/backups` when given `../../../etc/passwd` |

**Run**: `sudo bash /vagrant/tests/test_vulnerable.sh` (or `make test`)

**Known limitation**: the path-traversal check only verifies that the
`.bak` copy is created — it does not verify the copy is *readable*, since
that depends on the target file's own permissions (e.g. `/etc/shadow`
remains unreadable to `operator` even after being copied, while
`/etc/passwd` is readable). This is documented in `docs/remediation.md`.

## 3. `tests/test_hardened.sh`

Verifies both vulnerabilities are corrected, and legitimate features are
preserved. Should be run after `make harden`.

| Test case                           | Expected result |
|-------------------------------------|----------------------------------------------|
| Legitimate ping feature still works | Response contains `bytes from` |
| Command injection is blocked | Response does NOT contain `websvc` |
| `cleanup.sh` ownership/permissions corrected | Owner is `root`, mode is `755` |
| Legitimate backup feature still works | `backup.sh sample.txt` creates `sample.txt.bak` |
| `backup.sh` rejects path traversal | No file created outside `/opt/rootpath/backups` |

**Run**: `sudo bash /vagrant/tests/test_hardened.sh`

## 4. Known false positives / fragile checks

- The command-injection test in `test_vulnerable.sh` greps for the literal
  string `websvc` in the HTTP response. If a future legitimate feature
  happens to print this string for an unrelated reason, the test could
  report a false positive. Currently this is not the case.
- All tests assume the VM's system clock is reasonably synchronized;
  a large clock skew (encountered during development, see project
  history) can cause unrelated `apt-get` failures that are not covered
  by this test suite, since it is a provisioning-time issue rather than
  a lab vulnerability.

## 5. Manual verification (not automated)

Some checks are validated manually rather than scripted, since they
require an interactive session or network-level testing:

- Full privilege escalation via path A (SUID bash copy) — demonstrated
  manually in `docs/walkthrough.md`, not scripted, since it requires
  waiting for a live cron execution and leaves a filesystem artifact
  (`/tmp/rootbash`) that must be cleaned up.
- Reverse-shell foothold establishment — inherently interactive
  (requires a listener on the attacker workstation), not suited to a
  single automated script.
