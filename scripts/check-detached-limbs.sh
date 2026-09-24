#!/bin/bash
set -euo pipefail
script_dir=$(cd "$(dirname "$0")" && pwd)
repo_dir=$(cd "$script_dir/.." && pwd)
output_dir=${1:-"$repo_dir/artifacts/qa/flexible-fall-2026-09-23"}
limb_build=$(mktemp -d /tmp/crococross-detached-limbs.XXXXXX)
trap 'rm -rf "$limb_build"' EXIT
mkdir -p "$output_dir"
xcrun swiftc -swift-version 6 -emit-library -emit-module -module-name CrocoCrossCore \
    "$repo_dir/Sources/CrocoCrossCore/GameTypes.swift" "$repo_dir/Sources/CrocoCrossCore/PhysicsConfiguration.swift" \
    -module-cache-path "$limb_build/cache" -emit-module-path "$limb_build/CrocoCrossCore.swiftmodule" \
    -o "$limb_build/libCrocoCrossCore.dylib"
xcrun swiftc -swift-version 6 "$repo_dir/App/Scene/DetachedLimbMotion.swift" "$script_dir/check-detached-limbs.swift" \
    -I "$limb_build" -L "$limb_build" -lCrocoCrossCore -Xlinker -rpath -Xlinker @executable_path \
    -module-cache-path "$limb_build/cache" -o "$limb_build/check-detached-limbs"
"$limb_build/check-detached-limbs" "$output_dir/detached-limbs-model.json"
