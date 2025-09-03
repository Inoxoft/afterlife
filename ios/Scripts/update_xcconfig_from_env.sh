#!/bin/bash
set -euo pipefail

ENVIRONMENT="${1:-development}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IOS_ROOT="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$IOS_ROOT")"

TEMPLATE_FILE="$IOS_ROOT/Configs/Templates/Development.xcconfig"
OUTPUT_DIR="$IOS_ROOT/Configs/Generated"
OUTPUT_FILE="$OUTPUT_DIR/Development.local.xcconfig"

# Default env file path
ENV_FILE="$PROJECT_ROOT/.env.development"

echo "[update_xcconfig] ENVIRONMENT=$ENVIRONMENT"
echo "[update_xcconfig] TEMPLATE=$TEMPLATE_FILE"
echo "[update_xcconfig] OUTPUT=$OUTPUT_FILE"
echo "[update_xcconfig] ENV_FILE=$ENV_FILE"

mkdir -p "$OUTPUT_DIR"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "[update_xcconfig] Missing $ENV_FILE. Create it with HUGGINGFACE_API_KEY=..."
  exit 0
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

if [[ -z "${HUGGINGFACE_API_KEY:-}" ]]; then
  echo "[update_xcconfig] HUGGINGFACE_API_KEY not set in $ENV_FILE"
  exit 0
fi

cp "$TEMPLATE_FILE" "$OUTPUT_FILE"

# macOS-compatible in-place sed
sed -i '' "s/HUGGINGFACE_API_KEY_PLACEHOLDER/${HUGGINGFACE_API_KEY//\//\\/}/g" "$OUTPUT_FILE"

echo "[update_xcconfig] Wrote $OUTPUT_FILE"

