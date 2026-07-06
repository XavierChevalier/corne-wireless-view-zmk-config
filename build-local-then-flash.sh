#!/usr/bin/env bash
# Build ZMK firmware and flash each half when plugged in bootloader mode.
# Usage: ./build-local-then-flash.sh [--no-build] [--left-only] [--right-only]
#
# Workflow:
#   1. Build firmware (unless --no-build)
#   2. Put the LEFT half in bootloader mode (double-tap RESET) and plug in USB
#   3. Script flashes left firmware and waits for the device to reboot
#   4. Repeat for the RIGHT half
#
# The nice!nano UF2 bootloader mounts as a USB drive named "NICENANO".

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

OUTPUT_DIR="build-output"
POLL_INTERVAL=0.4
UF2_VOLUME_GLOBS=(/Volumes/NICENANO /Volumes/NICENANO*)

SKIP_BUILD=false
SIDES=(left right)

usage() {
  cat <<EOF
Usage: $0 [options]

Build firmware and flash each keyboard half in bootloader mode (left, then right).

Options:
  --no-build    Skip build; flash existing firmware from ${OUTPUT_DIR}/
  --left-only   Flash left half only
  --right-only  Flash right half only
  -h, --help    Show this help

Bootloader mode: double-tap the RESET button on the nice!nano, then plug in USB.
The controller appears as a drive named "NICENANO".
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --no-build)
      SKIP_BUILD=true
      ;;
    --left-only)
      SIDES=(left)
      ;;
    --right-only)
      SIDES=(right)
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

artifact_name_for_side() {
  case "$1" in
    left)  echo "corne_left-nice_nano_v2-zmk" ;;
    right) echo "corne_right-nice_nano_v2-zmk" ;;
  esac
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

side_label() {
  case "$1" in
    left)  echo "LEFT" ;;
    right) echo "RIGHT" ;;
  esac
}

find_bootloader_volume() {
  local vol pattern
  shopt -s nullglob
  for pattern in "${UF2_VOLUME_GLOBS[@]}"; do
    for vol in $pattern; do
      if [ -d "$vol" ] && [ -w "$vol" ]; then
        shopt -u nullglob
        echo "$vol"
        return 0
      fi
    done
  done
  shopt -u nullglob
  return 1
}

wait_for_bootloader_volume() {
  while true; do
    if find_bootloader_volume; then
      return 0
    fi
    sleep "$POLL_INTERVAL"
  done
}

wait_for_volume_gone() {
  local vol="$1"
  while [ -d "$vol" ]; do
    sleep "$POLL_INTERVAL"
  done
}

flash_uf2() {
  local uf2="$1"
  local vol="$2"

  echo "Copying $(basename "$uf2") to ${vol}..."
  cp "$uf2" "${vol}/"
  sync 2>/dev/null || true
  echo "File copied. The keyboard is rebooting (volume will unmount)..."
  wait_for_volume_gone "$vol"
  echo "Flash complete."
}

flash_side() {
  local side="$1"
  local uf2
  local vol

  uf2="$(artifact_path_for_side "$side")" || {
    echo "Firmware not found for ${side} half in ${OUTPUT_DIR}/" >&2
    exit 1
  }

  if [[ "$uf2" == *.bin ]]; then
    echo "Only .uf2 files are supported for automatic flashing (found: ${uf2})." >&2
    exit 1
  fi

  echo ""
  echo "=============================================="
  echo "$(side_label "$side") half"
  echo "=============================================="
  echo "1. Double-tap RESET to enter bootloader mode"
  echo "2. Plug in the $(side_label "$side") half via USB"
  echo ""
  echo "Waiting for bootloader volume (NICENANO)..."

  vol="$(wait_for_bootloader_volume)"
  echo "Volume detected: ${vol}"

  flash_uf2 "$uf2" "$vol"

  # Avoid instantly picking up a stale mount before the user switches halves.
  sleep 1
}

cleanup() {
  echo ""
  echo "Interrupted."
  exit 130
}

trap cleanup INT TERM

if [ "$SKIP_BUILD" = false ]; then
  echo "=== Build ==="
  if ! "${SCRIPT_DIR}/build-local.sh" all; then
    echo "Build failed." >&2
    exit 1
  fi
else
  echo "=== Build skipped (--no-build) ==="
fi

for side in "${SIDES[@]}"; do
  if ! artifact_path_for_side "$side" >/dev/null 2>&1; then
    echo "Missing firmware for ${side} half. Run without --no-build." >&2
    exit 1
  fi
done

echo ""
echo "=== Flash ==="
echo "Halves will be flashed in order: ${SIDES[*]}"

for side in "${SIDES[@]}"; do
  flash_side "$side"
done

echo ""
echo "Done. Firmware flashed for: ${SIDES[*]}"
