#!/usr/bin/env bash
set -euo pipefail

echo "===================================="
echo "[BOOTSTRAP] Stage 0 - SSH setup"
echo "===================================="

detect_pm() {
    if command -v apt >/dev/null 2>&1; then
        echo "apt"
    elif command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    else
        echo "unknown"
    fi
}

PM="$(detect_pm)"

if [[ "$PM" == "unknown" ]]; then
    echo "[!] Unsupported system (no apt or pacman found)"
    exit 1
fi

echo "[+] Detected package manager: $PM"

install_packages() {
    case "$PM" in
        apt)
            sudo apt update
            sudo apt install -y git openssh-client curl
            ;;
        pacman)
            sudo pacman -Sy --needed git openssh curl
            ;;
    esac
}

echo "[+] Installing base tools..."
install_packages

echo "[+] Installing Bitwarden..."

install_bitwarden() {
    case "$PM" in
        apt)
            curl -L -o /tmp/bitwarden.deb \
                "https://bitwarden.com/download/?app=desktop&platform=linux&variant=deb"
            sudo dpkg -i /tmp/bitwarden.deb || sudo apt -f install -y
            ;;
        pacman)
            if command -v yay >/dev/null 2>&1; then
                yay -S --needed bitwarden
            elif command -v paru >/dev/null 2>&1; then
                paru -S --needed bitwarden
            else
                echo "[!] No AUR helper found (yay/paru)."
                echo "    Install Bitwarden manually or install yay/paru."
            fi
            ;;
    esac
}

install_bitwarden || true

mkdir -p ~/.ssh
chmod 700 ~/.ssh

echo "[+] Generating SSH key..."

if [ ! -f ~/.ssh/id_ed25519 ]; then
    default_label="$(whoami)@$(hostname 2>/dev/null || echo "host")"

    read -rp "SSH key label [$default_label]: " label
    label="${label:-$default_label}"

    ssh-keygen -t ed25519 -C "$label" -f ~/.ssh/id_ed25519 -N ""
fi

echo "[+] Your public key:"
cat ~/.ssh/id_ed25519.pub

echo
echo "Add this key to GitHub, then press ENTER"
read -r

echo "[+] Testing connection..."
result=$(ssh -T git@github.com 2>&1 || true)

if [[ "$result" == *"successfully authenticated"* ]] || [[ "$result" == *"You've successfully authenticated"* ]]; then
    echo "[+] GitHub SSH OK"
else
    echo "[!] GitHub SSH failed"
    echo
    echo "Fix steps:"
    echo "1. Copy your key:"
    echo "   cat ~/.ssh/id_ed25519.pub"
    echo "2. Add it to GitHub"
    echo "3. Re-run this script"
    exit 1
fi

echo "[+] Cloning private repo..."

if [ -d "$HOME/dotfiles" ]; then
    echo "[+] Repo already exists, skipping"
else
    git clone git@github.com:Dmitrev/dotfiles.git "$HOME/dotfiles"
fi

echo "[+] Done"
