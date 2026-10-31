#!/usr/bin/env bash
# Installs Repo Linker into the Files (Nautilus) right-click Scripts menu.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
command -v zenity >/dev/null || { echo "Please install zenity first: sudo apt install zenity"; exit 1; }
mkdir -p "$HOME/.local/share/nautilus/scripts" "$HOME/.config/repo-linker"
chmod +x "$HERE/repo-linker.sh"
printf '#!/usr/bin/env bash\nexec "%s" "$@"\n' "$HERE/repo-linker.sh" > "$HOME/.local/share/nautilus/scripts/Repo Linker"
chmod +x "$HOME/.local/share/nautilus/scripts/Repo Linker"
[ -f "$HOME/.config/repo-linker/config" ] || cp "$HERE/config.example" "$HOME/.config/repo-linker/config"
echo "Installed. Edit ~/.config/repo-linker/config, then right-click a folder → Scripts → Repo Linker."
