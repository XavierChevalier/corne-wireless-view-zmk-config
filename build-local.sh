#!/usr/bin/env bash
# Build ZMK firmware locally using the same Docker image as GitHub Actions.
# Usage: ./build-local.sh [left|right|all]
# Default: auto-detect which side(s) need rebuilding from config changes.
#
# Tip: The first run downloads Zephyr/ZMK and modules (~hundreds of MB).
# Subsequent runs reuse .west/, modules/, .ccache/, and .build/ for speed.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

IMAGE="zmkfirmware/zmk-build-arm:stable"
CONFIG_PATH="config"
OUTPUT_DIR="build-output"
BUILD_ROOT=".build"
WEST_HASH_FILE="${BUILD_ROOT}/west-manifest.hash"
CCACHE_DIR="${SCRIPT_DIR}/.ccache"

BOARD="nice_nano_v2"
SNIPPET="studio-rpc-usb-uart"
CCACHE_CMAKE="-DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache"

shield_for_side() {
  case "$1" in
    left)  echo "corne_left nice_view_adapter nice_view" ;;
    right) echo "corne_right nice_view_adapter nice_view" ;;
  esac
}

artifact_name_for_side() {
  case "$1" in
    left)  echo "corne_left-nice_nano_v2-zmk" ;;
    right) echo "corne_right-nice_nano_v2-zmk" ;;
  esac
}

file_mtime() {
  stat -f '%m' "$1" 2>/dev/null || stat -c '%Y' "$1"
}

west_manifest_hash() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "${CONFIG_PATH}/west.yml" | awk '{print $1}'
  else
    shasum -a 256 "${CONFIG_PATH}/west.yml" | awk '{print $1}'
  fi
}

config_latest_mtime() {
  local latest=0
  local mtime
  while IFS= read -r -d '' file; do
    mtime="$(file_mtime "$file")"
    if [ "$mtime" -gt "$latest" ]; then
      latest="$mtime"
    fi
  done < <(
    find "$CONFIG_PATH" -type f \( \
      -name '*.keymap' -o -name '*.conf' -o -name '*.h' -o \
      -name '*.dtsi' -o -name '*.json' \
    \) -print0 2>/dev/null
  )
  echo "$latest"
}

artifact_path_for_side() {
  local side="$1"
  local base="${OUTPUT_DIR}/$(artifact_name_for_side "$side")"
  if [ -f "${base}.uf2" ]; then
    echo "${base}.uf2"
  elif [ -f "${base}.bin" ]; then
    echo "${base}.bin"
  else
    return 1
  fi
}

side_needs_build() {
  local side="$1"
  local west_changed="$2"
  local config_ts="$3"

  if [ "$west_changed" = true ]; then
    return 0
  fi
  if [ ! -d "${BUILD_ROOT}/${side}" ]; then
    return 0
  fi
  if ! artifact_path_for_side "$side" >/dev/null 2>&1; then
    return 0
  fi
  local artifact
  artifact="$(artifact_path_for_side "$side")"
  local artifact_ts
  artifact_ts="$(file_mtime "$artifact")"
  [ "$config_ts" -gt "$artifact_ts" ]
}

detect_sides() {
  local mode="${1:-auto}"
  local -a sides=()

  case "$mode" in
    left|right)
      sides=("$mode")
      ;;
    all)
      sides=(left right)
      ;;
    auto|"")
      local west_changed=false
      local current_hash
      current_hash="$(west_manifest_hash)"
      mkdir -p "$BUILD_ROOT"
      if [ ! -f "$WEST_HASH_FILE" ] || [ "$(cat "$WEST_HASH_FILE")" != "$current_hash" ]; then
        west_changed=true
      fi

      local config_ts
      config_ts="$(config_latest_mtime)"

      for side in left right; do
        if side_needs_build "$side" "$west_changed" "$config_ts"; then
          sides+=("$side")
        fi
      done

      if [ "${#sides[@]}" -eq 0 ]; then
        return 1
      fi

      echo "Auto-detected side(s) to build: ${sides[*]}" >&2
      ;;
    *)
      echo "Usage: $0 [left|right|all]" >&2
      echo "  (no args) - auto-detect stale side(s) from config changes" >&2
      echo "  left      - build left half only" >&2
      echo "  right     - build right half only" >&2
      echo "  all       - build both halves" >&2
      exit 1
      ;;
  esac

  DETECTED_SIDES=("${sides[@]}")
  return 0
}

