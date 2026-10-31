#!/usr/bin/env bash
# Repo Linker — right-click a folder in Files (Nautilus) to link a GitHub repo into it
# as a git submodule of your root repo, pick which GitHub account pushes to it,
# do a first-time push, or view the settings of a folder that's already linked.
# MIT License — Rootrecord Software Systems
set -u
CONF="${REPO_LINKER_CONFIG:-$HOME/.config/repo-linker/config}"
fail() { zenity --error --title="Repo Linker" --width=440 --text="$1"; exit 1; }
command -v zenity >/dev/null || { echo "Repo Linker needs zenity: sudo apt install zenity" >&2; exit 1; }
[ -f "$CONF" ] || fail "No config found.\nCopy config.example to $CONF and fill it in."
ROOT=""; ACCOUNTS=(); AFTER_LINK=""; LOCK_FILE=""
# shellcheck source=/dev/null
. "$CONF"
[ -d "$ROOT/.git" ] || [ -f "$ROOT/.git" ] || fail "ROOT in your config isn't a git repo:\n$ROOT"
[ "${#ACCOUNTS[@]}" -gt 0 ] || fail "Add at least one account to ACCOUNTS in your config."
ROOT="$(realpath "$ROOT")"
STATE="$HOME/.local/state/repo-linker"; mkdir -p "$STATE"; ERR="$STATE/last-error.log"; : > "$ERR"
LOCK="${LOCK_FILE:-$STATE/lock}"
RULES='*.wav\n*.mp3\n*.ogg\n*.opus\n*.flac\n*.m4a\n*.aac\n*.pem\n*.key\n*.env\n.env*\n*token*\nid_*\n__pycache__/\n'

acct_field() { printf '%s' "$1" | cut -d'|' -f"$2"; }

show_settings() {
  local D="$1" URL HOST SLUG ACC="HTTPS (no push account)" a BR LAST WHO CH
  URL="$(git -C "$D" remote get-url origin 2>/dev/null || echo none)"
  HOST="$(printf '%s' "$URL" | sed -nE 's#^git@([^:]+):.*#\1#p')"
  SLUG="$(printf '%s' "$URL" | sed -E 's#^(https?://github\.com/|git@[^:]+:)##; s#\.git$##')"
  for a in "${ACCOUNTS[@]}"; do [ "$(acct_field "$a" 2)" = "$HOST" ] && ACC="$(acct_field "$a" 1)"; done
  BR="$(git -C "$D" branch --show-current)"; LAST="$(git -C "$D" log -1 --format='%h %s (%cr)' 2>/dev/null)"
  WHO="$(git -C "$D" config user.name) &lt;$(git -C "$D" config user.email)&gt;"
  CH="$(git -C "$D" status --porcelain | wc -l)"
  A="$(zenity --info --title="Repo settings" --width=560 --ok-label="Close" --extra-button="Open on GitHub" \
    --text="<b>$(basename "$D")</b>\n\nRepo: $SLUG\nPush account: $ACC\nCommits as: $WHO\nBranch: $BR\nUncommitted changes: $CH\nLast commit: ${LAST:-none}")"
  [ "$A" = "Open on GitHub" ] && { xdg-open "https://github.com/$SLUG" >/dev/null 2>&1 & }
  exit 0
}

