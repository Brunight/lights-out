#!/usr/bin/env bash
# Install (or upgrade) the Screen Black KWin script, enable it, and link the
# `screen-black` CLI into ~/.local/bin.
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

if kpackagetool6 --type KWin/Script --show screenblack >/dev/null 2>&1; then
    kpackagetool6 --type KWin/Script --upgrade package
else
    kpackagetool6 --type KWin/Script --install package
fi
kwriteconfig6 --file kwinrc --group Plugins --key screenblackEnabled true
qdbus6 org.kde.KWin /KWin reconfigure

mkdir -p ~/.local/bin
ln -sfn "$PWD/screen-black" ~/.local/bin/screen-black
echo "Installed. If you upgraded while the script was running, log out and back"
echo "in: KWin caches QML files until it restarts."
