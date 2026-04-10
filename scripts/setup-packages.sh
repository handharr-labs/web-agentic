#!/usr/bin/env bash
# setup-packages.sh
# Interactive package installer for web-agentic.
# Presents available packages, lets the user choose, then symlinks only the
# selected agents and skills. Core package is always installed.
#
# Usage (run from the downstream project root):
#   .claude/web-agentic/scripts/setup-packages.sh
#
# Re-running is safe — existing symlinks are never overwritten.

set -euo pipefail

SUBMODULE="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_ROOT="$(cd "$SUBMODULE/../.." && pwd)"
CLAUDE_DIR="$PROJECT_ROOT/.claude"
PACKAGES_DIR="$SUBMODULE/packages"

# ── Helpers ──────────────────────────────────────────────────────────────────

bold()    { printf '\033[1m%s\033[0m' "$*"; }
green()   { printf '\033[32m%s\033[0m' "$*"; }
yellow()  { printf '\033[33m%s\033[0m' "$*"; }
cyan()    { printf '\033[36m%s\033[0m' "$*"; }
reset()   { printf '\033[0m'; }

link_agent() {
  local name="$1"
  local src="$SUBMODULE/agents/$name.md"
  local link="$CLAUDE_DIR/agents/$name.md"
  if [ ! -f "$src" ]; then
    echo "  $(yellow "warn")  agent $name not found in web-agentic — skipping"
    return
  fi
  if [ -e "$link" ] || [ -L "$link" ]; then
    echo "  skip  agents/$name.md"
  else
    ln -s "../web-agentic/agents/$name.md" "$link"
    echo "  $(green "link")  agents/$name.md"
  fi
}

link_skill() {
  local name="$1"
  local src="$SUBMODULE/skills/$name"
  local link="$CLAUDE_DIR/skills/$name"
  if [ ! -d "$src" ]; then
    echo "  $(yellow "warn")  skill $name not found in web-agentic — skipping"
    return
  fi
  if [ -e "$link" ] || [ -L "$link" ]; then
    echo "  skip  skills/$name"
  else
    ln -s "../web-agentic/skills/$name" "$link"
    echo "  $(green "link")  skills/$name"
  fi
}

read_pkg() {
  local file="$1"
  local field="$2"
  grep "^${field}=" "$file" | cut -d= -f2-
}

install_pkg() {
  local pkg_file="$1"
  local pkg_name
  pkg_name="$(read_pkg "$pkg_file" name)"
  local agents skills

  echo ""
  echo "  Installing $(bold "$pkg_name")..."

  agents="$(read_pkg "$pkg_file" agents)"
  skills="$(read_pkg "$pkg_file" skills)"

  for agent in $agents; do
    link_agent "$agent"
  done

  for skill in $skills; do
    link_skill "$skill"
  done
}

# ── Directory setup ───────────────────────────────────────────────────────────

echo ""
echo "$(bold "web-agentic package installer")"
echo "────────────────────────────────────────"

# Convert any old-style directory symlinks
for dir in "$CLAUDE_DIR/agents" "$CLAUDE_DIR/skills"; do
  if [ -L "$dir" ]; then
    echo "convert  $dir (directory symlink → real directory)"
    rm "$dir"
    mkdir -p "$dir"
  fi
done

mkdir -p \
  "$CLAUDE_DIR/agents" \
  "$CLAUDE_DIR/skills" \
  "$CLAUDE_DIR/agents.local/extensions" \
  "$CLAUDE_DIR/skills.local/extensions"

# ── Local overrides first ─────────────────────────────────────────────────────

