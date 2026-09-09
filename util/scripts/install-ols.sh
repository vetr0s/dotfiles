#!/usr/bin/env bash
# ols is the Odin language server and odinfmt is the formatter both editors
# call. Both are ordinary Odin programs in one checkout. The revision below is
# tested with this configuration and stays fixed until it is changed here.
set -euo pipefail

SRC_DIR="${OLS_SRC_DIR:-$HOME/source/third_party/ols}"
BIN_DIR="${OLS_BIN_DIR:-$HOME/.local/bin}"
OLS_REVISION="${OLS_REVISION:-110e63703db100e9cd5f381328bfde99fdb4b85f}"

if ! command -v odin >/dev/null 2>&1; then
  echo "odin is not on PATH. Install the compiler first." >&2
  exit 1
fi

if [ -d "$SRC_DIR/.git" ]; then
  if ! git -C "$SRC_DIR" cat-file -e "$OLS_REVISION^{commit}" 2>/dev/null; then
    git -C "$SRC_DIR" fetch origin "$OLS_REVISION"
  fi
else
  mkdir -p "$(dirname "$SRC_DIR")"
  git clone --filter=blob:none https://github.com/DanielGavin/ols "$SRC_DIR"
fi
git -C "$SRC_DIR" checkout --detach "$OLS_REVISION"

# Both scripts write their binary into the checkout root.
cd "$SRC_DIR"
./build.sh
./odinfmt.sh

# Symlinked rather than copied, so a later run of this script updates what is
# on PATH without touching BIN_DIR again.
mkdir -p "$BIN_DIR"
ln -sf "$SRC_DIR/ols" "$BIN_DIR/ols"
ln -sf "$SRC_DIR/odinfmt" "$BIN_DIR/odinfmt"

echo "ols and odinfmt linked into $BIN_DIR"
