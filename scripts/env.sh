#!/usr/bin/env bash
# Shared settings, sourced by every DonoGenSoft script.
# Everything lives inside the repo folder so it survives a pod restart
# (on RunPod / vast.ai only /workspace is kept).

DGS_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export DGS_ROOT

# Ports (override with: FORGE_PORT=8000 ./start.sh)
export FORGE_PORT="${FORGE_PORT:-7860}"
export KOHYA_PORT="${KOHYA_PORT:-7861}"
export LC_PORT="${LC_PORT:-7870}"

# Login for all web UIs (user is "dono", password generated once)
export DGS_USER="${DGS_USER:-dono}"

# Shared data folders
export DGS_DATA="$DGS_ROOT/data"
export DGS_LOGS="$DGS_ROOT/logs"

# uv: binary, Python builds and cache kept in the repo (persistent volume)
export UV_INSTALL_DIR="$DGS_ROOT/.uv/bin"
export UV_PYTHON_INSTALL_DIR="$DGS_ROOT/.uv/python"
export UV_CACHE_DIR="$DGS_ROOT/.uv/cache"
export UV_LINK_MODE=copy
export PATH="$UV_INSTALL_DIR:$PATH"

# Hugging Face downloads + accelerate config, also persistent
export HF_HOME="$DGS_DATA/hf-cache"

# Colors
c_ok() { printf '\033[1;32m%s\033[0m\n' "$*"; }
c_info() { printf '\033[1;36m==> %s\033[0m\n' "$*"; }
c_warn() { printf '\033[1;33m[!] %s\033[0m\n' "$*"; }
c_err() { printf '\033[1;31m[x] %s\033[0m\n' "$*" >&2; }

# Which tools to act on: "all" (default), "forge", "kohya" or "lora" (LoRA Creator)
dgs_targets() {
  case "${1:-all}" in
    all | "") echo "forge kohya lora" ;;
    forge | neo | sd) echo "forge" ;;
    kohya | ss) echo "kohya" ;;
    lora | lora-creator | lc) echo "lora" ;;
    *) c_err "Unknown target '$1' (use: all, forge, kohya, lora)"; exit 1 ;;
  esac
}

# LoRA Creator config: kohya_ss, LoRA output and model folders of this repo
export LORA_CREATOR_CONFIG="$DGS_DATA/lora-creator/config.json"
dgs_lora_creator_config() {
  mkdir -p "$DGS_DATA/lora-creator"
  cat >"$LORA_CREATOR_CONFIG" <<EOF
{
  "kohya_dir": "$DGS_ROOT/kohya_ss",
  "python": "$DGS_ROOT/kohya_ss/.venv/bin/python",
  "data_dir": "$DGS_DATA/lora-creator",
  "forge_lora_dir": "$DGS_DATA/loras",
  "model_dirs": [
    "$DGS_DATA/models/checkpoints",
    "$DGS_ROOT/forge-neo/models/Stable-diffusion"
  ],
  "host": "0.0.0.0",
  "port": $LC_PORT,
  "tagger_repo": "SmilingWolf/wd-swinv2-tagger-v3"
}
EOF
}

dgs_password() {
  local f="$DGS_DATA/password.txt"
  if [ -n "${DGS_PASSWORD:-}" ]; then
    echo "$DGS_PASSWORD"
    return
  fi
  if [ ! -s "$f" ]; then
    mkdir -p "$DGS_DATA"
    # finite input: avoids a SIGPIPE that would stop scripts using pipefail
    local p
    p="$(head -c 512 /dev/urandom | tr -dc 'A-Za-z0-9')"
    printf '%s' "${p:0:16}" >"$f"
    chmod 600 "$f"
  fi
  cat "$f"
}