for agent in "$CLAUDE_DIR/agents.local"/*.md; do
  [ -f "$agent" ] || continue
  name="$(basename "$agent")"
  if [ ! -e "$CLAUDE_DIR/agents/$name" ] && [ ! -L "$CLAUDE_DIR/agents/$name" ]; then
    ln -s "../agents.local/$name" "$CLAUDE_DIR/agents/$name"
    echo "  $(green "link")  agents/$name (local override)"
  fi
done

for skill_dir in "$CLAUDE_DIR/skills.local"/*/; do
  [ -d "$skill_dir" ] || continue
  name="$(basename "$skill_dir")"
  if [ ! -e "$CLAUDE_DIR/skills/$name" ] && [ ! -L "$CLAUDE_DIR/skills/$name" ]; then
    ln -s "../skills.local/$name" "$CLAUDE_DIR/skills/$name"
    echo "  $(green "link")  skills/$name (local override)"
  fi
done

# ── Core (always installed) ───────────────────────────────────────────────────

install_pkg "$PACKAGES_DIR/core.pkg"

# ── Package selection ─────────────────────────────────────────────────────────

echo ""
echo "$(bold "Available packages:")"
echo ""

# Load non-core packages
optional_pkgs=()
for pkg_file in "$PACKAGES_DIR"/*.pkg; do
  pkg_name="$(read_pkg "$pkg_file" name)"
  [ "$pkg_name" = "core" ] && continue
  optional_pkgs+=("$pkg_file")
done

# Display menu
i=1
for pkg_file in "${optional_pkgs[@]}"; do
  pkg_name="$(read_pkg "$pkg_file" name)"
  pkg_desc="$(read_pkg "$pkg_file" description)"
  printf "  $(cyan "[%d]") %-14s %s\n" "$i" "$pkg_name" "$pkg_desc"
  i=$((i + 1))
done

echo ""
echo "  Enter package numbers to install (e.g. $(bold "1 2")), $(bold "all"), or $(bold "none"):"
printf "  > "
read -r selection

echo ""

if [ "$selection" = "none" ]; then
  echo "  No optional packages selected."
elif [ "$selection" = "all" ]; then
  for pkg_file in "${optional_pkgs[@]}"; do
    install_pkg "$pkg_file"
  done
else
  for num in $selection; do
    if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "${#optional_pkgs[@]}" ]; then
      install_pkg "${optional_pkgs[$((num - 1))]}"
    else
      echo "  $(yellow "warn")  '$num' is not a valid option — skipping"
    fi
  done
fi

# ── Hooks ─────────────────────────────────────────────────────────────────────

echo ""
echo "Making hooks executable..."
chmod +x "$SUBMODULE/hooks/"*.sh

# ── Settings ─────────────────────────────────────────────────────────────────

echo ""
if [ -f "$CLAUDE_DIR/settings.local.json" ]; then
  echo "skip  .claude/settings.local.json (already exists)"
else
  cp "$SUBMODULE/settings-template.json" "$CLAUDE_DIR/settings.local.json"
  echo "copy  .claude/settings.local.json"
  echo ""
  echo "  $(yellow "⚠")  Edit .claude/settings.local.json — replace PROJECT_ROOT with:"
  echo "     $CLAUDE_DIR"
fi

# ── CLAUDE.md ─────────────────────────────────────────────────────────────────

echo ""
if [ -f "$PROJECT_ROOT/CLAUDE.md" ]; then
  echo "skip  CLAUDE.md (already exists)"
else
  cp "$SUBMODULE/CLAUDE-template.md" "$PROJECT_ROOT/CLAUDE.md"
  echo "copy  CLAUDE.md (from CLAUDE-template.md)"
  echo ""
  echo "  $(yellow "⚠")  Edit CLAUDE.md — fill in [AppName] and stack placeholders"
fi

# ── Done ──────────────────────────────────────────────────────────────────────

echo ""
echo "────────────────────────────────────────"
echo "$(green "Done.") web-agentic packages installed."
echo ""
echo "Next steps:"
echo "  1. Fill in CLAUDE.md placeholders"
echo "  2. Edit .claude/settings.local.json — replace PROJECT_ROOT"
echo "  3. git add .claude/ && git commit -m 'chore: wire web-agentic packages'"
