# 0xfraso's dotfiles

Managed with [chezmoi](https://chezmoi.io).

## Setup on a new machine (Linux or macOS)

```sh
chezmoi init --apply 0xfraso/.dotfiles
```

`init` clones the repo and prompts for per-machine values (monitor outputs),
then `apply` writes configs and runs the install bootstrap.

The original machine keeps its checkout at `~/.dotfiles` via a manual
`~/.config/chezmoi/chezmoi.toml` (`sourceDir = "~/.dotfiles"`); every other
machine uses chezmoi's default source dir (`~/.local/share/chezmoi`).

## Daily workflow

```sh
chezmoi cd            # shell in the source dir; edit files there
chezmoi apply         # source -> $HOME
chezmoi update        # git pull + apply
chezmoi status        # what would change
```

Commit/push with normal git inside the source dir.

## Machine-specific handling

- **`.chezmoiignore`** skips Linux-only configs on macOS (`i3`, `rofi`,
  `i3status`, `scripts/`).
- **`.chezmoi.toml.tmpl`** prompts for monitor output names on `init`; the i3
  config consumes them via `{{ .monitors.primary }}` / `{{ .monitors.secondary }}`.
- **`.zshrc`** is templated: `$DOTFILES` resolves to chezmoi's source dir per
  machine, `/home/...` paths use `$HOME`, and the Android SDK block is guarded.
- **`run_once_install-packages.sh.tmpl`** installs core tools (brew on macOS,
  pacman/apt on Linux); skips when already present.