DIR="${1:-}"; [ -z "$DIR" ] && DIR="$(printf '%s' "${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS:-}" | head -n1)"
[ -z "$DIR" ] && DIR="$(pwd)"
DIR="$(realpath -m "$DIR")"
[ "$DIR" = "$ROOT" ] && show_settings "$DIR"
case "$DIR" in "$ROOT"/*) ;; *) fail "Pick a folder inside your root repo:\n$ROOT";; esac
[ -e "$DIR" ] && [ ! -d "$DIR" ] && fail "That's a file, not a folder."
[ -e "$DIR/.git" ] && show_settings "$DIR"
REL="${DIR#"$ROOT"/}"
FIRST=0; [ -d "$DIR" ] && [ -n "$(ls -A "$DIR")" ] && FIRST=1

URL="$(zenity --entry --title="Repo Linker" --width=520 --text="GitHub repo link for:\n$REL" --entry-text="https://github.com/")" || exit 0
SLUG="$(printf '%s' "$URL" | sed -E 's#^(https?://github\.com/|git@[^:]+:)##; s#/tree/.*$##; s#\.git$##; s#/+$##')"
printf '%s' "$SLUG" | grep -Eq '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$' || fail "That doesn't look like a GitHub repo link."

ROWS=(); first=TRUE
for a in "${ACCOUNTS[@]}"; do ROWS+=("$first" "$(acct_field "$a" 1)" "$(acct_field "$a" 2)"); first=FALSE; done
PICK="$(zenity --list --radiolist --title="Repo Linker" --width=440 --height=280 --text="Which account should push to $SLUG?" \
  --column="" --column="Account" --column="SSH host" "${ROWS[@]}")" || exit 0
for a in "${ACCOUNTS[@]}"; do [ "$(acct_field "$a" 1)" = "$PICK" ] && SEL="$a"; done
HOST="$(acct_field "$SEL" 2)"; NAME="$(acct_field "$SEL" 3)"; EMAIL="$(acct_field "$SEL" 4)"
SSHURL="git@$HOST:$SLUG.git"; WEB="https://github.com/$SLUG"

REFS="$(timeout 30 git ls-remote "$SSHURL" 2>>"$ERR")" || fail "Couldn't reach $SLUG as $PICK.\nCheck the link and that this account has access."
if [ "$FIRST" = 1 ]; then
  [ -n "$REFS" ] && fail "This folder has files and $SLUG already has commits.\nUse an empty folder, or an empty repo for a first push."
  NF="$(find "$DIR" -type f -not -path '*/.git/*' | wc -l)"; SZ="$(du -sh "$DIR" | cut -f1)"
  zenity --question --title="Repo Linker" --width=480 --ok-label="Push" \
    --text="$SLUG is empty.\n\nPush this folder as its first commit?\n$NF files, $SZ\n\nAudio, keys, .env and token files are skipped." || exit 0
fi

(
  set -e
  exec 9>"$LOCK"; flock 9
  ignore() { touch "$1/.gitignore"; printf "$RULES" | while read -r r; do grep -qxF "$r" "$1/.gitignore" || echo "$r" >> "$1/.gitignore"; done; }
  if [ "$FIRST" = 1 ]; then
    echo 30; echo "# First push…"
    git -C "$ROOT" ls-files --error-unmatch "$REL" >/dev/null 2>&1 && git -C "$ROOT" rm -r -q --cached "$REL"
    git -C "$DIR" init -q -b main
    git -C "$DIR" config user.name "$NAME"; git -C "$DIR" config user.email "$EMAIL"
    ignore "$DIR"; git -C "$DIR" remote add origin "$SSHURL"
    git -C "$DIR" add -A; git -C "$DIR" commit -qm "First push"; git -C "$DIR" push -q -u origin main
  else
    echo 30; echo "# Cloning…"
    rmdir "$DIR" 2>/dev/null || true
    git clone -q "$SSHURL" "$DIR"
    git -C "$DIR" config user.name "$NAME"; git -C "$DIR" config user.email "$EMAIL"
    if [ -z "$REFS" ]; then
      echo 50; echo "# Empty repo, adding a README…"
      git -C "$DIR" checkout -q -b main 2>/dev/null || true
      ignore "$DIR"; printf '# %s\n' "${SLUG#*/}" > "$DIR/README.md"
      git -C "$DIR" add -A; git -C "$DIR" commit -qm "Initial commit"; git -C "$DIR" push -q -u origin main
    fi
  fi
  echo 70; echo "# Linking into your root repo…"
  cd "$ROOT"
  git submodule add -q "$WEB.git" "$REL"
  git -C "$DIR" remote set-url origin "$SSHURL"
  git commit -qm "Link $SLUG at $REL"; git push -q
  echo 90; echo "# Finishing up…"
  [ -n "$AFTER_LINK" ] && REPO_DIR="$DIR" REPO_SLUG="$SLUG" bash -c "$AFTER_LINK" || true
  echo 100
) 2>>"$ERR" | zenity --progress --title="Repo Linker" --width=420 --auto-close --no-cancel --text="Starting…"

if git -C "$ROOT" config -f .gitmodules --get "submodule.$REL.url" >/dev/null 2>&1; then
  zenity --info --title="Repo Linker" --width=420 --text="Linked $SLUG into $REL as $PICK."
else
  fail "Linking didn't finish. Details are in:\n$ERR"
fi
