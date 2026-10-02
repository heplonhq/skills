# Heplon Skills

[![skills.sh](https://skills.sh/b/heplonhq/skills)](https://skills.sh/heplonhq/skills)
[![Validate skills](https://github.com/heplonhq/skills/actions/workflows/validate.yml/badge.svg)](https://github.com/heplonhq/skills/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Agent skills that find and fix the problems that cause incidents and slow down engineering teams. Made by [Heplon](https://heplon.com).

The skills work with Claude Code, Cursor, Codex, GitHub Copilot and all other agents that the [skills CLI](https://www.skills.sh/docs) supports.

## Install

```bash
npx skills add heplonhq/skills
```

Install one skill:

```bash
npx skills add heplonhq/skills --skill <name>
```

Show the skills without an installation:

```bash
npx skills add heplonhq/skills --list
```

Add `--global` to install for all your projects.

## Skills

| Skill | What it does |
| ----- | ------------ |
| [`find-flaky-test`](skills/find-flaky-test/SKILL.md) | Finds one flaky test from your CI history, proves that it is flaky, finds the root cause and fixes it. |

## Update and remove

```bash
npx skills update
npx skills remove <name>
```

## Want this for your full system?

A skill runs in one repository when you ask for it. Heplon connects to GitHub, GitLab, Kubernetes, PagerDuty and your other tools, scans continuously and opens pull requests with fixes. See [heplon.com](https://heplon.com).

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md). To report a vulnerability, read [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE)
