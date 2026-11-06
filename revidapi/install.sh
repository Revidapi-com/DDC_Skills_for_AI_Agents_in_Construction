#!/usr/bin/env bash
# Install the DDC construction skills into Claude Code, Codex and Hermes Agent,
# and point their Python examples at RevidAPI (OpenAI-compatible).
#
#   bash revidapi/install.sh                 # every app found on this machine
#   bash revidapi/install.sh claude codex    # only these
#
# Safe by design:
#   - only folders that contain SKILL.md are copied; the repo's .claude/ folder is NOT
#   - a skill folder you already have (not installed by this script) is never overwritten
#   - your API key is never written by this script; set REVIDAPI_API_KEY yourself
set -euo pipefail

GOC="$(cd "$(dirname "$0")/.." && pwd)"
DAU="# installed by DDC x RevidAPI"
APPS=("$@"); [ ${#APPS[@]} -eq 0 ] && APPS=(claude codex hermes)

dich() {
  case "$1" in
    claude) echo "$HOME/.claude/skills" ;;
    codex)  echo "${CODEX_HOME:-$HOME/.codex}/skills" ;;
    hermes) echo "$HOME/.hermes/skills/construction" ;;
    *) echo "" ;;
  esac
}
co_app() {
  case "$1" in
    claude) [ -d "$HOME/.claude" ] || command -v claude >/dev/null ;;
    codex)  [ -d "${CODEX_HOME:-$HOME/.codex}" ] || command -v codex >/dev/null ;;
    hermes) [ -d "$HOME/.hermes" ] || command -v hermes >/dev/null ;;
  esac
}

# Sorted so 1_DDC_Toolkit wins when two folders share a name.
DS=$(cd "$GOC" && find . -name SKILL.md -not -path './.git/*' -not -path './.claude/*' | sort)

for app in "${APPS[@]}"; do
  D="$(dich "$app")"
  [ -z "$D" ] && { echo "skip $app: unknown app (use claude, codex, hermes)"; continue; }
  co_app "$app" || { echo "skip $app: not installed"; continue; }
  mkdir -p "$D"
  moi=0; giu=0; trung=0; daco=""
  while IFS= read -r f; do
    src="$GOC/$(dirname "$f")"; ten="$(basename "$src")"; dst="$D/$ten"
    case " $daco " in *" $ten "*) trung=$((trung+1)); continue ;; esac
    daco="$daco $ten"
    if [ -e "$dst" ] && ! grep -qs "$DAU" "$dst/.ddc-revidapi"; then
      giu=$((giu+1)); continue           # the user's own skill with this name: leave it alone
    fi
    rm -rf "$dst" && cp -R "$src" "$dst" && echo "$DAU" > "$dst/.ddc-revidapi"
    moi=$((moi+1))
  done <<< "$DS"
  echo "$app: $moi skills -> $D  (kept $giu existing, skipped $trung duplicate names)"
done

cat <<'EOF'

Next: give the Python examples your RevidAPI key (they use the OpenAI SDK).
  export OPENAI_BASE_URL=https://revidapi.com/v1
  export OPENAI_API_KEY=$REVIDAPI_API_KEY
Get a key at https://revidapi.com/dashboard . Restart the app so it sees the new skills.
EOF
