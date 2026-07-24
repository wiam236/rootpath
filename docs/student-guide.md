# Student Guide — Rootpath

Welcome to Rootpath, a deliberately vulnerable Linux lab. Your goal is to
go from zero access to a full root compromise, then understand how to fix
what you exploited. No solution is given here — use your own tools,
research skills, and the custom enumeration tool provided in this repo.

## Rules of engagement

- This lab runs on an isolated private network (`192.168.56.0/24`).
  **Only** interact with the target machine defined in this project.
  Never point any of these techniques at systems you do not own or have
  explicit authorization to test.
- No kernel exploits are needed or allowed for this lab.
- No brute-forcing of credentials is required.
- You are expected to use only standard Linux tools (curl, a browser,
  an SSH client, common shell utilities).

## Environment

- Target IP: `192.168.56.10`
- A single web service is exposed on port 80.
- SSH (port 22) is available, but is not part of the intended attack path
  for a first-time visitor.

## Objectives

1. **Discover** what service is running on the target and what it does.
2. **Find an initial foothold** — a way to execute commands on the target
   without valid credentials. Think about how user-supplied input is
   handled by the web application.
3. **Enumerate** the system once you have a shell. A custom enumeration
   script is provided at `scripts/enumerate.sh` — run it and read every
   section carefully. It distinguishes plain facts (`[+]`) from
   potential security findings (`[!]`).
4. **Escalate to root.** There are **two independent paths**. Finding one
   does not mean the other is related to it — think about different
   categories of Linux privilege boundaries (scheduled tasks vs. sudo
   configuration).
5. Once you have root, locate `root.txt`. There is also a `user.txt`
   readable once you've obtained your initial foothold.
6. Read `docs/remediation.md` (after you've completed the exercise, not
   before) to understand the "why" behind each vulnerability and how it
   was fixed.

## Hints (use only if you're stuck)

<details>
<summary>Hint 1 — Initial foothold</summary>

The web application offers a single, simple network diagnostic feature.
Think about what happens to the text you type into that field before it
reaches the operating system. What characters might change how a shell
interprets your input?
</details>

<details>
<summary>Hint 2 — Privilege escalation path A</summary>

Once you have a shell, look closely at what root does automatically and
repeatedly in the background. Ownership of a file and the ability to
*write* to it are two different things — check both.
</details>

<details>
<summary>Hint 3 — Privilege escalation path B</summary>

`sudo -l` tells you what you're allowed to run as another user. Being
restricted to a single script doesn't mean that script is safe — look at
how it handles the arguments you give it.
</details>

## What to submit / demonstrate

- Evidence of your initial foothold (e.g., a screenshot or transcript of
  a shell as the low-privilege service account).
- Contents of both flags.
- A short explanation, in your own words, of both privilege-escalation
  paths and why they worked.

Good luck — and remember: the goal is understanding the full chain, not
just reaching root as fast as possible.
