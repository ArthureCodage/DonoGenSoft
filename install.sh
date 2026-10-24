#!/usr/bin/env bash
# Install Forge Neo + kohya_ss on a fresh Linux GPU instance (vast.ai, RunPod...).
#   bash install.sh          -> both
#   bash install.sh forge    -> Stable Diffusion Forge Neo only
#   bash install.sh kohya    -> kohya_ss only
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/scripts/env.sh"
cd "$DGS_ROOT"
mkdir -p "$DGS_LOGS"
exec > >(tee -a "$DGS_LOGS/install.log") 2>&1

TARGETS="$(dgs_targets "${1:-all}")"
START=$(date +%s)

SUDO=""
if [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null; then SUDO="sudo"; fi

# ---------------------------------------------------------------- system
if command -v apt-get >/dev/null; then
  c_info "System packages"
  export DEBIAN_FRONTEND=noninteractive
  $SUDO apt-get update -y
  $SUDO apt-get install -y --no-install-recommends \
    git git-lfs curl ca-certificates build-essential ffmpeg \
    libgl1 libglib2.0-0 python3-tk psmisc
  # Nice to have, names differ between Ubuntu versions
  for p in aria2 tmux nano libtcmalloc-minimal4t64 libtcmalloc-minimal4; do
    $SUDO apt-get install -y --no-install-recommends "$p" >/dev/null 2>&1 || true
  done
else
  c_warn "apt-get not found: install git, ffmpeg, gcc, libgl1 yourself if something fails"
fi

# ---------------------------------------------------------------- uv
if ! command -v uv >/dev/null; then
  c_info "Installing uv (fast Python package manager)"
  curl -LsSf https://astral.sh/uv/install.sh | env INSTALLER_NO_MODIFY_PATH=1 sh
fi
uv --version

# ---------------------------------------------------------------- sources
c_info "Fetching kohya_ss + Forge Neo sources (git submodules)"
git submodule sync --recursive
git submodule update --init --recursive

mkdir -p "$DGS_DATA"/{models/checkpoints,loras,datasets,outputs,hf-cache}

# ---------------------------------------------------------------- GPU check
CUDA_DRV=""
if command -v nvidia-smi >/dev/null; then
  nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader || true
  CUDA_DRV="$(nvidia-smi | grep -oP 'CUDA (UMD )?Version:\s*\K[0-9]+\.[0-9]+' | head -1 || true)"
  c_info "Driver supports CUDA ${CUDA_DRV:-?}"
else
  c_warn "nvidia-smi not found: no NVIDIA GPU detected"
fi
cuda_ge() { [ -n "$CUDA_DRV" ] && awk -v a="$CUDA_DRV" -v b="$1" 'BEGIN{exit !(a+0 >= b+0)}'; }

# ---------------------------------------------------------------- kohya_ss
if [[ " $TARGETS " == *" kohya "* ]]; then
  c_info "Installing kohya_ss (Python 3.11, torch cu128)"
  if [ -n "$CUDA_DRV" ] && ! cuda_ge 12.8; then
    c_warn "kohya_ss needs a driver with CUDA >= 12.8 (this one: $CUDA_DRV). Pick another instance."
  fi
  (
    cd kohya_ss
    uv sync
    # Default accelerate config (the GUI passes its own precision settings)
    uv run --no-sync accelerate config default
  )
  c_ok "kohya_ss installed"
fi

# ---------------------------------------------------------------- Forge Neo
if [[ " $TARGETS " == *" forge "* ]]; then
  c_info "Installing Stable Diffusion Forge Neo (Python 3.13)"
  # Forge Neo wants torch cu130 (driver CUDA >= 13.0). Fall back on older drivers.
  if [ -n "$CUDA_DRV" ] && ! cuda_ge 13.0; then
    if cuda_ge 12.8; then
      export TORCH_COMMAND="pip install torch==2.10.0+cu128 torchvision==0.25.0+cu128 --extra-index-url https://download.pytorch.org/whl/cu128"
    else
      export TORCH_COMMAND="pip install torch==2.10.0+cu126 torchvision==0.25.0+cu126 --extra-index-url https://download.pytorch.org/whl/cu126"
    fi
    c_warn "Older driver: using $TORCH_COMMAND"
    echo "export TORCH_COMMAND=\"$TORCH_COMMAND\"" >"$DGS_DATA/forge-torch.sh"
  else
    rm -f "$DGS_DATA/forge-torch.sh"
  fi
  (
    cd forge-neo
    [ -x venv/bin/python ] || uv venv venv --python 3.13 --seed
    # First run installs torch + requirements, then exits
    bash webui.sh --uv --exit
  )
  c_ok "Forge Neo installed"
fi

dgs_password >/dev/null
c_ok "Done in $(( ($(date +%s) - START) / 60 )) min. Start with:  bash start.sh"
