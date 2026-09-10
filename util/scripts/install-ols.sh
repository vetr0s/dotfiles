#!/usr/bin/env bash
# ols is the Odin language server and odinfmt is the formatter both editors
# call. Both are ordinary Odin programs in one checkout. The revision below is
# tested with this configuration and stays fixed until it is changed here.
set -euo pipefail

SRC_DIR="${OLS_SRC_DIR:-$HOME/source/third_party/ols}"
BIN_DIR="${OLS_BIN_DIR:-$HOME/.local/bin}"
OLS_REVISION="${OLS_REVISION:-110e63703db100e9cd5f381328bfde99fdb4b85f}"
OLS_ODIN_VERSION="${OLS_ODIN_VERSION:-dev-2026-09:a2fb372b7}"

if [[ ! "$OLS_REVISION" =~ ^[0-9a-f]{40}$ ]]; then
  echo "OLS_REVISION must be a 40-character lowercase Git revision." >&2
  exit 1
fi

if [[ ! "$OLS_ODIN_VERSION" =~ ^[A-Za-z0-9._:+-]+$ ]]; then
  echo "OLS_ODIN_VERSION contains an unsafe release path character." >&2
  exit 1
fi

compiler_key="${OLS_ODIN_VERSION//:/_}"
release_key="$OLS_REVISION-$compiler_key"
release_root="$BIN_DIR/ols-revisions"
release_dir="$release_root/$release_key"

activate_release() {
  ln -sfn "$release_dir" "$BIN_DIR/.ols-current"
  ln -sfn "$BIN_DIR/.ols-current/ols" "$BIN_DIR/ols"
  ln -sfn "$BIN_DIR/.ols-current/odinfmt" "$BIN_DIR/odinfmt"
}

mkdir -p "$release_root"
if [ -d "$release_dir" ]; then
  if [ ! -x "$release_dir/ols" ] || [ ! -x "$release_dir/odinfmt" ] \
    || [ ! -f "$release_dir/BUILD-PINS" ]; then
    echo "Existing OLS release is incomplete: $release_dir" >&2
    exit 1
  fi

  IFS=$'\t' read -r release_revision release_odin_version \
    < "$release_dir/BUILD-PINS"
  if [ "$release_revision" != "$OLS_REVISION" ] \
    || [ "$release_odin_version" != "$OLS_ODIN_VERSION" ]; then
    echo "Existing OLS release has different build pins: $release_dir" >&2
    exit 1
  fi

  activate_release
  echo "ols and odinfmt linked into $BIN_DIR"
  exit 0
fi

if ! command -v odin >/dev/null 2>&1; then
  echo "odin is not on PATH. Install the compiler first." >&2
  exit 1
fi

odin_version="$(odin version 2>&1)"
case "$odin_version" in
  *" version $OLS_ODIN_VERSION") ;;
  *)
    echo "ols is tested with Odin $OLS_ODIN_VERSION." >&2
    echo "Found: $odin_version" >&2
    echo "Set OLS_ODIN_VERSION to test another compiler." >&2
    exit 1
    ;;
esac

if [ -d "$SRC_DIR/.git" ]; then
  if ! git -C "$SRC_DIR" cat-file -e "$OLS_REVISION^{commit}" 2>/dev/null; then
    git -C "$SRC_DIR" fetch origin "$OLS_REVISION"
  fi
else
  mkdir -p "$(dirname "$SRC_DIR")"
  git clone --filter=blob:none https://github.com/DanielGavin/ols "$SRC_DIR"
fi

build_parent="$(mktemp -d "$(dirname "$SRC_DIR")/.ols-build.XXXXXX")"
build_root="$build_parent/source"
release_stage=""
cleanup() {
  git -C "$SRC_DIR" worktree remove --force "$build_root" >/dev/null 2>&1 || true
  [ -z "$build_parent" ] || rm -rf "$build_parent"
  [ -z "$release_stage" ] || rm -rf "$release_stage"
}
trap cleanup EXIT

git -C "$SRC_DIR" worktree add --detach "$build_root" "$OLS_REVISION"
cd "$build_root"
./build.sh
./odinfmt.sh

release_stage="$(mktemp -d "$release_root/.${release_key}.XXXXXX")"
cp "$build_root/ols" "$build_root/odinfmt" "$release_stage/"
chmod 0755 "$release_stage/ols" "$release_stage/odinfmt"
printf '%s\t%s\n' "$OLS_REVISION" "$OLS_ODIN_VERSION" \
  > "$release_stage/BUILD-PINS"
mv "$release_stage" "$release_dir"
release_stage=""

activate_release

git -C "$SRC_DIR" worktree remove --force "$build_root"
rm -rf "$build_parent"
build_parent=""
trap - EXIT

echo "ols and odinfmt linked into $BIN_DIR"
