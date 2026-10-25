#!/usr/bin/env bash
# All-in-one: clone (if needed) + install (if needed) + start.
# Paste this in the "On-start script" of vast.ai / RunPod:
#   curl -fsSL https://raw.githubusercontent.com/ArthureCodage/DonoGenSoft/main/bootstrap.sh | bash
# Options (env vars): DGS_DIR (default /workspace/DonoGenSoft), DGS_TARGET (all|forge|kohya|lora)
set -euo pipefail

DGS_DIR="${DGS_DIR:-/workspace/DonoGenSoft}"
DGS_TARGET="${DGS_TARGET:-all}"
REPO="https://github.com/ArthureCodage/DonoGenSoft.git"

if ! command -v git >/dev/null; then
  apt-get update -y && apt-get install -y git
fi

mkdir -p "$(dirname "$DGS_DIR")"
if [ ! -d "$DGS_DIR/.git" ]; then
  git clone --recursive "$REPO" "$DGS_DIR"
fi
cd "$DGS_DIR"

need_install=0
case "$DGS_TARGET" in
  forge) [ -x forge-neo/venv/bin/python ] || need_install=1 ;;
  kohya) [ -d kohya_ss/.venv ] || need_install=1 ;;
  lora) [ -f data/lora-creator/config.json ] || need_install=1 ;;
  *) { [ -x forge-neo/venv/bin/python ] && [ -f data/lora-creator/config.json ]; } || need_install=1 ;;
esac

[ "$need_install" = 1 ] && bash install.sh "$DGS_TARGET"
bash start.sh "$DGS_TARGET"
