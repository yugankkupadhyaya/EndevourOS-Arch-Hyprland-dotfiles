# EndeavourOS + Hyprland Dotfiles

Personal dotfiles and automated setup for an EndeavourOS Arch Linux system running Hyprland Wayland compositor.

## Overview

This repository provides a complete, reproducible desktop environment based on:

- **OS:** EndeavourOS (Arch Linux)
- **WM:** Hyprland (Wayland)
- **Shell:** Zsh with Oh My Posh
- **Terminal:** Ghostty
- **Bar:** Waybar
- **Notifications:** SwayNC
- **App Launcher:** Rofi
- **Session Lock:** Hyprlock
- **Logout:** Wlogout
- **Editor:** Neovim (LazyVim) & VS Code
- **Browser:** Brave & Zen Browser
- **File Manager:** Nemo & Dolphin

## Features

- Modular Hyprland configuration (monitors, programs, keybindings, etc.)
- Catppuccin Mocha color scheme across all components
- GTK3/4 theming with Breeze-Dark + WhiteSur icons
- Input method support (Fcitx5 with Bamboo for Vietnamese)
- Wallpaper daemon (awww) with dynamic wallpapers
- Clipboard manager (cliphist)
- Screenshot utility (hyprshot)
- Systemd service management

## Requirements

- EndeavourOS or Arch Linux (base installation)
- Internet connection
- `sudo` access
- ~15 GB free disk space for packages

## Quick Start

```bash
git clone https://github.com/yugankkupadhyaya/EndevourOS-Arch-Hyprland-dotfiles
cd EndevourOS-Arch-Hyprland-dotfiles
chmod +x install.sh
./install.sh
```

## What the Installer Does

1. Verifies the system is Arch/EndeavourOS and has internet access
2. Installs `yay` (AUR helper) if missing
3. Installs all pacman packages from `packages/pacman.txt`
4. Installs all AUR packages from `packages/aur.txt`
5. Backs up existing configs to `~/.dotfiles-backup-<timestamp>/`
6. Deploys all configuration files
7. Restores wallpapers
8. Enables systemd services
9. Sets Zsh as default shell
10. Rebuilds font caches

The installer is idempotent — safe to run multiple times.

## Package Management

| Manifest | Contents |
|---|---|
| `packages/pacman.txt` | Official Arch Linux packages |
| `packages/aur.txt` | AUR packages (installed via yay) |
| `packages/npm-global.txt` | Global npm packages |
| `packages/cargo.txt` | Rust/Cargo tools |
| `packages/go-tools.txt` | Go-installed tools |

To update manifests from a running system:

```bash
pacman -Qqen > packages/pacman.txt
pacman -Qqem > packages/aur.txt
```

## Configuration Layout

```
configs/
├── hypr/              # Hyprland WM (main + modular conf/)
├── waybar/            # Status bar
├── rofi/              # App launcher
├── wlogout/           # Logout/power menu
├── swaync/            # Notification center
├── ghostty/           # Terminal emulator
├── gtk3/              # GTK3 settings & CSS
├── gtk4/              # GTK4 settings & CSS
├── ohmyposh/          # Prompt theme
├── fcitx5/            # Input method
├── fontconfig/        # Font preferences
├── xsettingsd/        # X settings daemon
├── cava/              # Audio visualizer
├── nvim/              # Neovim configuration
├── viegphunt/         # Custom scripts (wallpaper, clipboard, etc.)
├── colors/            # Shared color scheme
├── nwg-look/          # GTK settings exporter
├── .zshrc             # Zsh configuration
├── .tmux.conf         # Tmux configuration
├── .gitconfig         # Git configuration
└── vscode-settings.json  # VS Code settings
```

## Manual Steps After Installation

1. **Log out and back in** — for shell change to take effect
2. **SDDM theme** — Select `sddm-astronaut-theme` in System Settings
3. **GTK theme** — Run `nwg-look` and apply Breeze-Dark / WhiteSur-dark
4. **Qt theme** — Run `qt5ct` / `qt6ct` to configure Kvantum
5. **Neovim plugins** — Open `nvim` to trigger Lazy plugin install
6. **Tmux plugins** — Launch `tmux` and press `prefix + I` (Ctrl-z then Shift+I)
7. **Hyprland bindings** — Press `Super + H` to view keybinding hints

## Troubleshooting

- **No network in installer:** Ensure `NetworkManager` is running: `sudo systemctl start NetworkManager`
- **Hyprland won't start:** Check logs: `journalctl -xe | grep hyprland`
- **Missing fonts:** Run `fc-cache -f` after installation
- **Waybar not showing:** Check modules in `~/.config/waybar/config`
- **Wallpaper not loading:** Run `awww init` or `awww next`
- **Screenshots not working:** Ensure `hyprshot` is installed and `$HOME/Pictures/Screenshots` exists

## Verification Checklist

- [ ] Hyprland loads without errors
- [ ] Waybar displays with all modules
- [ ] Rofi launches (Super + Space)
- [ ] Ghostty terminal opens (Super + T)
- [ ] Brave browser opens (Super + B)
- [ ] Nemo file manager opens (Super + E)
- [ ] Workspace switching works (Super + 1-0)
- [ ] Volume keys work (XF86Audio*)
- [ ] Brightness keys work (XF86MonBrightness*)
- [ ] Bluetooth manager opens via tray
- [ ] Network manager shows Wi-Fi status
- [ ] Fcitx5 input method works
- [ ] Clipboard history works (Super + V)
- [ ] Screenshots work (Super + Shift + S)
- [ ] Screen lock works (Super + L)
- [ ] Wlogout power menu works (click circle icon)
- [ ] Tmux config loads correctly
- [ ] Neovim plugins install without errors
