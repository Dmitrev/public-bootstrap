#!/usr/bin/env bash
set -euo pipefail

echo "===================================="
echo "[BOOTSTRAP] Stage 0 - SSH setup"
echo "===================================="

echo "[+] Installing base tools..."
sudo apt update
sudo apt install -y git openssh-client

mkdir -p ~/.ssh
chmod 700 ~/.ssh

echo "[+] Generating SSH key..."

if [ ! -f ~/.ssh/id_ed25519 ]; then
    default_label="$(whoami)@$(hostnamectl --static 2>/dev/null || hostname)"

    read -p "SSH key label [$default_label]: " label
    label="${label:-$default_label}"

    ssh-keygen -t ed25519 -C "$label" -f ~/.ssh/id_ed25519 -N ""
fi

echo "[+] Your public key:"
cat ~/.ssh/id_ed25519.pub

echo "Add this key to GitHub, then press ENTER"
read

echo "[+] Testing connection..."
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo "[+] GitHub SSH OK"
else
    echo "[!] GitHub SSH failed"

    echo ""
    echo "Fix steps:"
    echo "1. Copy your key:"
    echo "   cat ~/.ssh/id_ed25519.pub"
    echo "2. Add it to GitHub"
    echo "3. Re-run this script"
    exit 1
fi

echo "[+] Cloning private repo..."

if [ -d "$HOME/bootstrap" ]; then
    echo "[+] Repo already exists, skipping"
else
    git clone git@github.com:Dmitrev/bootstrap.git ~/bootstrap
fi
