#!/bin/bash
set -euo pipefail
# Usage: bash scripts/render-rider-preview.sh croco|shiba /tmp/preview [--baseline]
# --baseline renders Rocco from HEAD for a pixel-level before/after comparison.
script_dir=$(cd "$(dirname "$0")" && pwd)
repo_dir=$(cd "$script_dir/.." && pwd)
rider_id=${1:-croco}
output_dir=${2:-/tmp/crococross-rider-preview}
baseline=${3:-}
if [[ "$rider_id" != croco && "$rider_id" != shiba ]]; then
  echo 'Supported riders: croco, shiba' >&2
  exit 2
fi
if [[ -n "$baseline" && ( "$baseline" != --baseline || "$rider_id" != croco ) ]]; then
  echo '--baseline supports Rocco only' >&2
  exit 2
fi
preview_build=$(mktemp -d /tmp/crococross-rider-renderer.XXXXXX)
preview_app="$preview_build/Preview.app/Contents"
mkdir -p "$preview_build/sources" "$preview_app/MacOS" "$preview_app/Resources" "$output_dir"
ln -s "$repo_dir/App/Resources/GameAssets" "$preview_app/Resources/GameAssets"
python3 - "$repo_dir" "$preview_build/sources" "$baseline" <<'PY'
import subprocess, sys
from pathlib import Path
root,out=map(Path,sys.argv[1:3])
paths = ['App/Scene/RoccoArtwork.swift','App/Scene/RoccoRig.swift']
if not sys.argv[3]: paths.append('App/Scene/DetachedLimbMotion.swift')
for relative in paths:
    source = subprocess.check_output(['git','show','HEAD:'+relative], cwd=root, text=True) if sys.argv[3] else (root/relative).read_text()
    (out/Path(relative).name).write_text(source.replace('import UIKit','import AppKit'))
PY
cp "$script_dir/rider-preview/Compatibility.swift" "$script_dir/rider-preview/NativePreview.swift" "$preview_build/sources/"
xcrun swiftc -emit-library -emit-module -module-name CrocoCrossCore \
    "$repo_dir/Sources/CrocoCrossCore/GameTypes.swift" "$repo_dir/Sources/CrocoCrossCore/PhysicsConfiguration.swift" \
    -module-cache-path "$preview_build/cache" -emit-module-path "$preview_build/sources/CrocoCrossCore.swiftmodule" \
    -o "$preview_app/MacOS/libCrocoCrossCore.dylib"
flags=(-D DEBUG)
if [[ -z "$baseline" ]]; then flags+=(-D RIG_DIAGNOSTICS); fi
xcrun swiftc "${flags[@]}" "$preview_build"/sources/*.swift -I "$preview_build/sources" -L "$preview_app/MacOS" \
    -lCrocoCrossCore -Xlinker -rpath -Xlinker @executable_path -module-cache-path "$preview_build/cache" \
    -o "$preview_app/MacOS/Preview"
"$preview_app/MacOS/Preview" "$rider_id" "$output_dir"
printf 'Native preview build: %s\n' "$preview_build"
