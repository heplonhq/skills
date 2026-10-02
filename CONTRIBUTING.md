# Contributing

## Report a problem or suggest a skill

Open an [issue](https://github.com/heplonhq/skills/issues/new/choose). For security problems, read [SECURITY.md](SECURITY.md).

## Add or change a skill

1. Create the skill.

   ```bash
   cd skills
   npx skills init my-skill
   ```

2. Edit `skills/my-skill/SKILL.md`. The rules are in [AGENTS.md](AGENTS.md).
3. Run the checks.

   ```bash
   scripts/validate.sh
   npx skills add . --list
   ```

4. Install the skill in a test repository and run it with an agent.

   ```bash
   npx skills add /path/to/this/repo --skill my-skill
   ```

5. Add the skill to the table in `README.md`.
6. Open a pull request.

## License

Your contribution is released under the [MIT License](LICENSE).
