#!/usr/bin/env bash
# Update DonoGenSoft.
#   bash update.sh           -> pull this repo, go to the versions pinned in it
#   bash update.sh --latest  -> also move kohya_ss (master) and Forge Neo (neo) to their newest commits
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/scripts/env.sh"
cd "$DGS_ROOT"

bash stop.sh >/dev/null || true
git pull --ff-only
git submodule sync --recursive
if [ "${1:-}" = "--latest" ]; then
  c_info "Moving kohya_ss and Forge Neo to their latest upstream commits"
  git submodule update --init --remote
  git submodule update --init --recursive kohya_ss
else
  git submodule update --init --recursive
fi
git submodule status
bash install.sh
