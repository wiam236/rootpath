# Architecture — Rootpath

## 1. Virtualization approach

- Hypervisor: VirtualBox, orchestrated by Vagrant.
- Reproducibility: the entire target is defined in a single `Vagrantfile` plus provisioning scripts under `provisioning/`. A fresh `vagrant up` must produce an identical machine every time.

## 2. Target operating system

- OS: Debian (bookworm, stable branch).
- Box: `debian/bookworm64` (official Debian Vagrant box).

## 3. Network

| Item | Value |
|------|-------|
| Network type | Private / host-only |
| Target IP | `192.168.56.10` |
| Attacker workstation | Same private network, e.g. `192.168.56.1` (host) |
| Exposed ports | `80/tcp` (vulnerable web app), `22/tcp` (SSH, private network only) |
| Internet access | Allowed during provisioning only; not required at runtime |
| Public/production exposure | None — private network only |

## 4. Accounts and privilege levels

| Account | Purpose | Privilege level |
|---------|---------|-----------------|
| `root` | System owner | Administrative — never used by the web app |
| `websvc` | Runs the vulnerable web service | Low privilege, dedicated service account |
| `operator` | Owns the legitimate maintenance function (sudo rule) | Standard user, scoped sudo rights |
| `student` | Optional troubleshooting entry point | Standard user, not part of the attack path |

## 5. Services and scheduled tasks

| Component | Runs as | Mechanism | Purpose |
|---|---|---|---|
| Web application (`ping` diagnostic tool) | `websvc` | systemd service, bound to `192.168.56.10:80` | Legitimate feature + intentional command-injection vulnerability |
| Privileged maintenance task | `root` | systemd timer (or cron), frequent interval | Intentionally influenced by a low-privilege-writable file/script (privilege-escalation path A) |
| Sudo maintenance script | `operator` (via `sudo`) | Restricted sudoers rule | Legitimate backup/maintenance function with an unsafe argument-handling flaw (privilege-escalation path B) |

## 6. Intended attack path

```
1. Discover the web service on 192.168.56.10:80
2. Exploit the OS command injection in the ping feature → obtain a shell as websvc
3. Run the custom enumeration script as websvc
4. Identify path A (writable file/script executed by root's scheduled task) OR path B (unsafe sudo rule for operator)
5. Escalate to root via either path (independently)
6. Read root.txt
7. Apply `make harden`
8. Re-run tests to confirm both paths are closed while the legitimate ping feature and maintenance script still work
```

## 7. Trust boundaries and isolation assumptions

- The private network (`192.168.56.0/24`) is the only boundary between the attacker workstation and the target — no other network path exists.
- The VM is assumed to have no access to production systems, no access to the host filesystem beyond what Vagrant/VirtualBox itself requires, and no privileged Docker components.
- The web application process boundary (`websvc`) is a hard boundary: it must never run with root privileges, so the initial foothold is always low-privilege by construction.
- The two privilege-escalation paths (A: scheduled task, B: sudo rule) are designed to be independent: fixing one must not implicitly fix the other, since they rely on different underlying mechanisms (file
  permissions/execution context vs. sudoers configuration).
- Internet access is only assumed during initial provisioning (package
  installation); the running lab must not depend on it.