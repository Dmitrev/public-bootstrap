#!/usr/bin/env bash
set -euo pipefail

echo "[+] Installing base tools..."
sudo apt update
sudo apt install -y git curl openssh-client

echo "[+] Generating SSH key..."
[ -f ~/.ssh/id_ed25519 ] || ssh-keygen -t ed25519 -C "bootstrap" -f ~/.ssh/id_ed25519 -N ""

echo "[+] Your public key:"
cat ~/.ssh/id_ed25519.pub

echo "Add this key to GitHub, then press ENTER"
read

echo "[+] Testing connection..."
ssh -T git@github.com || true

echo "[+] Cloning private repo..."
git clone git@github.com:Dmitrev/bootstrap.git ~/bootstrap
