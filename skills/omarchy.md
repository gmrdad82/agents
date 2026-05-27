---
name: omarchy
description: Omarchy Linux config management — Hyprland, Waybar, Alacritty, neovim, system services.
triggers:
  [
    "omarchy.sh present",
    "~/.config/hypr/ + ~/.config/waybar/ present",
    "user mentions Omarchy / DHH / Hyprland setup",
  ]
---

# Omarchy

## Project context

Read `docs/EXTRA.md` first. It declares the user's Omarchy version,
the dotfiles backup location, the display setup (single / multi-
monitor, scaling), and any custom binds or services on top of the
base install. Anything declared there overrides the defaults below.

## Conventions

### Layout

- Omarchy ships configs under `~/.config/`. Persistent edits go
  there.
- Don't edit files installed by the Omarchy installer in place
  without copying them to your own dotfiles repo first — `omarchy
update` may overwrite them.
- Per-machine overrides: most Omarchy configs source a local file
  if present (e.g., `~/.config/hypr/conf.d/local.conf`). Use those
  rather than forking the main config.

### Hyprland

- Binds in `~/.config/hypr/binds.conf` (or per Omarchy's layout).
- Monitor config in `~/.config/hypr/monitors.conf`. Use
  `hyprctl monitors` to confirm the connected output names and
  modes before editing.
- Test config changes live with `hyprctl reload` — no logout
  needed.
- Animations / blur / shaders are pretty but expensive. If laptop
  battery matters, reduce blur passes and animation curves.

### Waybar

- `~/.config/waybar/config.jsonc` (modules) + `style.css` (CSS).
- Modules are tiny scripts or built-ins. For a custom module: a
  shell script that emits a JSON line per tick.
- Restart waybar via `pkill -SIGUSR2 waybar` (reloads in place).
  Crashes show in `journalctl --user -u waybar` if waybar runs as
  a user unit.

### Alacritty / terminal

- `~/.config/alacritty/alacritty.toml` (Alacritty switched from YAML
  to TOML in v0.13).
- Font: a Nerd Font is required for icon glyphs in starship /
  waybar — `JetBrainsMono Nerd Font` is the Omarchy default.
- Live config reload works for most options.

### Neovim

- Omarchy ships a LazyVim-based config. Personal overrides under
  `~/.config/nvim/lua/plugins/` and `lua/config/`.
- Run `:Lazy sync` after editing plugin specs. `:checkhealth` after
  install to catch missing deps.

### System services

- User-level systemd units under `~/.config/systemd/user/`. Enable
  with `systemctl --user enable --now <unit>`.
- For services that should start before Hyprland (e.g., display
  manager replacements), they're system-level under
  `/etc/systemd/system/` — edit with care.

### Package management

- Omarchy is Arch-based. `pacman -Syu` for system packages, `yay`
  / `paru` for AUR.
- Don't `pacman -Sy` (sync without upgrade) — partial upgrades
  break Arch.
- After kernel updates, reboot before reloading nvidia / dkms
  modules.

## Anti-patterns

- Don't run `omarchy update` while in the middle of an unrelated
  task — it pulls config defaults that may step on local changes.
- Don't edit `/etc/` files Omarchy manages without checking
  `omarchy.sh` first. The next update will revert them.
- Don't rebind Super+Q / Super+E / Super+Return without checking
  the muscle-memory cost — Omarchy ships them for a reason.
- Don't disable the system journal. Most Omarchy debugging
  (Hyprland crashes, waybar issues, audio glitches) starts with
  `journalctl`.

## Commands / verification

- `omarchy update` — pull latest Omarchy configs. Diff against
  local first if you have customizations: `git diff` in
  `~/.config/`.
- `hyprctl monitors` — connected outputs, modes, transforms.
- `hyprctl clients` — running windows + their workspaces / pids.
- `hyprctl reload` — re-read Hyprland config.
- `journalctl --user -u waybar -f` — tail waybar logs.
- `systemctl --user list-units --state=failed` — failed user
  services.
- `pacman -Qqe` — list explicitly installed packages (good for
  diffing against a fresh install or another machine).
- `paru -Qua` — outdated AUR packages.
