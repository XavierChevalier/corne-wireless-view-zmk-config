#!/usr/bin/env bash
# Build ZMK firmware locally using the same Docker image as GitHub Actions.
# Usage: ./build-local.sh [left|right|all]
# Default: all (builds both left and right)
#
# Tip: The first run downloads Zephyr/ZMK and modules (~hundreds of MB).
# Subsequent runs reuse .west/ and modules/ (only west update + build).

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

IMAGE="zmkfirmware/zmk-build-arm:stable"
CONFIG_PATH="config"
OUTPUT_DIR="build-output"
# Build dir must be inside repo so it's visible in the Docker mount
BUILD_ROOT=".build"

# Only run west init if not already initialized; then west update (fast when cached)
WEST_SETUP='
  if [ ! -d .west ]; then
    echo "First run: initializing west and fetching modules (this can take a while)..."
    west init -l '"$CONFIG_PATH"'
    west update --fetch-opt='"'"'--filter=tree:0'"'"'
  else
    echo "Reusing cached west workspace, updating..."
    west update --fetch-opt='"'"'--filter=tree:0'"'"'
  fi
  west zephyr-export
'

run_build() {
  local board="$1"
  local shield="$2"
  local snippet="$3"
  local artifact_name="$4"
  local build_suffix="$5"
  local build_dir="${BUILD_ROOT}/${build_suffix}"

  echo "=============================================="
  echo "Building: $shield"
  echo "=============================================="

  docker run --rm -it \
    -v "$SCRIPT_DIR:/workspace" \
    -w /workspace \
    "$IMAGE" \
    bash -c "
      set -e
      cd /workspace
      $WEST_SETUP
      west build -s zmk/app -d $build_dir -b $board ${snippet:+-S \"$snippet\"} -- \
        -DZMK_CONFIG=/workspace/$CONFIG_PATH \
        -DSHIELD='$shield'
      mkdir -p $OUTPUT_DIR
      if [ -f $build_dir/zephyr/zmk.uf2 ]; then
        cp $build_dir/zephyr/zmk.uf2 $OUTPUT_DIR/${artifact_name}.uf2
        echo \"Built: $OUTPUT_DIR/${artifact_name}.uf2\"
      elif [ -f $build_dir/zephyr/zmk.bin ]; then
        cp $build_dir/zephyr/zmk.bin $OUTPUT_DIR/${artifact_name}.bin
        echo \"Built: $OUTPUT_DIR/${artifact_name}.bin\"
      fi
    "
}

mkdir -p "$OUTPUT_DIR"

case "${1:-all}" in
  left)
    run_build "nice_nano_v2" "corne_left nice_view_adapter nice_view" "studio-rpc-usb-uart" "corne_left-nice_nano_v2-zmk" "left"
    ;;
  right)
    run_build "nice_nano_v2" "corne_right nice_view_adapter nice_view" "studio-rpc-usb-uart" "corne_right-nice_nano_v2-zmk" "right"
    ;;
  all)
    echo "Building both halves in one container..."
    docker run --rm -it \
      -v "$SCRIPT_DIR:/workspace" \
      -w /workspace \
      "$IMAGE" \
      bash -c "
        set -e
        cd /workspace
        $WEST_SETUP
        for side in left right; do
          [ \"\$side\" = left ] && shield='corne_left nice_view_adapter nice_view' || shield='corne_right nice_view_adapter nice_view'
          [ \"\$side\" = left ] && artifact='corne_left-nice_nano_v2-zmk' || artifact='corne_right-nice_nano_v2-zmk'
          echo '=============================================='
          echo \"Building: \$shield\"
          echo '=============================================='
          west build -s zmk/app -d $BUILD_ROOT/\$side -b nice_nano_v2 -S 'studio-rpc-usb-uart' -- \
            -DZMK_CONFIG=/workspace/$CONFIG_PATH \
            -DSHIELD=\"\$shield\"
          mkdir -p $OUTPUT_DIR
          cp $BUILD_ROOT/\$side/zephyr/zmk.uf2 $OUTPUT_DIR/\${artifact}.uf2 2>/dev/null || cp $BUILD_ROOT/\$side/zephyr/zmk.bin $OUTPUT_DIR/\${artifact}.bin
          echo \"Built: $OUTPUT_DIR/\${artifact}.*\"
        done
      "
    ;;
  *)
    echo "Usage: $0 [left|right|all]"
    echo "  left   - build left half only"
    echo "  right  - build right half only"
    echo "  all    - build both (default)"
    exit 1
    ;;
esac

echo ""
echo "Firmware written to: ${SCRIPT_DIR}/${OUTPUT_DIR}"
