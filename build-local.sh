#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="/workspace"
CONFIG_PATH="config"
BUILD_YAML="build.yaml"
FALLBACK_BINARY="bin"

cd "$WORKSPACE"

# ── Parse build.yaml ────────────────────────────────────────────────
if [ ! -f "$BUILD_YAML" ]; then
    echo "ERROR: $BUILD_YAML not found in $WORKSPACE"
    exit 1
fi

# Extract include entries as JSON array
ENTRIES=$(yq -oj -I0 '.include' "$BUILD_YAML")

if [ -z "$ENTRIES" ] || [ "$ENTRIES" = "null" ]; then
    echo "ERROR: No build targets found in $BUILD_YAML"
    echo "See https://zmk.dev/docs/user-setup#add-a-keyboard"
    exit 1
fi

NUM_TARGETS=$(echo "$ENTRIES" | jq 'length')
echo "════════════════════════════════════════════════════"
echo " Found $NUM_TARGETS build target(s) in $BUILD_YAML"
echo "════════════════════════════════════════════════════"

# ── Detect if project is a ZMK module ───────────────────────────────
if [ -f "zephyr/module.yml" ]; then
    BASE_DIR="${TMPDIR:-/tmp}/zmk-config"
    mkdir -p "$BASE_DIR"
    # Copy config files to isolated temp directory
    mkdir -p "$BASE_DIR/$CONFIG_PATH"
    cp -R "$CONFIG_PATH"/* "$BASE_DIR/$CONFIG_PATH/"
    ZMK_IS_MODULE=1
    echo " Detected zephyr/module.yml → using isolated build dir: $BASE_DIR"
else
    BASE_DIR="$WORKSPACE"
    ZMK_IS_MODULE=0
fi

# ── West init + update (shared across targets) ──────────────────────
echo ""
echo ">>> west init"
(cd "$BASE_DIR" && west init -l "$BASE_DIR/$CONFIG_PATH")

echo ""
echo ">>> west update"
(cd "$BASE_DIR" && west update --fetch-opt=--filter=tree:0)

echo ""
echo ">>> west zephyr-export"
(cd "$BASE_DIR" && west zephyr-export)

# ── Build each target ───────────────────────────────────────────────
OUTPUT_DIR="$WORKSPACE/output"
mkdir -p "$OUTPUT_DIR"

for i in $(seq 0 $((NUM_TARGETS - 1))); do
    BOARD=$(echo "$ENTRIES" | jq -r ".[$i].board")
    SHIELD=$(echo "$ENTRIES" | jq -r ".[$i].shield // empty")
    SNIPPET=$(echo "$ENTRIES" | jq -r ".[$i].snippet // empty")
    CMAKE_ARGS=$(echo "$ENTRIES" | jq -r ".[$i].\"cmake-args\" // empty")
    ARTIFACT_NAME=$(echo "$ENTRIES" | jq -r ".[$i].\"artifact-name\" // empty")

    DISPLAY_NAME="${SHIELD:+$SHIELD - }${BOARD}"
    ARTIFACT_NAME="${ARTIFACT_NAME:-${SHIELD:+$SHIELD-}${BOARD//\//_}-zmk}"

    echo ""
    echo "════════════════════════════════════════════════════"
    echo " Building [$((i + 1))/$NUM_TARGETS]: $DISPLAY_NAME"
    echo "════════════════════════════════════════════════════"

    BUILD_DIR=$(mktemp -d)

    WEST_ARGS=()
    if [ -n "$SNIPPET" ]; then
        WEST_ARGS+=(-S "$SNIPPET")
    fi

    CMAKE_ARGS_ARRAY=(-DZMK_CONFIG="$BASE_DIR/$CONFIG_PATH")
    if [ -n "$SHIELD" ]; then
        CMAKE_ARGS_ARRAY+=(-DSHIELD="$SHIELD")
    fi
    if [ "${ZMK_IS_MODULE:-0}" -eq 1 ]; then
        CMAKE_ARGS_ARRAY+=(-DZMK_EXTRA_MODULES="${WORKSPACE}")
    fi
    if [ -n "$CMAKE_ARGS" ]; then
        # shellcheck disable=SC2206
        CMAKE_ARGS_ARRAY+=($CMAKE_ARGS)
    fi

    (cd "$BASE_DIR" && west build -s zmk/app -d "$BUILD_DIR" -b "$BOARD" \
        "${WEST_ARGS[@]}" -- "${CMAKE_ARGS_ARRAY[@]}")

    # ── Collect artifacts ───────────────────────────────────────
    if [ -f "$BUILD_DIR/zephyr/zmk.uf2" ]; then
        cp "$BUILD_DIR/zephyr/zmk.uf2" "$OUTPUT_DIR/${ARTIFACT_NAME}.uf2"
        echo " ✓ Produced: ${ARTIFACT_NAME}.uf2"
    elif [ -f "$BUILD_DIR/zephyr/zmk.${FALLBACK_BINARY}" ]; then
        cp "$BUILD_DIR/zephyr/zmk.${FALLBACK_BINARY}" "$OUTPUT_DIR/${ARTIFACT_NAME}.${FALLBACK_BINARY}"
        echo " ✓ Produced: ${ARTIFACT_NAME}.${FALLBACK_BINARY}"
    else
        echo " ⚠ No firmware artifact found for $DISPLAY_NAME"
    fi

    # Clean up build dir to save space
    rm -rf "$BUILD_DIR"
done

echo ""
echo "════════════════════════════════════════════════════"
echo " All builds complete!"
echo " Firmware files in: $OUTPUT_DIR/"
echo "════════════════════════════════════════════════════"
ls -lh "$OUTPUT_DIR/"
