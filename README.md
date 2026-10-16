# dotfiles

macOS dotfiles managed with GNU Stow. The `macos` branch starts from the
shared configuration on `main`.

The desktop uses AeroSpace, SketchyBar, JankyBorders, Raycast, Hammerspoon,
Karabiner-Elements, and kitty. SketchyBar and JankyBorders run as Homebrew
services. AeroSpace and Hammerspoon start themselves at login.

## New machine

Install Homebrew and clone this branch:

```sh
git clone --branch macos --single-branch \
  https://github.com/vetr0s/dotfiles ~/source/repos/dotfiles
cd ~/source/repos/dotfiles
./setup-macos --dry-run
./setup-macos --install
```

The dry run checks Stow conflicts. The install command runs `brew bundle` and
links each package. Stow refuses to replace an existing file. Move any reported
conflict aside and rerun the command.

Set Homebrew Bash as the login shell:

```sh
install-bash
```

Open a new terminal before continuing.

## Desktop activation

Grant Accessibility access to AeroSpace and Hammerspoon in System Settings.
Karabiner-Elements needs its requested Input Monitoring and driver permissions.
JankyBorders may request Accessibility access on first launch. Raycast only
needs extra permissions for features that use them.

Start the desktop after permissions are ready:

```sh
./setup-macos --start
```

This registers SketchyBar and JankyBorders with `brew services`, skipping any
service that is already started. launchd restarts them at login and after a
crash. AeroSpace repaints the bar's workspaces when it starts.

Set the Raycast hotkey to Option+Space in Raycast Settings, General. Disable or
change the Siri shortcut if it uses Option+Space. Raycast does not provide a
supported text preference for this setting.

The bar replaces the native menu bar, which `macos-desktop-settings apply`
hides. The native menu bar still appears at the top edge on hover. AeroSpace
reserves 40 pixels at the top for the bar. Without the hidden menu bar, that
gap sits below the native one. The bar uses IosevkaTerm Nerd Font. The Brewfile
already installs that font.

## Window workflow

The physical right diamond key on the HHKB is Hyper. Karabiner sends
Command+Control+Option while it is held. This preserves left Option as Meta in
kitty. Add Shift to any move binding.

| Key | Action |
| --- | --- |
| Hyper+h/j/k/l | Focus left, down, up, or right |
| Hyper+Shift+h/j/k/l | Move a window |
| Hyper+1 through Hyper+9 | Change workspace |
| Hyper+Shift+1 through Hyper+Shift+9 | Move a window to a workspace |
| Hyper+v, then h/j/k/l | Join the window with a neighbour into a new container |
| Hyper+e / Hyper+s | Cycle tile orientation or use accordion layout |
| Hyper+f / Hyper+Shift+f | AeroSpace or native macOS fullscreen |
| Hyper+Shift+Space | Toggle floating and tiling |
| Hyper+r | Enter resize mode. Use h/j/k/l and Escape to leave |
| Hyper+minus / Hyper+equal | Resize by 50 pixels |
| Hyper+0 | Balance window sizes |
| Hyper+period | Focus the next monitor |
| Hyper+Shift+period | Move the window to the next monitor |
| Hyper+Tab | Return to the previous workspace |
| Hyper+q | Close the focused window |
| Hyper+Shift+c | Reload the AeroSpace config |
| Hyper+; | Service mode. Escape reloads, r flattens, Backspace closes the others |
| Hyper+Enter | Show the floating kitty terminal |
| Hyper+c | Center a floating window through Hammerspoon |

Finder and the existing SDL sandbox float automatically. Browsers use
workspace 1. Terminals use 2. Editors use 3. Communications use 4. AI tools
use 5. Notes use 6. Virtual machines use 8. Games use 9.

SketchyBar shows workspaces and the focused application on the left. The window
title sits in the center. CPU, memory, network, battery, and time sit on the
right. Workspace and focus changes are event driven. A 30-second poll catches
windows that close on an unfocused workspace. CPU, memory, network, battery,
and clock poll every 10 to 120 seconds.

## macOS settings

Inspect the current values before changing them:

```sh
macos-desktop-settings status
```

