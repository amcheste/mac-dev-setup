#!/usr/bin/env bash
# Host-side orchestrator for VM acceptance testing via Tart.
# Provisions a clean macOS VM, runs setup.sh, executes acceptance-test.sh.

set -euo pipefail

VM_NAME="mac-dev-setup-test-$(date +%s)"
BASE_IMAGE="ghcr.io/cirruslabs/macos-sequoia-base:latest"
SSH_USER="admin"
SSH_PASS="admin"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── Preflight ──────────────────────────────────────────────────────────────────

if ! command -v tart &>/dev/null; then
  echo "ERROR: tart not found. Install with:" >&2
  echo "  brew install cirruslabs/cli/tart" >&2
  exit 1
fi

if ! command -v sshpass &>/dev/null; then
  echo "ERROR: sshpass not found. Install with:" >&2
  echo "  brew install hudochenkov/sshpass/sshpass" >&2
  exit 1
fi

# ── Cleanup trap ──────────────────────────────────────────────────────────────

cleanup() {
  echo ""
  echo "▶ Cleaning up VM: $VM_NAME"
  tart stop "$VM_NAME" --timeout 10 2>/dev/null || true
  tart delete "$VM_NAME" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# ── SSH helper ────────────────────────────────────────────────────────────────

vm_ssh() {
  sshpass -p "$SSH_PASS" ssh \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o LogLevel=ERROR \
    "${SSH_USER}@${VM_IP}" "$@"
}

vm_scp() {
  sshpass -p "$SSH_PASS" scp \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o LogLevel=ERROR \
    "$1" "${SSH_USER}@${VM_IP}:$2"
}

# ── Steps ─────────────────────────────────────────────────────────────────────

echo "▶ Cloning base image: $BASE_IMAGE"
tart clone "$BASE_IMAGE" "$VM_NAME"

echo "▶ Starting VM (headless)"
tart run "$VM_NAME" --no-graphics &

echo "▶ Waiting for VM IP address"
VM_IP=""
for i in $(seq 1 60); do
  VM_IP=$(tart ip "$VM_NAME" 2>/dev/null || true)
  if [[ -n "$VM_IP" ]]; then
    echo "  IP: $VM_IP (after ${i}×5s)"
    break
  fi
  sleep 5
done

if [[ -z "$VM_IP" ]]; then
  echo "ERROR: Timed out waiting for VM IP address." >&2
  exit 1
fi

echo "▶ Waiting for SSH"
for i in $(seq 1 30); do
  if nc -z "$VM_IP" 22 2>/dev/null; then
    echo "  SSH ready (after ${i}×5s)"
    break
  fi
  if [[ $i -eq 30 ]]; then
    echo "ERROR: Timed out waiting for SSH." >&2
    exit 1
  fi
  sleep 5
done

echo "▶ Cloning repository into VM"
vm_ssh "git clone https://github.com/amcheste/mac-dev-setup ~/Repos/amcheste/mac-dev-setup"

echo "▶ Removing cirruslabs/cli tap (simulates fresh machine without pre-added taps)"
vm_ssh "brew untap cirruslabs/cli 2>/dev/null || true"

echo "▶ Pre-seeding ~/.secrets with placeholder values (skips interactive credential wizard)"
vm_ssh 'printf "%s\n" \
  "# Placeholder secrets for VM acceptance test — not real credentials." \
  "export ANTHROPIC_API_KEY=\"vm-test-placeholder\"" \
  "export OCIR_TOKEN=\"vm-test-placeholder\"" \
  "export OCIR_REGION=\"vm-test-placeholder\"" \
  "export OCIR_NAMESPACE=\"vm-test-placeholder\"" \
  "export DIGITAL_OCEAN_TOKEN=\"vm-test-placeholder\"" \
  "export DB_PASSWORD=\"vm-test-placeholder\"" \
  > ~/.secrets && chmod 600 ~/.secrets'

echo "▶ Running setup.sh (using Brewfile.vm — excludes large IDEs)"
vm_ssh "cd ~/Repos/amcheste/mac-dev-setup && BREWFILE=Brewfile.vm bash setup.sh"

echo "▶ Copying acceptance-test.sh to VM"
vm_scp "$SCRIPT_DIR/acceptance-test.sh" "/tmp/acceptance-test.sh"

echo "▶ Running acceptance-test.sh"
vm_ssh "bash /tmp/acceptance-test.sh"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ VM acceptance test passed."
