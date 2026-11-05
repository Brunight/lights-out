#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Brunight <brunorodriguesricardo@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
# Build dist/lights-out-VERSION.kwinscript, the archive to upload to the KDE
# Store. Users install it from System Settings > KWin Scripts > Get New, or
# with `kpackagetool6 --type KWin/Script --install FILE`.
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

version=$(python3 -c 'import json; print(json.load(open("package/metadata.json"))["KPlugin"]["Version"])')
out="dist/lights-out-$version.kwinscript"
mkdir -p dist
rm -f "$out"
python3 -I - "$out" <<'PY'
import sys, zipfile
from pathlib import Path
with zipfile.ZipFile(sys.argv[1], "w", zipfile.ZIP_DEFLATED) as z:
    for f in sorted(Path("package").rglob("*")):
        if f.is_file():
            z.write(f, f.relative_to("package"))
    z.write("LICENSE", "LICENSE")
PY
echo "$out"
