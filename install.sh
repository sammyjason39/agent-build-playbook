#!/usr/bin/env bash
# Symlink every skill in ./skills into the global skills folder of one or more agents.
#
#   ./install.sh                 # Claude Code (default)
#   ./install.sh claude opencode hermes antigravity antigravity-cli agents
#   ./install.sh all
#
# Targets (global, all projects):
#   claude           ~/.claude/skills/<skill>                 (also read by opencode)
#   opencode         ~/.config/opencode/skills/<skill>
#   agents           ~/.agents/skills/<skill>                 (shared path: opencode and others)
#   antigravity      ~/.gemini/config/skills/<skill>          (Antigravity IDE)
#   antigravity-cli  ~/.gemini/antigravity-cli/skills/<skill> (Antigravity CLI `agy`)
#   hermes           ~/.hermes/skills/agent-build-playbook -> ./skills (one category folder)
#
# Symlinks mean `git pull` updates every agent at once. Existing symlinks are replaced;
# real directories with the same name are left alone. Set SKILLS_COPY=1 to copy instead
# (for tools or sandboxes that do not follow symlinks).
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
targets=("$@")
[ ${#targets[@]} -eq 0 ] && targets=(claude)
[ "${targets[0]}" = all ] && targets=(claude opencode agents antigravity antigravity-cli hermes)

place() { # <source> <destination>
  local src=$1 dst=$2
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    echo "  skip $dst (exists and is not a symlink)"; return
  fi
  if [ "${SKILLS_COPY:-0}" = 1 ]; then
    rm -f "$dst"; cp -R "$src" "$dst"; echo "  copied $(basename "$src") -> $dst"
  else
    ln -sfn "$src" "$dst"; echo "  linked $(basename "$src") -> $dst"
  fi
}

per_skill() { # <destination dir>
  mkdir -p "$1"
  for skill in "$here"/skills/*/; do place "${skill%/}" "$1/$(basename "$skill")"; done
}

for t in "${targets[@]}"; do
  echo "[$t]"
  case $t in
    claude) per_skill "${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}" ;;
    opencode) per_skill "$HOME/.config/opencode/skills" ;;
    agents) per_skill "$HOME/.agents/skills" ;;
    antigravity) per_skill "$HOME/.gemini/config/skills" ;;
    antigravity-cli) per_skill "$HOME/.gemini/antigravity-cli/skills" ;;
    hermes) mkdir -p "$HOME/.hermes/skills"; place "$here/skills" "$HOME/.hermes/skills/agent-build-playbook" ;;
    *) echo "  unknown target: $t (use claude|opencode|agents|antigravity|antigravity-cli|hermes|all)"; exit 2 ;;
  esac
done
