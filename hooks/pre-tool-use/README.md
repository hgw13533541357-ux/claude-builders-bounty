# Pre-Tool-Use Security Hook

Blocks destructive bash commands from being executed by Claude Code.

## Installation

```bash
# One-command install:
cp hooks/pre-tool-use/block-destructive.sh ~/.claude/hooks/pre-tool-use/
chmod +x ~/.claude/hooks/pre-tool-use/block-destructive.sh
```

## What It Blocks

| Pattern | Blocked | Notes |
|---------|---------|-------|
| `rm -rf` / `rm -r -f` / `rm --recursive --force` | ✅ Yes | Recursive force delete |
| `DROP TABLE` / `DROP DATABASE` | ✅ Yes | Destructive DDL |
| `TRUNCATE` | ✅ Yes | Table truncation |
| `git push --force` / `git push -f` | ✅ Yes | Force push (rewrites history) |
| `DELETE FROM` without `WHERE` | ✅ Yes | Unconditional row deletion |
| `DELETE FROM` with `WHERE` | ✅ No | Safe delete with condition |
| Normal commands | ✅ No | No interference |

## Logging

All blocked attempts are logged to:
```
~/.claude/hooks/blocked.log
```
Format: `[timestamp] BLOCKED | cmd: <command> | pwd: <project_path>`

## How It Works

Claude Code calls pre-tool-use hooks before executing bash commands.
This hook checks the command against known dangerous patterns.
If matched, it prints a clear block message, logs the attempt, and exits non-zero.

## Requirements

- Bash 3.2+
- Claude Code with hooks support

## Resources

- [Claude Code Hooks Documentation](https://docs.anthropic.com/claude-code/hooks)
- [Issue #3](https://github.com/claude-builders-bounty/claude-builders-bounty/issues/3)
