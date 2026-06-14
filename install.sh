#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────
#  EndevourOS / Arch Linux — Hyprland Dotfiles Installer
#  Source: https://github.com/yugankkupadhyaya/EndevourOS-Arch-Hyprland-dotfiles
# ─────────────────────────────────────────────────────────────────────

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="/tmp/dotfiles-install-$(date +%Y%m%d-%H%M%S).log"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()   { echo -e "${GREEN}[✓]${NC} $*" | tee -a "$LOG_FILE"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*" | tee -a "$LOG_FILE"; }
error() { echo -e "${RED}[✗]${NC} $*" | tee -a "$LOG_FILE"; }
info()  { echo -e "${CYAN}[ℹ]${NC} $*" | tee -a "$LOG_FILE"; }

trap 'error "Installation failed at line $LINENO. See log: $LOG_FILE"' ERR

# ─────────────────────────────────────────────────────────────────────
#  Pre-flight checks
# ─────────────────────────────────────────────────────────────────────
preflight() {
    info "Running pre-flight checks..."

    if [ ! -f /etc/arch-release ] && [ ! -f /etc/endeavouros-release ]; then
        error "This installer is for Arch Linux / EndeavourOS only."
        exit 1
    fi

    if ! command -v pacman &>/dev/null; then
        error "pacman not found. Are you on Arch Linux?"
        exit 1
    fi

    if ! ping -c 1 -W 2 archlinux.org &>/dev/null; then
        error "No internet connection. Aborting."
        exit 1
    fi

    if [ "$(id -u)" -eq 0 ]; then
        error "Do not run this script as root."
        exit 1
    fi
}

# ─────────────────────────────────────────────────────────────────────
#  Install AUR helper (yay)
# ─────────────────────────────────────────────────────────────────────
install_aur_helper() {
    if command -v yay &>/dev/null; then
        log "yay already installed"
        return
    fi
    info "Installing yay (AUR helper)..."
    sudo pacman -S --needed --noconfirm base-devel git
    local tmpdir
    tmpdir="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
    (cd "$tmpdir/yay" && makepkg -si --noconfirm)
    rm -rf "$tmpdir/yay"
    log "yay installed"
}

# ─────────────────────────────────────────────────────────────────────
#  Install pacman packages
# ─────────────────────────────────────────────────────────────────────
install_pacman() {
    local pkg_file="$REPO_DIR/packages/pacman.txt"
    if [ ! -f "$pkg_file" ]; then
        warn "packages/pacman.txt not found — skipping"
        return
    fi
    info "Installing pacman packages (this may take a while)..."
    local pkgs
    pkgs=$(grep -vE '^\s*(#|$)' "$pkg_file" | tr '\n' ' ')
    if [ -z "$pkgs" ]; then
        warn "No packages listed in pacman.txt"
        return
    fi
    sudo pacman -S --needed --noconfirm $pkgs 2>&1 | tee -a "$LOG_FILE"
    log "Pacman packages installed"
}

# ─────────────────────────────────────────────────────────────────────
#  Install AUR packages
# ─────────────────────────────────────────────────────────────────────
install_aur() {
    local pkg_file="$REPO_DIR/packages/aur.txt"
    if [ ! -f "$pkg_file" ]; then
        warn "packages/aur.txt not found — skipping"
        return
    fi
    info "Installing AUR packages..."
    local pkgs
    pkgs=$(grep -vE '^\s*(#|$)' "$pkg_file" | tr '\n' ' ')
    if [ -z "$pkgs" ]; then
        warn "No packages listed in aur.txt"
        return
    fi
    yay -S --needed --noconfirm $pkgs 2>&1 | tee -a "$LOG_FILE"
    log "AUR packages installed"
}

# ─────────────────────────────────────────────────────────────────────
#  Deploy configs using stow (or manual symlinks)
# ─────────────────────────────────────────────────────────────────────
deploy_configs() {
    local config_src="$REPO_DIR/configs"

    if [ ! -d "$config_src" ]; then
        warn "configs/ directory not found — skipping config deployment"
        return
    fi

    info "Backing up existing configs to $BACKUP_DIR..."
    mkdir -p "$BACKUP_DIR"

    # Backup existing config files before overwriting
    for dir in hypr waybar rofi wlogout swaync ghostty gtk3 gtk4 ohmyposh \
               fcitx5 fontconfig xsettingsd cava nvim viegphunt colors nwg-look; do
        if [ -d "$HOME/.config/$dir" ]; then
            cp -r "$HOME/.config/$dir" "$BACKUP_DIR/" 2>/dev/null || true
        fi
    done
    for f in .zshrc .bashrc .bash_profile .gitconfig .tmux.conf .screenrc; do
        if [ -f "$HOME/$f" ]; then
            cp "$HOME/$f" "$BACKUP_DIR/" 2>/dev/null || true
        fi
    done

    info "Deploying config files..."

    # Hyprland
    if [ -d "$config_src/hypr" ]; then
        mkdir -p "$HOME/.config/hypr"
        cp -r "$config_src/hypr/"* "$HOME/.config/hypr/"
        log "Hyprland configs deployed"
    fi

    # Waybar
    if [ -d "$config_src/waybar" ]; then
        mkdir -p "$HOME/.config/waybar"
        cp -r "$config_src/waybar/"* "$HOME/.config/waybar/"
        chmod +x "$HOME/.config/waybar/scripts/"*.sh 2>/dev/null || true
        log "Waybar configs deployed"
    fi

    # Rofi
    if [ -d "$config_src/rofi" ]; then
        mkdir -p "$HOME/.config/rofi"
        cp -r "$config_src/rofi/"* "$HOME/.config/rofi/"
        log "Rofi configs deployed"
    fi

    # Wlogout
    if [ -d "$config_src/wlogout" ]; then
        mkdir -p "$HOME/.config/wlogout"
        cp -r "$config_src/wlogout/"* "$HOME/.config/wlogout/"
        log "Wlogout configs deployed"
    fi

    # SwayNC
    if [ -d "$config_src/swaync" ]; then
        mkdir -p "$HOME/.config/swaync"
        cp -r "$config_src/swaync/"* "$HOME/.config/swaync/"
        log "SwayNC configs deployed"
    fi

    # Ghostty
    if [ -d "$config_src/ghostty" ]; then
        mkdir -p "$HOME/.config/ghostty"
        cp -r "$config_src/ghostty/"* "$HOME/.config/ghostty/"
        log "Ghostty configs deployed"
    fi

    # GTK3
    if [ -d "$config_src/gtk3" ]; then
        mkdir -p "$HOME/.config/gtk-3.0"
        cp -r "$config_src/gtk3/"* "$HOME/.config/gtk-3.0/"
        log "GTK3 configs deployed"
    fi

    # GTK4
    if [ -d "$config_src/gtk4" ]; then
        mkdir -p "$HOME/.config/gtk-4.0"
        cp -r "$config_src/gtk4/"* "$HOME/.config/gtk-4.0/"
        log "GTK4 configs deployed"
    fi

    # Oh My Posh
    if [ -d "$config_src/ohmyposh" ]; then
        mkdir -p "$HOME/.config/ohmyposh"
        cp -r "$config_src/ohmyposh/"* "$HOME/.config/ohmyposh/"
        log "Oh My Posh configs deployed"
    fi

    # Fcitx5
    if [ -d "$config_src/fcitx5" ]; then
        mkdir -p "$HOME/.config/fcitx5"
        cp -r "$config_src/fcitx5/"* "$HOME/.config/fcitx5/"
        log "Fcitx5 configs deployed"
    fi

    # Fontconfig
    if [ -d "$config_src/fontconfig" ]; then
        mkdir -p "$HOME/.config/fontconfig"
        cp -r "$config_src/fontconfig/"* "$HOME/.config/fontconfig/"
        log "Fontconfig deployed"
    fi

    # Xsettingsd
    if [ -d "$config_src/xsettingsd" ]; then
        mkdir -p "$HOME/.config/xsettingsd"
        cp -r "$config_src/xsettingsd/"* "$HOME/.config/xsettingsd/"
        log "Xsettingsd configs deployed"
    fi

    # Cava
    if [ -d "$config_src/cava" ]; then
        mkdir -p "$HOME/.config/cava"
        cp -r "$config_src/cava/"* "$HOME/.config/cava/"
        log "Cava configs deployed"
    fi

    # NVim
    if [ -d "$config_src/nvim" ]; then
        mkdir -p "$HOME/.config/nvim"
        cp -r "$config_src/nvim/"* "$HOME/.config/nvim/"
        log "Neovim configs deployed"
    fi

    # Viegphunt scripts
    if [ -d "$config_src/viegphunt" ]; then
        mkdir -p "$HOME/.config/viegphunt"
        cp -r "$config_src/viegphunt/"* "$HOME/.config/viegphunt/"
        chmod +x "$HOME/.config/viegphunt/"*.sh 2>/dev/null || true
        log "Viegphunt scripts deployed"
    fi

    # Colors
    if [ -d "$config_src/colors" ]; then
        mkdir -p "$HOME/.config/colors"
        cp -r "$config_src/colors/"* "$HOME/.config/colors/"
        log "Colors configs deployed"
    fi

    # Nwg-look
    if [ -d "$config_src/nwg-look" ]; then
        mkdir -p "$HOME/.config/nwg-look"
        cp -r "$config_src/nwg-look/"* "$HOME/.config/nwg-look/"
        log "Nwg-look config deployed"
    fi

    # Root dotfiles
    for f in .zshrc .bashrc .bash_profile .gitconfig .tmux.conf .screenrc; do
        if [ -f "$config_src/$f" ]; then
            cp "$config_src/$f" "$HOME/$f"
            log "Deployed $f"
        fi
    done

    # GTK2
    if [ -f "$config_src/gtk3/.gtkrc-2.0" ]; then
        cp "$config_src/gtk3/.gtkrc-2.0" "$HOME/.gtkrc-2.0"
        log "Deployed .gtkrc-2.0"
    fi
}

# ─────────────────────────────────────────────────────────────────────
#  Restore wallpapers
# ─────────────────────────────────────────────────────────────────────
deploy_wallpapers() {
    if [ -d "$REPO_DIR/wallpapers" ] && ls "$REPO_DIR/wallpapers/"*.{jpg,png,jpeg} &>/dev/null 2>&1; then
        mkdir -p "$HOME/Pictures/Wallpapers"
        cp -r "$REPO_DIR/wallpapers/"* "$HOME/Pictures/Wallpapers/"
        log "Wallpapers restored"
    else
        warn "No wallpapers found in repo — skipping"
    fi
}

# ─────────────────────────────────────────────────────────────────────
#  Enable systemd services
# ─────────────────────────────────────────────────────────────────────
enable_services() {
    info "Enabling system services..."
    local services=(
        NetworkManager
        bluetooth
        firewalld
        systemd-timesyncd
        sddm
        avahi-daemon
        power-profiles-daemon
    )
    for svc in "${services[@]}"; do
        if systemctl is-enabled "$svc" &>/dev/null 2>&1; then
            log "$svc already enabled"
        else
            sudo systemctl enable "$svc" 2>&1 | tee -a "$LOG_FILE" || warn "Failed to enable $svc"
        fi
    done

    info "Enabling user services..."
    local user_services=(
        wireplumber
    )
    for svc in "${user_services[@]}"; do
        if systemctl --user is-enabled "$svc" &>/dev/null 2>&1; then
            log "User $svc already enabled"
        else
            systemctl --user enable "$svc" 2>&1 | tee -a "$LOG_FILE" || warn "Failed to enable user $svc"
        fi
    done
}

# ─────────────────────────────────────────────────────────────────────
#  Set Zsh as default shell
# ─────────────────────────────────────────────────────────────────────
set_shell() {
    if [ "$SHELL" != "/usr/bin/zsh" ]; then
        if command -v zsh &>/dev/null; then
            info "Setting Zsh as default shell..."
            chsh -s "$(command -v zsh)" 2>&1 | tee -a "$LOG_FILE"
            log "Default shell set to Zsh (log out and back in to take effect)"
        else
            warn "Zsh not installed — skipping shell change"
        fi
    else
        log "Zsh is already the default shell"
    fi
}

# ─────────────────────────────────────────────────────────────────────
#  Install npm global packages
# ─────────────────────────────────────────────────────────────────────
install_npm_global() {
    local pkg_file="$REPO_DIR/packages/npm-global.txt"
    if [ ! -f "$pkg_file" ]; then
        return
    fi
    local pkgs
    pkgs=$(grep -vE '^\s*(#|$)' "$pkg_file" | tr '\n' ' ')
    if [ -n "$pkgs" ]; then
        info "Installing global npm packages..."
        npm install -g $pkgs 2>&1 | tee -a "$LOG_FILE" || warn "Some npm packages failed to install"
        log "Global npm packages installed"
    fi
}

# ─────────────────────────────────────────────────────────────────────
#  Rebuild font caches
# ─────────────────────────────────────────────────────────────────────
rebuild_caches() {
    info "Rebuilding font cache..."
    fc-cache -f 2>&1 | tee -a "$LOG_FILE" || true
    info "Updating user dirs..."
    xdg-user-dirs-update 2>/dev/null || true
    info "Updating pkgfile database..."
    sudo pkgfile -u 2>/dev/null || true
}

# ─────────────────────────────────────────────────────────────────────
#  Post-install summary
# ─────────────────────────────────────────────────────────────────────
summary() {
    echo ""
    echo "────────────────────────────────────────────────────────────"
    echo -e "${GREEN}  Installation complete!${NC}"
    echo "────────────────────────────────────────────────────────────"
    echo ""
    echo "  Backup:       $BACKUP_DIR"
    echo "  Log:          $LOG_FILE"
    echo ""
    echo "  ${YELLOW}Manual steps still required:${NC}"
    echo "  1. Log out and back in for shell change to take effect"
    echo "  2. SDDM theme: ensure sddm-astronaut-theme is selected"
    echo "     in System Settings → SDDM"
    echo "  3. Configure GTK theme via nwg-look if needed"
    echo "  4. Configure Qt theme via qt5ct / qt6ct if needed"
    echo "  5. Open Neovim to trigger Lazy plugin install"
    echo "  6. Install tmux plugins with: tmux + I"
    echo "  7. Review $BACKUP_DIR for any lost customizations"
    echo ""
    echo "  ${CYAN}To restore from backup:${NC}"
    echo "  cp -r $BACKUP_DIR/* ~/.config/"
    echo ""
}

# ─────────────────────────────────────────────────────────────────────
#  Main
# ─────────────────────────────────────────────────────────────────────
main() {
    echo ""
    echo "  EndevourOS / Arch Linux — Hyprland Dotfiles Installer"
    echo "══════════════════════════════════════════════════════════"
    echo ""

    preflight
    install_aur_helper
    install_pacman
    install_aur
    deploy_configs
    deploy_wallpapers
    enable_services
    set_shell
    install_npm_global
    rebuild_caches
    summary
}

main "$@"
