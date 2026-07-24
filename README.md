# Rootpath

A deliberately vulnerable Linux laboratory for introduction to offensive
security. Build it, break it, fix it, prove it.

See `docs/architecture.md` for the full design, `docs/student-guide.md` to
attempt the lab yourself, or `docs/walkthrough.md` for the full solution.

## Prerequisites

- [Vagrant](https://developer.hashicorp.com/vagrant/downloads) (tested
  with 2.4.9)
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
- A Bash-capable shell to run the provided scripts (Linux, macOS, or WSL2
  on Windows)
- (Optional) `make`, if you want to use the Makefile targets directly
  instead of the equivalent commands below

## Quick start

```bash
git clone <this-repo-url>
cd rootpath
vagrant up
```

This provisions a Debian VM on a private network (`192.168.56.10`),
creates the required user accounts, installs the vulnerable web service,
and installs both privilege-escalation paths and the lab flags.

Visit `http://192.168.56.10/` in a browser to confirm the deployment.

## Lifecycle commands

The primary interface is the `Makefile`. If `make` is not available on
your system, the equivalent `vagrant`/shell commands are given alongside.

| Action | `make` command | Equivalent command |
|---|---|---|
| Deploy the lab | `make deploy` | `vagrant up` |
| Validate deployment | `make validate` | `vagrant ssh -c "sudo bash /vagrant/tests/test_deployment.sh"` |
| Reset to vulnerable state | `make reset` | `vagrant ssh -c "sudo bash /vagrant/scripts/reset.sh"` |
| Apply hardening | `make harden` | `vagrant ssh -c "sudo bash /vagrant/scripts/harden.sh"` |
| Run test suite | `make test` | `vagrant ssh -c "sudo bash /vagrant/tests/test_deployment.sh && sudo bash /vagrant/tests/test_vulnerable.sh"` |
| Destroy the lab | `make destroy` | `vagrant destroy -f` |

To specifically test the hardened state after running `make harden`:
```bash
vagrant ssh -c "sudo bash /vagrant/tests/test_hardened.sh"
```

## Repository layout

```
.
├── README.md
├── Makefile
├── Vagrantfile
├── app/                  # Vulnerable web application
│   ├── src/
│   │   ├── app.py         # Vulnerable version (default, active)
│   │   └── app_secure.py  # Secure reference used by the hardened profile
│   ├── requirements.txt
│   └── systemd/
├── provisioning/         # Deployment scripts (run automatically by Vagrant)
│   ├── packages.sh
│   ├── users.sh
│   ├── services.sh
│   ├── privesc_a.sh
│   ├── privesc_b.sh
│   ├── flags.sh
│   └── files/            # Source files copied by the scripts above
├── scripts/              # Lab lifecycle tools
│   ├── enumerate.sh       # Custom enumeration tool (run from inside the VM)
│   ├── reset.sh
│   └── harden.sh
├── tests/                # Automated test suites
│   ├── test_deployment.sh
│   ├── test_vulnerable.sh
│   └── test_hardened.sh
└── docs/
    ├── architecture.md
    ├── threat-model.md
    ├── student-guide.md
    ├── walkthrough.md
    ├── remediation.md
    └── test-plan.md
```

## Troubleshooting

**`apt-get update` fails with "Release file ... is not valid yet"**
The VM's clock is out of sync with the host. This was resolved during
development by adding `-o Acquire::Check-Valid-Until=false -o
Acquire::Check-Date=false` to the `apt-get update` call in
`provisioning/packages.sh` — already applied in this repo. If it recurs,
resync the VM clock: `vagrant ssh -c "sudo hwclock --systohc"`.

**`make: command not found` (Windows)**
Install `make` via [Chocolatey](https://chocolatey.org/) (`choco install
make -y`), or simply use the equivalent commands listed in the table
above — the Makefile is not required to operate the lab.

**`vagrant provision` fails on a missing file**
Ensure any file referenced by a provisioning script (e.g. under
`provisioning/files/` or `app/`) has actually been committed/copied to
the project root that Vagrant reads from, not just to a separate working
copy.

**Reverse shell payload doesn't connect back**
Confirm the target can reach your listener's IP over the network (a
simple `ping` from inside the VM is enough to check reachability) before
troubleshooting the payload itself.

## Safety notice

This lab must only run on an isolated, private network, using synthetic
data only. It is intended for authorized local training. Do not point any
of the techniques demonstrated here at systems you do not own or have
explicit authorization to test.
