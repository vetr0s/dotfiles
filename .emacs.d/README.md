# .emacs.d

Emacs configuration built on [minimal-emacs.d](https://github.com/jamescherti/minimal-emacs.d)
(v1.5.1), using the built-in `package.el`. No third-party package manager and
no `use-package`.

## Layout

`early-init.el` and `init.el` are upstream's, copied verbatim. **Do not edit
them**; replace them wholesale when updating minimal-emacs.d. Everything else
is mine, hooked into the points upstream provides.

The repository directory holds configuration only. `pre-early-init.el` moves
`user-emacs-directory` to `$XDG_DATA_HOME/emacs/`, or `~/.local/share/emacs/`
when that variable is unset. Packages, history, bookmarks, grammars, recovery
files, and session data live there. Native compilation output lives under
`$XDG_CACHE_HOME/emacs/`, or `~/.cache/emacs/` when that variable is unset.

| File | Role |
|------|------|
| `pre-early-init.el` | Separates runtime state, sets `load-path`, and reports startup time |
| `pre-init.el` | The package manifest, read before `package-initialize` |
| `package-lock.el` | Exact package versions and source revisions |
| `post-init.el` | Installs and verifies packages, then loads the modules |
| `configs/rc-*.el` | The actual configuration, one file per concern |

Modules are ordinary Elisp with `provide`/`require`. `rc-defaults` comes first
because it repairs `PATH`, which everything shelling out depends on.

| Module | Covers |
|--------|--------|
| `rc-defaults` | `PATH`, recentf, savehist, saveplace, auto-revert, Dired, auto-save |
| `rc-ui` | Font, theme, line numbers, mode line, scrolling, `winner-mode` |
| `rc-completion` | Vertico, Orderless, Marginalia, Consult, Embark, Corfu, Cape |
| `rc-evil` | Evil, evil-collection, evil-mc, evil-surround, undo-fu, move-text |
| `rc-editing` | Outline folding, stripspace, apheleia, YASnippet, spelling |
| `rc-elisp` | paredit, aggressive-indent, highlight-defined, helpful |
| `rc-programming` | Tags, Python (tree-sitter, local environments, Flymake), Markdown |
| `rc-cc` | C and C++: tree-sitter modes, clang-format indentation, CMake |
| `rc-zig` | Zig: build command |
| `rc-odin` | Odin: `odin-ts-mode` written here, odinfmt |
| `rc-org` | Org, agenda, pdf-tools |
| `rc-git` | Magit |
| `rc-terminal` | ghostel and its Evil integration |

## Packages

`pre-init.el` declares the package manifest. `package-lock.el` records the
exact installed version and upstream commit for its full dependency closure.
Startup stops before loading the modules when an installed package differs
from that lock.

Packages come from GNU ELPA, NonGNU ELPA, MELPA, and MELPA Stable. Nothing is
pulled directly from a repository. `package.el` installs missing packages.
The lock prevents a changed archive build from being accepted silently.

Org is deliberately **not** in the manifest: Emacs ships a current one, and a
second copy from ELPA races the built-in for load order.

Update packages from a running Emacs. Write the new lock before restarting:

```
M-x package-upgrade-all
M-x rc-package-write-lock
```

Review `package-lock.el` with the configuration change that needs the update.

## Odin

`odin-mode` was a regex mode that never matched procedure calls or field
access, which left most of a buffer unfontified, so `configs/rc-odin.el`
replaces it with a tree-sitter mode written here. It covers font lock,
indentation, imenu and the compilation error format `odin build` emits.

The grammar is not vendored. On a new machine:

```
M-x rc-odin-install-grammar
```

That compiles a pinned revision of
[tree-sitter-odin](https://github.com/tree-sitter-grammars/tree-sitter-odin)
into `$XDG_DATA_HOME/emacs/tree-sitter/`. The fallback is
`~/.local/share/emacs/tree-sitter/`.

Formatting on save is apheleia running `odinfmt -stdin`. It reads a project's
`odinfmt.json` if there is one, so both editors produce the same result. The
default is tabs at width four, which is what `odin-ts-mode` indents to.
`odinfmt` is not packaged, so it is built from source. See the root README. A
machine without it saves Odin files unformatted.

`C-c b` builds. A `Makefile` at the project root wins, since it already carries
the flags and the `-out:` path a bare `odin build` would have to invent.
Otherwise the command is `odin build` on the package, which is `src/` when the
project has one and the root when it does not.

| Key | Does |
|-----|------|
| `C-c C-r` | `odin run` |
| `C-c C-k` | `odin check`, no binary produced |
| `C-c C-t` | `odin test` |

Errors jump. `odin` reports them as `path(line:column) Error:`, which no entry
in the default `compilation-error-regexp-alist` matches, so `rc-odin` adds one.

## Zig

`zig-mode` supplies syntax and indentation. Apheleia runs `zig fmt` on save.

`C-c b` runs `zig build` from the nearest parent containing `build.zig`.

## Python

`python-ts-mode` comes in through `major-mode-remap-alist`, but only where the
grammar is present, so a fresh clone falls back to `python-mode` rather than
erroring. python.el registers its own commit-pinned grammar source, so that
part is not repeated here. On a new machine:

```
M-x rc-programming-install-python-grammar
```

The Python workflow expects [uv](https://github.com/astral-sh/uv) and
[ruff](https://github.com/astral-sh/ruff) on `PATH`.

uv puts its environment at `.venv` in the project root and exports nothing.
Opening a Python file adds that environment to the buffer-local `exec-path` and
`process-environment`. Open projects cannot replace each other's tools.

Linting is Flymake over `ruff check`. It falls back to `flake8` when a project
environment provides it. Both print `stdin:line:col: CODE message`, which is
the pattern Emacs expects. Only a file that will not run is an error. Import
ordering and complexity are notes. Everything else is a warning.

Formatting is apheleia running `ruff-isort` then `ruff format`, which is the
pair that replaces isort and black. apheleia's own default for Python is black,
which a uv setup does not install, so it is overridden.

## C and C++

The target is a CMake project that exports a compilation database. On a new
machine, once:

```
M-x rc-cc-install-grammars
```

That builds the C, C++, Doxygen and CMake grammars into
`$XDG_DATA_HOME/emacs/tree-sitter/`. The fallback is
`~/.local/share/emacs/tree-sitter/`. Then, once per project:

```
M-x rc-cc-cmake-configure
```

That runs `cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON`. `compile`
is set to `cmake --build <root>/build` in a CMake project, so `C-c b` builds
the same tree.

`c-ts-mode` and `c++-ts-mode` come in through `major-mode-remap-alist`, but
only where both grammars are present, so a fresh clone stays in cc-mode, with
font lock and indentation, until the install command has run.

### Formatting and indentation

Formatting on save is apheleia running `clang-format`, and it **does** pick up
a project's own `.clang-format`: apheleia passes `-assume-filename` with the
buffer's real path, so clang-format walks up from the file the way it would on
the command line. A project file beats `~/.clang-format`.

That leaves a gap, which `rc-cc-follow-clang-format` closes. Emacs indents
while you type from its own settings, so in a project whose `.clang-format`
says two columns you would type at four and watch every save move the line.
Opening a C or C++ buffer asks `clang-format --dump-config` what actually
applies to that file and sets `c-ts-indent-offset`, `c-basic-offset` and
`indent-tabs-mode` from the answer. Asking clang-format rather than parsing the
YAML is what resolves `BasedOnStyle` and nested directories correctly. Each
request reads the current configuration. C and C++ files can resolve different
language sections in the same directory.

`BreakBeforeBraces` maps onto a `c-ts-mode` indent style as well, so an Allman
project types Allman.

Indentation then comes from two places, because no one source is good at both
jobs:

| | Per line, as you type | Over a region (`indent-region`, `=` in Evil) |
|---|---|---|
| Source | tree-sitter | clang-format |
| Why | Survives the half-written buffer typing produces | Exact by construction |

clang-format is exact but useless mid-edit: with braces still unbalanced it has
nothing to balance and guesses badly. tree-sitter has error recovery and is
what should answer a keystroke. Over a region the buffer is usually whole, and
there clang-format wins outright.

Two details make the clang-format side safe. It has no indent-only mode and
would otherwise rewrap to `ColumnLimit`, changing how many lines come back and
putting every column after the first rewrap on the wrong line; the resolved
style is dumped to a temp file with the limit lifted, so line breaks stay put
and indentation is the only thing that moves. And the leading whitespace is
copied verbatim rather than re-derived from a column, so tabs land exactly
where clang-format puts them.

Two `c-ts-mode` gaps are patched for the typing path, both reproducible under
`emacs -Q`:

- **Macro bodies.** tree-sitter-c parses the whole body of a multi-line macro
  as one opaque `preproc_arg` token, so `c-ts-mode` gives up with `no-indent`.
  The syntax table still works: `parse-partial-sexp` counts unclosed braces
  between the directive and the line, skipping strings and comments.
- **Nested directives.** `c-ts-mode` sends a top-level form under a directive
  to column 0 with a rule that reaches only one level deep. A header with an
  include guard around an `#ifdef` nests two.

Measured against `clang-format` over 55 files of C in these projects, 51
re-indent to exactly what clang-format produces. Running `indent-region` over
already-formatted code changes nothing at all, which is the property that
matters most: `=` never churns a file.

C++ is where the split earns itself. Under Allman braces `c-ts-mode` cascades
the indent of a brace opening a namespace or class, and closing that with
tree-sitter rules needs a special case per declaration form. The region path
sidesteps all of it.

### Keys

There is no language server. Completion is Corfu over the Cape backends
`rc-completion` adds, navigation is [tags](#tags), and errors come from
`compile`.

| Key | Does |
|-----|------|
| `M-.` / `M-,` | Definition, and back |
| `M-?` | References |
| `C-c b` | Build, through `compile` |
| `C-c o` | Switch between source and header, through `ff-find-other-file` |

No debugger is wired in. `lldb` runs in a terminal.

## Tags

`M-.` is the etags backend, not a server. `util/scripts/tags.sh` writes the
index; `rc-programming` points `tags-table-list` at the nearest `.tags` when a
buffer opens, so nothing has to be visited by hand. The index is a file, so it
is as current as the last run of the script.

The vi-format `tags` beside it is Neovim's half of the same index. macOS
filesystems are case-insensitive, which is why the Emacs one is not `TAGS`.

## Emacs and the daemon

The configuration is shared. Each host owns the Emacs binary and daemon. See
the [macOS instructions](../macos/README.md) or
[Linux instructions](../linux/README.md). The root
[Emacs daemon section](../README.md#emacs-daemon) describes client behavior.

Because the daemon has no frame at startup, the font and theme are applied
from `server-after-make-frame-hook` rather than at load time, and
`exec-path-from-shell` runs an interactive login shell so that `PATH` picks up
everything `config.bash` exports. Interactive matters: `~/.bashrc` returns
immediately in a non-interactive shell, and it is the file that sources
`config.bash`, so `-l` on its own would come back with none of it.
