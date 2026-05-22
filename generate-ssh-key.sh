#!/usr/bin/env bash
set -e

SSH_DIR="$(dirname "$0")/.ssh"
KEY="$SSH_DIR/id_ed25519"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

if [ -f "$KEY" ]; then
  echo "SSH-Key existiert bereits: $KEY"
  echo "Löschen und neu erstellen? [j/N]"
  read -r antwort
  [ "$antwort" = "j" ] || exit 0
fi

ssh-keygen -t ed25519 -f "$KEY" -N "" -C "silverbullet-sync@$(hostname)"
chmod 600 "$KEY"
chmod 644 "$KEY.pub"

# GitHub-Hostkey eintragen (vermeidet interaktive Abfrage im Container)
ssh-keyscan github.com >> "$SSH_DIR/known_hosts" 2>/dev/null
chmod 644 "$SSH_DIR/known_hosts"

# SSH-Config damit der richtige Key automatisch gewählt wird
cat > "$SSH_DIR/config" <<EOF
Host github.com
  HostName github.com
  User git
  IdentityFile /root/.ssh/id_ed25519
  StrictHostKeyChecking yes
EOF
chmod 600 "$SSH_DIR/config"

echo ""
echo "========================================"
echo " Public Key – bei GitHub eintragen:"
echo " Settings → SSH and GPG keys → New SSH key"
echo "========================================"
echo ""
cat "$KEY.pub"
echo ""
