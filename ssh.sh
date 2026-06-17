#!/usr/bin/env bash

set -euo pipefail

PUBKEY_URL="https://kevinzonda.com/pubkey"
SSH_DIR="$HOME/.ssh"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"

BEGIN_MARKER="# BEGIN kevinzonda.com/pubkey auto-sync"
END_MARKER="# END kevinzonda.com/pubkey auto-sync"

TMP_KEYS="$(mktemp)"
TMP_AUTH="$(mktemp)"

cleanup() {
  rm -f "$TMP_KEYS" "$TMP_AUTH"
}
trap cleanup EXIT

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

curl -fsSL "$PUBKEY_URL" -o "$TMP_KEYS"

grep -E '^(ssh-rsa|ssh-ed25519|ecdsa-sha2-nistp[0-9]+|sk-ssh-ed25519|sk-ecdsa-sha2-nistp256) ' "$TMP_KEYS" > "${TMP_KEYS}.valid" || {
  echo "No valid SSH public keys found from $PUBKEY_URL" >&2
  exit 1
}

mv "${TMP_KEYS}.valid" "$TMP_KEYS"

touch "$AUTHORIZED_KEYS"
chmod 600 "$AUTHORIZED_KEYS"

awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" '
  $0 == begin { skip=1; next }
  $0 == end { skip=0; next }
  !skip { print }
' "$AUTHORIZED_KEYS" > "$TMP_AUTH"

{
  cat "$TMP_AUTH"
  echo "$BEGIN_MARKER"
  cat "$TMP_KEYS"
  echo "$END_MARKER"
} > "$AUTHORIZED_KEYS"

chmod 600 "$AUTHORIZED_KEYS"

echo "sync ssh pk done."
