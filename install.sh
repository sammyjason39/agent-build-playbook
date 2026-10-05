#!/usr/bin/env bash
# Symlink every skill into ~/.claude/skills (personal skills, all projects).
# Re-run after `git pull`; existing links are replaced, real directories are left alone.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
dest=${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}
mkdir -p "$dest"
for skill in "$here"/skills/*/; do
  name=$(basename "$skill")
  target=$dest/$name
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    echo "skip $name: $target exists and is not a symlink"; continue
  fi
  ln -sfn "${skill%/}" "$target"
  echo "linked $name -> $target"
done
