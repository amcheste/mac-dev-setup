#!/usr/bin/env bash
# preflight-test.sh — Unit tests for setup.sh preflight checks.
# Verifies that setup.sh exits early with clear messages for:
#   - non-admin accounts
#   - unwritable Homebrew prefix
# Runs on macOS without a VM. Safe — does not modify system state.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SETUP="$REPO_DIR/setup.sh"
TMPDIR_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_ROOT"' EXIT

PASS=0
FAIL=0
FAILURES=()

check() {
    local desc="$1"
    local result="$2"   # "pass" or "fail"
    if [[ "$result" == "pass" ]]; then
        echo "  ✓ $desc"
        PASS=$((PASS + 1))
    else
        echo "  ✗ $desc"
        FAIL=$((FAIL + 1))
        FAILURES+=("$desc")
    fi
}

run_setup_with_fake_id() {
    local fake_groups="$1"
    local fake_bin="$TMPDIR_ROOT/fake-bin-nonadmin"
    local out_file="$TMPDIR_ROOT/output-nonadmin.txt"
    mkdir -p "$fake_bin"

    cat > "$fake_bin/id" <<EOF
#!/usr/bin/env bash
if [[ "\${1:-}" == "-Gn" ]]; then
    echo "$fake_groups"
else
    /usr/bin/id "\$@"
fi
EOF
    chmod +x "$fake_bin/id"

    PATH="$fake_bin:$PATH" bash "$SETUP" > "$out_file" 2>&1 && echo 0 || echo $?
}

run_setup_with_unwritable_prefix() {
    local fake_bin="$TMPDIR_ROOT/fake-bin-nowrite"
    local fake_prefix="$TMPDIR_ROOT/fake-prefix"
    local out_file="$TMPDIR_ROOT/output-nowrite.txt"
    mkdir -p "$fake_bin" "$fake_prefix"
    chmod 555 "$fake_prefix"

    # Fake brew that reports our unwritable prefix
    cat > "$fake_bin/brew" <<EOF
#!/usr/bin/env bash
if [[ "\${1:-}" == "--prefix" ]]; then
    echo "$fake_prefix"
else
    /opt/homebrew/bin/brew "\$@"
fi
EOF
    chmod +x "$fake_bin/brew"

    # Fake id that reports admin (so we pass the admin check)
    cat > "$fake_bin/id" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "-Gn" ]]; then
    echo "staff admin everyone"
else
    /usr/bin/id "$@"
fi
EOF
    chmod +x "$fake_bin/id"

    PATH="$fake_bin:$PATH" bash "$SETUP" > "$out_file" 2>&1 && echo 0 || echo $?
    chmod 755 "$fake_prefix"
}

echo ""
echo "━━━ Preflight Unit Tests ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── Test: root / sudo is rejected ─────────────────────────────────────────────
echo ""
echo "── Root / sudo check"

OUT_ROOT="$TMPDIR_ROOT/output-root.txt"
FAKE_BIN_ROOT="$TMPDIR_ROOT/fake-bin-root"
mkdir -p "$FAKE_BIN_ROOT"

cat > "$FAKE_BIN_ROOT/id" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "-u" ]]; then
    echo "0"
elif [[ "${1:-}" == "-Gn" ]]; then
    echo "staff admin everyone"
else
    /usr/bin/id "$@"
fi
EOF
chmod +x "$FAKE_BIN_ROOT/id"

PATH="$FAKE_BIN_ROOT:$PATH" bash "$SETUP" > "$OUT_ROOT" 2>&1 && EXIT_ROOT=0 || EXIT_ROOT=$?

check "setup.sh exits non-zero when run as root" \
    "$([[ $EXIT_ROOT -ne 0 ]] && echo pass || echo fail)"
check "setup.sh prints 'must not be run as root' message" \
    "$(grep -q 'must not be run as root' "$OUT_ROOT" && echo pass || echo fail)"
