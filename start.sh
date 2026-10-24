#!/usr/bin/env bash
# Start the web UIs in the background (logs in logs/).
#   bash start.sh            -> both
#   bash start.sh forge      -> Forge Neo only  (port 7860)
#   bash start.sh kohya      -> kohya_ss only   (port 7861)
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/scripts/env.sh"
cd "$DGS_ROOT"
mkdir -p "$DGS_LOGS"

TARGETS="$(dgs_targets "${1:-all}")"
PASS="$(dgs_password)"

if ! command -v uv >/dev/null; then
  c_err "uv not found: run 'bash install.sh' first"
  exit 1
fi

running() { [ -f "$DGS_LOGS/$1.pid" ] && kill -0 "$(cat "$DGS_LOGS/$1.pid")" 2>/dev/null; }

if [[ " $TARGETS " == *" forge "* ]]; then
  if running forge; then
    c_warn "Forge Neo already running"
  elif [ ! -x forge-neo/venv/bin/python ]; then
    c_err "Forge Neo is not installed: bash install.sh forge"
  else
    [ -f "$DGS_DATA/forge-torch.sh" ] && source "$DGS_DATA/forge-torch.sh"
    (
      cd forge-neo
      nohup setsid bash webui.sh --uv --listen --port "$FORGE_PORT" \
        --gradio-auth "$DGS_USER:$PASS" --enable-insecure-extension-access \
        --ckpt-dirs "$DGS_DATA/models/checkpoints" --lora-dirs "$DGS_DATA/loras" \
        ${FORGE_ARGS:-} >"$DGS_LOGS/forge.log" 2>&1 &
      echo $! >"$DGS_LOGS/forge.pid"
    )
    c_ok "Forge Neo starting on port $FORGE_PORT  (log: logs/forge.log)"
  fi
fi

if [[ " $TARGETS " == *" kohya "* ]]; then
  if running kohya; then
    c_warn "kohya_ss already running"
  elif [ ! -d kohya_ss/.venv ]; then
    c_err "kohya_ss is not installed: bash install.sh kohya"
  else
    (
      cd kohya_ss
      nohup setsid uv run --no-sync kohya_gui.py --noverify --headless \
        --listen 0.0.0.0 --server_port "$KOHYA_PORT" \
        --username "$DGS_USER" --password "$PASS" \
        ${KOHYA_ARGS:-} >"$DGS_LOGS/kohya.log" 2>&1 &
      echo $! >"$DGS_LOGS/kohya.pid"
    )
    c_ok "kohya_ss starting on port $KOHYA_PORT  (log: logs/kohya.log)"
  fi
fi

echo
echo "  Login:     $DGS_USER / $PASS"
echo "  Forge Neo: http://<instance-ip>:$FORGE_PORT"
echo "  kohya_ss:  http://<instance-ip>:$KOHYA_PORT"
echo "  Or through SSH from your PC:"
echo "    ssh -p <ssh-port> root@<ip> -L $FORGE_PORT:localhost:$FORGE_PORT -L $KOHYA_PORT:localhost:$KOHYA_PORT"
echo "    then open http://localhost:$FORGE_PORT and http://localhost:$KOHYA_PORT"
echo
echo "  Follow logs: tail -f logs/forge.log logs/kohya.log      Stop: bash stop.sh"
