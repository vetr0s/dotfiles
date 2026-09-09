#!/usr/bin/env bash
# ols is the Odin language server and odinfmt is the formatter both editors
# call. Neither is packaged anywhere, both are ordinary Odin programs living in
# one checkout, so the compiler is the only prerequisite. Re-running updates it.
set -e

SRC_DIR="${OLS_SRC_DIR:-$HOME/source/third_party/ols}"
BIN_DIR="${OLS_BIN_DIR:-$HOME/.local/bin}"

if ! command -v odin >/dev/null 2>&1; then
  echo "odin is not on PATH. Install the compiler first." >&2
  exit 1
fi

if [ -d "$SRC_DIR/.git" ]; then
  git -C "$SRC_DIR" pull --ff-only
else
  mkdir -p "$(dirname "$SRC_DIR")"
  git clone https://github.com/DanielGavin/ols "$SRC_DIR"
fi

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
