#!/bin/bash
# Claude Code Pre-Tool-Use Hook: Block Destructive Commands
# Installation: cp this file to ~/.claude/hooks/pre-tool-use/
#
# This hook intercepts bash commands before execution and blocks
# dangerous patterns like rm -rf, DROP TABLE, git push --force, etc.

LOG_FILE="${HOME}/.claude/hooks/blocked.log"
mkdir -p "$(dirname "$LOG_FILE")"

# Get the command from Claude Code environment
# Claude Code passes the command via CLAUDE_COMMAND env var
CMD="${CLAUDE_COMMAND:-$*} "

# Block patterns (case-insensitive)
PATTERNS=(
  "rm[[:space:]]+-rf"
  "rm[[:space:]]+-r[[:space:]]+-f"
  "rm[[:space:]]+--recursive[[:space:]]+--force"
  "DROP[[:space:]]+TABLE"
  "DROP[[:space:]]+DATABASE"
  "TRUNCATE[[:space:]]+"
  "git[[:space:]]+push[[:space:]]+--force"
  "git[[:space:]]+push[[:space:]]+-f"
  "DELETE[[:space:]]+FROM[[:space:]]+"
)

# Check if WHERE clause exists for DELETE commands
has_where() {
  echo "$CMD" | grep -qi "WHERE"
  return $?
}

# Determine if command should be blocked
# Returns 0 (block) or 1 (allow)
should_block() {
  local cmd_lower
  cmd_lower=$(echo "$CMD" | tr "[:upper:]" "[:lower:]")
  
  for pattern in "${PATTERNS[@]}"; do
    if echo "$cmd_lower" | grep -qE "$pattern"; then
      # Special case: DELETE FROM without WHERE is blocked
      # DELETE FROM with WHERE is allowed
      if echo "$cmd_lower" | grep -q "delete[[:space:]]+from"; then
        if has_where; then
          return 1  # Has WHERE, allow
        fi
        return 0  # No WHERE, block
      fi
      return 0  # Block
    fi
  done
  return 1  # Allow
}

# Log blocked command
log_block() {
  local timestamp
  timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  local project_path="${PWD}"
  echo "[${timestamp}] BLOCKED | cmd: ${CMD} | pwd: ${project_path}" >> "$LOG_FILE"
}

# Main logic
if should_block; then
  log_block
  cat << "BLOCKED_MSG"
  ______ _            _
  | ___ \ |          | |
  | |_/ / | ___   ___| | _____
  | ___ \ |/ _ \ / __| |/ / __|
  | |_/ / | (_) | (__|   <\__ \
  \____/|_|\___/ \___|_|\_\___/

  ⚠️  DESTRUCTIVE COMMAND BLOCKED

  The command was blocked because it matches a dangerous pattern.
  This is enforced by the pre-tool-use security hook.

  Blocked pattern detected in:
    $ ${CMD}

  If you intended to run this command, use one of these approaches:
    1. Manually run it in your terminal outside Claude Code
    2. Temporarily disable the hook: mv ~/.claude/hooks/pre-tool-use ~/.claude/hooks/pre-tool-use.disabled
    3. For DROP/TRUNCATE/DELETE, use explicit WHERE clauses

  The attempt has been logged to: ~/.claude/hooks/blocked.log
BLOCKED_MSG
  exit 1
fi

exit 0
