#!/usr/bin/env bash
# One tag index per project, in the two formats the editors read: `tags' is the
# vi format Neovim's <C-]> finds on its own, and `.tags' is the etags format
# Emacs `M-.' wants. Same definitions either way, so both jump to the same
# place. Emacs would conventionally call its file TAGS, but macOS filesystems
# are case-insensitive and that is the same name as the vi one.
#
# universal-ctags ships no Odin or Zig parser, so both are defined below. The
# rest are its own.
set -e

ROOT="${1:-.}"

if ! command -v ctags >/dev/null 2>&1 || ! ctags --version 2>/dev/null | grep -q Universal; then
  echo "universal-ctags is not on PATH. brew install universal-ctags" >&2
  exit 1
fi

# A declaration in Odin is `name :: <kind>', so the kinds are told apart by
# what follows the ::. {exclusive} stops a matched line reaching the catch-all
# constant rule underneath, which would otherwise tag every struct twice.
#
# Anchored at column 0, since only a top-level declaration is worth a tag and
# `x := 1' inside a procedure is indented.
LANGDEFS=(
  --langdef=Odin
  --map-Odin=.odin
  '--regex-Odin=/^([A-Za-z_][A-Za-z0-9_]*)[ \t]*::[ \t]*proc/\1/p,procedure/{exclusive}'
  '--regex-Odin=/^([A-Za-z_][A-Za-z0-9_]*)[ \t]*::[ \t]*struct/\1/s,struct/{exclusive}'
  '--regex-Odin=/^([A-Za-z_][A-Za-z0-9_]*)[ \t]*::[ \t]*enum/\1/g,enum/{exclusive}'
  '--regex-Odin=/^([A-Za-z_][A-Za-z0-9_]*)[ \t]*::[ \t]*union/\1/u,union/{exclusive}'
  '--regex-Odin=/^([A-Za-z_][A-Za-z0-9_]*)[ \t]*::[ \t]*bit_set/\1/b,bitset/{exclusive}'
  '--regex-Odin=/^package[ \t]+([A-Za-z_][A-Za-z0-9_]*)/\1/n,package/{exclusive}'
  '--regex-Odin=/^([A-Za-z_][A-Za-z0-9_]*)[ \t]*:[:=][ \t]*[^ \t]/\1/c,constant/'

  # Zig methods sit inside a struct, so `fn' is the one rule that may be
  # indented. The type rules come first for the same reason as Odin's.
  --langdef=Zig
  --map-Zig=.zig
  '--regex-Zig=/^[ \t]*(pub[ \t]+)?(export[ \t]+|inline[ \t]+)?fn[ \t]+([A-Za-z_][A-Za-z0-9_]*)/\3/f,function/{exclusive}'
  '--regex-Zig=/^(pub[ \t]+)?const[ \t]+([A-Za-z_][A-Za-z0-9_]*)[ \t]*=[ \t]*(extern[ \t]+|packed[ \t]+)?struct/\2/s,struct/{exclusive}'
  '--regex-Zig=/^(pub[ \t]+)?const[ \t]+([A-Za-z_][A-Za-z0-9_]*)[ \t]*=[ \t]*(extern[ \t]+|packed[ \t]+)?enum/\2/g,enum/{exclusive}'
  '--regex-Zig=/^(pub[ \t]+)?const[ \t]+([A-Za-z_][A-Za-z0-9_]*)[ \t]*=[ \t]*(extern[ \t]+|packed[ \t]+)?union/\2/u,union/{exclusive}'
  '--regex-Zig=/^(pub[ \t]+)?const[ \t]+([A-Za-z_][A-Za-z0-9_]*)/\2/c,constant/'
)

# --languages restricts the walk to what is actually written here, so a
# vendored web asset does not end up in the index.
COMMON=(
  -R
  --languages=C,C++,Go,Python,Odin,Zig
  --exclude=.git
  --exclude=build
  --exclude=.venv
  --exclude=node_modules
  --exclude=third_party
  --exclude=tags
  --exclude=.tags
)

cd "$ROOT"
tags_temp="$(mktemp .tags.vi.XXXXXX)"
etags_temp="$(mktemp .tags.emacs.XXXXXX)"
trap 'rm -f "$tags_temp" "$etags_temp"' EXIT

ctags --options=NONE "${LANGDEFS[@]}" "${COMMON[@]}" -f "$tags_temp" .
ctags --options=NONE "${LANGDEFS[@]}" "${COMMON[@]}" -e -f "$etags_temp" .
mv "$tags_temp" tags
mv "$etags_temp" .tags
trap - EXIT

echo "wrote $(pwd)/tags and $(pwd)/.tags"