check "setup.sh prints sudo chown fix hint when run as root" \
    "$(grep -q 'chown' "$OUT_ROOT" && echo pass || echo fail)"
check "setup.sh does not reach package install when run as root" \
    "$(! grep -q 'Installing packages' "$OUT_ROOT" && echo pass || echo fail)"

# ── Test: non-admin account is rejected ───────────────────────────────────────
echo ""
echo "── Non-admin account check"

OUT_NONADMIN="$TMPDIR_ROOT/output-nonadmin.txt"
EXIT_NONADMIN="$(run_setup_with_fake_id "staff everyone localaccounts")"
# Output was written to file by the subshell; recreate here via direct run
FAKE_BIN_NA="$TMPDIR_ROOT/fake-bin-na2"
mkdir -p "$FAKE_BIN_NA"
cat > "$FAKE_BIN_NA/id" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "-Gn" ]]; then
    echo "staff everyone localaccounts"
else
    /usr/bin/id "$@"
fi
EOF
chmod +x "$FAKE_BIN_NA/id"
PATH="$FAKE_BIN_NA:$PATH" bash "$SETUP" > "$OUT_NONADMIN" 2>&1 && EXIT_NONADMIN=0 || EXIT_NONADMIN=$?

check "setup.sh exits non-zero for non-admin" \
    "$([[ $EXIT_NONADMIN -ne 0 ]] && echo pass || echo fail)"
check "setup.sh prints admin error message" \
    "$(grep -q 'not an administrator' "$OUT_NONADMIN" && echo pass || echo fail)"
check "setup.sh does not reach package install for non-admin" \
    "$(! grep -q 'Installing packages' "$OUT_NONADMIN" && echo pass || echo fail)"

# ── Test: unwritable Homebrew prefix is caught ────────────────────────────────
echo ""
echo "── Unwritable Homebrew prefix check"

OUT_NOWRITE="$TMPDIR_ROOT/output-nowrite.txt"
FAKE_BIN_NW="$TMPDIR_ROOT/fake-bin-nw"
FAKE_PREFIX_NW="$TMPDIR_ROOT/fake-prefix-nw"
mkdir -p "$FAKE_BIN_NW" "$FAKE_PREFIX_NW"
chmod 555 "$FAKE_PREFIX_NW"

cat > "$FAKE_BIN_NW/brew" <<EOF
#!/usr/bin/env bash
if [[ "\${1:-}" == "--prefix" ]]; then
    echo "$FAKE_PREFIX_NW"
else
    /opt/homebrew/bin/brew "\$@"
fi
EOF
chmod +x "$FAKE_BIN_NW/brew"

cat > "$FAKE_BIN_NW/id" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "-Gn" ]]; then
    echo "staff admin everyone"
else
    /usr/bin/id "$@"
fi
EOF
chmod +x "$FAKE_BIN_NW/id"

PATH="$FAKE_BIN_NW:$PATH" bash "$SETUP" > "$OUT_NOWRITE" 2>&1 && EXIT_NOWRITE=0 || EXIT_NOWRITE=$?
chmod 755 "$FAKE_PREFIX_NW"

check "setup.sh exits non-zero for unwritable prefix" \
    "$([[ $EXIT_NOWRITE -ne 0 ]] && echo pass || echo fail)"
check "setup.sh prints writability error message" \
    "$(grep -q 'not writable' "$OUT_NOWRITE" && echo pass || echo fail)"
check "setup.sh does not reach package install for unwritable prefix" \
    "$(! grep -q 'Installing packages' "$OUT_NOWRITE" && echo pass || echo fail)"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "━━━ Results ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Passed: $PASS"
echo "  Failed: $FAIL"

if [[ $FAIL -gt 0 ]]; then
    echo ""
    echo "Failures:"
    for f in "${FAILURES[@]}"; do
        echo "  - $f"
    done
    exit 1
fi

echo ""
echo "✓ All preflight checks verified."
