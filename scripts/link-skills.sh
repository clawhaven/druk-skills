#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_DIR="$REPO_ROOT/skills"
TARGET_DIR="${AGENT_SKILLS_DIR:-${CODEX_SKILLS_DIR:-${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}}}"

mkdir -p "$TARGET_DIR"

linked=0
skipped=0
created=0

for skill_path in "$SOURCE_DIR"/*; do
  [ -d "$skill_path" ] || continue
  skill_name="$(basename "$skill_path")"
  target_path="$TARGET_DIR/$skill_name"

  if [ -L "$target_path" ]; then
    current_target="$(readlink "$target_path" || true)"
    desired_target="$skill_path"
    if [ "$current_target" = "$desired_target" ]; then
      echo "skip: $skill_name (already linked)"
      skipped=$((skipped + 1))
      continue
    else
      echo "skip: $skill_name (symlink exists but points elsewhere: $current_target)"
      skipped=$((skipped + 1))
      continue
    fi
  fi

  if [ -e "$target_path" ]; then
    echo "skip: $skill_name (target already exists at $target_path)"
    skipped=$((skipped + 1))
    continue
  fi

  ln -s "$skill_path" "$target_path"
  echo "linked: $skill_name -> $target_path"
  linked=$((linked + 1))
  created=$((created + 1))
done

echo
echo "done: linked=$linked skipped=$skipped target_dir=$TARGET_DIR"
