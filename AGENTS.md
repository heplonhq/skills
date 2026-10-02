# AGENTS.md

This repository contains agent skills that Heplon publishes. People install them with `npx skills add heplonhq/skills`.

## Layout

- `skills/<name>/SKILL.md`: one directory for each skill. The skills CLI finds skills here.
- `skills/<name>/scripts/`, `references/`, `assets/`: optional files that the skill uses.
- `scripts/validate.sh`: the check that CI runs.

## Rules for a skill

- The directory name and the `name` in the frontmatter are the same. Use lowercase letters, digits and hyphens.
- The `description` is on one line and has 1024 characters or fewer. It says what the skill does and when the agent must use it.
- Keep `SKILL.md` below 500 lines. Put long material in `references/` and link to it.
- A skill must work with all agents. Do not use tools that only one agent has.
- A skill must not send code, secrets or data out of the user's repository.
- A skill asks for confirmation before it does a destructive action.

## Checks

```bash
scripts/validate.sh
npx skills add . --list
```

Run the two commands before each commit. Update the skills table in `README.md` when you add, rename or remove a skill.