docker_run() {
  local script="$1"
  local -a tty_flags=()
  if [ -t 1 ]; then
    tty_flags=(-it)
  fi

  mkdir -p "$CCACHE_DIR"
  docker run --rm "${tty_flags[@]}" \
    -v "$SCRIPT_DIR:/workspace" \
    -v "$CCACHE_DIR:/ccache" \
    -e CCACHE_DIR=/ccache \
    -w /workspace \
    "$IMAGE" \
    bash -c "$script"
}

run_builds() {
  local -a sides=("$@")
  local sides_shell=""
  local side

  for side in "${sides[@]}"; do
    sides_shell+=" ${side}"
  done

  docker_run "
    set -euo pipefail
    cd /workspace
    mkdir -p .ccache \"${BUILD_ROOT}\" \"${OUTPUT_DIR}\"

    west_setup() {
      local current_hash
      current_hash=\$(sha256sum ${CONFIG_PATH}/west.yml | awk '{print \$1}')
      if [ ! -d .west ]; then
        echo 'First run: initializing west and fetching modules (this can take a while)...'
        west init -l ${CONFIG_PATH}
        west update --fetch-opt='--filter=tree:0'
        west zephyr-export
        echo \"\${current_hash}\" > ${WEST_HASH_FILE}
      elif [ ! -f ${WEST_HASH_FILE} ] || [ \"\$(cat ${WEST_HASH_FILE})\" != \"\${current_hash}\" ]; then
        echo 'West manifest changed, updating modules...'
        west update --fetch-opt='--filter=tree:0'
        west zephyr-export
        echo \"\${current_hash}\" > ${WEST_HASH_FILE}
      else
        echo 'West manifest unchanged, skipping west update.'
        if [ -f zephyr/zephyr-env.sh ]; then
          source zephyr/zephyr-env.sh
        else
          west zephyr-export
        fi
      fi
    }

    build_side() {
      local side=\"\$1\"
      local shield artifact build_dir
      case \"\${side}\" in
        left)
          shield='corne_left nice_view_adapter nice_view'
          artifact='corne_left-nice_nano_v2-zmk'
          ;;
        right)
          shield='corne_right nice_view_adapter nice_view'
          artifact='corne_right-nice_nano_v2-zmk'
          ;;
        *)
          echo \"Unknown side: \${side}\" >&2
          return 1
          ;;
      esac
      build_dir=${BUILD_ROOT}/\${side}

      echo '=============================================='
      echo \"Building: \${shield}\"
      echo '=============================================='

      if [ -f \"\${build_dir}/build.ninja\" ] || [ -f \"\${build_dir}/CMakeCache.txt\" ]; then
        echo \"Incremental build: \${side}\"
        west build -d \"\${build_dir}\"
      else
        echo \"Full build: \${side}\"
        west build -s zmk/app -d \"\${build_dir}\" -b ${BOARD} -S '${SNIPPET}' -- \\
          -DZMK_CONFIG=/workspace/${CONFIG_PATH} \\
          -DSHIELD=\"\${shield}\" \\
          ${CCACHE_CMAKE}
      fi

      if [ -f \"\${build_dir}/zephyr/zmk.uf2\" ]; then
        cp \"\${build_dir}/zephyr/zmk.uf2\" ${OUTPUT_DIR}/\${artifact}.uf2
        echo \"Built: ${OUTPUT_DIR}/\${artifact}.uf2\"
      elif [ -f \"\${build_dir}/zephyr/zmk.bin\" ]; then
        cp \"\${build_dir}/zephyr/zmk.bin\" ${OUTPUT_DIR}/\${artifact}.bin
        echo \"Built: ${OUTPUT_DIR}/\${artifact}.bin\"
      else
        echo \"Build failed: no firmware output for \${side}\" >&2
        return 1
      fi
    }

    west_setup

    if [ \"\$(echo${sides_shell} | wc -w | tr -d ' ')\" -gt 1 ]; then
      echo 'Building sides in parallel...'
      for side in${sides_shell}; do
        build_side \"\${side}\" &
      done
      failed=0
      for job in \$(jobs -p); do
        if ! wait \"\${job}\"; then
          failed=1
        fi
      done
      if [ \"\${failed}\" -ne 0 ]; then
        exit 1
      fi
    else
      for side in${sides_shell}; do
        build_side \"\${side}\"
      done
    fi
  "
}

mkdir -p "$OUTPUT_DIR" "$BUILD_ROOT"

DETECTED_SIDES=()
if ! detect_sides "${1:-auto}"; then
  echo "No changes detected; firmware is up to date."
  exit 0
fi

echo "Building side(s): ${DETECTED_SIDES[*]}"
run_builds "${DETECTED_SIDES[@]}"

echo ""
echo "Firmware written to: ${SCRIPT_DIR}/${OUTPUT_DIR}"
