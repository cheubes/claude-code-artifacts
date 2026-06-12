# claude-code-artifacts

A collection of custom skills for [Claude Code](https://claude.ai/code).

## Deploying a skill

```bash
./deploy-skill.sh <skill-directory>
```

This packages the skill into `bin/<name>.zip` and copies it to `~/.claude/skills/`.

Use `--link` to deploy as a symlink instead — edits to the source are reflected immediately without redeploying:

```bash
./deploy-skill.sh <skill-directory> --link
```

If `~/.claude/skills/` did not exist before, restart Claude Code once for the skill to be detected.

## Skills

### image-exif

Checks and edits EXIF metadata fields (Title, Creator, Copyright, WebStatement) on image files.

```
/image-exif check <file(s)>
/image-exif edit <file>
```