Apply the optional user-level settings explicitly:

```sh
macos-desktop-settings apply
```

The first apply records each key's old value under
`~/.local/state/dotfiles/macos-desktop-settings.tsv`. Later applies only add
keys that are new to the list. The command makes these changes:

| Setting | Value |
| --- | --- |
| Dock auto-hide, delay, and hide speed | on, 0, 0.15s |
| Dock launch animation | off |
| Mission Control animation | 0.1s |
| Rearrange Spaces by recent use | off |
| Group windows by application | on. AeroSpace recommends it for Mission Control |
| Displays have separate Spaces | off. AeroSpace recommends it for multi-monitor stability |
| Key repeat and initial delay | 2 and 15 |
| Window open animation | off |
| Menu bar auto-hide | on |

It restarts the Dock and SystemUIServer. Log out afterwards. The menu bar and
Spaces settings only apply fully after a new login.

Reduce Motion is not in the script. macOS refuses writes to
`com.apple.universalaccess` from a terminal. Set it in System Settings,
Accessibility, Display.

No enabled macOS shortcut uses Command+Control+Option. Check Accessibility
shortcuts before enabling any, since a few default to that chord.

Restore every saved preference with:

```sh
macos-desktop-settings restore
```

The restore command keeps the consumed backup with a timestamp.

## Reload and validation

Use these commands after editing the desktop files:

```sh
aerospace reload-config --no-gui --dry-run --warnings-as-errors
sketchybar --reload
luac -p ~/.hammerspoon/init.lua
bash -n ~/.config/sketchybar/sketchybarrc
bash -n ~/.config/sketchybar/plugins/*.sh
bash -n ~/.config/borders/bordersrc
```

The AeroSpace validator needs the app server. SketchyBar has no static config
validator. Run `sketchybar` in the foreground when debugging its live config.

## Rollback

Restore macOS preferences first. Then remove only the desktop links:

```sh
macos-desktop-settings restore
brew services stop sketchybar
brew services stop borders
killall Hammerspoon
stow --delete --target="$HOME" aerospace borders hammerspoon sketchybar
```

Disable AeroSpace login startup before removing the app. Homebrew packages can
then be removed with `brew uninstall` or `brew uninstall --cask` if desired.

## Known limits

AeroSpace and SketchyBar must be running before their live integration can be
checked. Native macOS fullscreen creates a separate Space. AeroSpace fullscreen
is faster for normal tiling work. On a notched display, the centered window
title sits behind the notch.

Possible later refinements include per-monitor workspace assignment, app icons
in the bar, and laptop-specific battery thresholds. Add them only after the
current workflow shows a need.

Build Emacs.app with
[build-emacs-for-macos](https://github.com/jimeh/build-emacs-for-macos).
Then install Doom Emacs and start the launchd service:

```sh
git clone --recurse-submodules --depth 1 --shallow-submodules \
  https://github.com/doomemacs/core ~/.config/emacs
~/.config/emacs/bin/doom sync --env
~/.config/emacs/bin/doom doctor
make-emacsclient-app
emacsctl start
```

AeroSpace starts at login. Karabiner maps the right Command key to the
modifier used by AeroSpace. Kitty uses the left Option key as Meta.

## Editors and shell

Doom Emacs is the primary editor. Vim is the portable terminal fallback.
Neovim has its own config built on its built-in plugin manager. Bash uses
shared history, a small prompt, and a few aliases.

Java editing uses Eclipse JDT LS with Eglot. Install a JDK, then extract a
[JDT LS release](https://download.eclipse.org/justj/?file=jdtls%2Fmilestones)
into `~/.local/share/jdtls`. The executable must exist at
`~/.local/share/jdtls/bin/jdtls`.

Ghostel downloads its native module on first use. Blog publishing loads when
`~/source/blog/publish.el` exists.

## Tags

`tags [project]` creates vi and Emacs tag indexes for C, C++, Go, Python,
Odin, and Zig.

## Updating from main

Bring shared changes across by path. Review changes to `bash/`, `doom/`,
`kitty/`, `scripts/`, `tmux/`, and `vim/`. Copy only changes that apply to
macOS.
