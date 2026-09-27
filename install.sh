#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KVER="$(uname -r)"
BUILD="/lib/modules/$KVER/build"
DEST="/lib/modules/$KVER/updates/elan-touchscreen"
MODULES_LOAD="/etc/modules-load.d/elan2513.conf"

echo
echo "=============================================="
echo " ELAN2513 Persistent Touchscreen Fix"
echo "=============================================="
echo
echo "Kernel : $KVER"
echo "Source : $PROJECT_DIR"
echo

if [[ $EUID -ne 0 ]]; then
    echo "Please run:"
    echo "  sudo ./install.sh"
    exit 1
fi

if [[ ! -d "$BUILD" ]]; then
    echo "ERROR: Matching kernel headers not found:"
    echo "  $BUILD"
    echo
    echo "Install them with:"
    echo "  sudo apt install linux-headers-$KVER"
    exit 1
fi

for file in i2c-hid-acpi.c i2c-hid-core.c i2c-hid.h Makefile Kconfig; do
    if [[ ! -f "$PROJECT_DIR/$file" ]]; then
        echo "ERROR: Required source file not found: $file"
        exit 1
    fi
done

grep -q 'ELAN2513:00' "$PROJECT_DIR/i2c-hid-acpi.c" || {
    echo "ERROR: ELAN2513 support not found in i2c-hid-acpi.c"
    exit 1
}

grep -q 'resume_prepare' "$PROJECT_DIR/i2c-hid.h" || {
    echo "ERROR: resume_prepare support not found in i2c-hid.h"
    exit 1
}

grep -q 'PTPL._OFF' "$PROJECT_DIR/i2c-hid-acpi.c" || {
    echo "ERROR: PTPL._OFF handling not found in i2c-hid-acpi.c"
    exit 1
}

grep -q 'msleep(10);' "$PROJECT_DIR/i2c-hid-acpi.c" || {
    echo "ERROR: 10 ms delay not found in i2c-hid-acpi.c"
    exit 1
}

echo "[1/7] Building modules..."
make -C "$BUILD" M="$PROJECT_DIR" clean
make -C "$BUILD" M="$PROJECT_DIR" modules

echo
echo "[2/7] Preparing destination..."
mkdir -p "$DEST"

echo
echo "[3/7] Installing patched modules..."
install -m 0644 "$PROJECT_DIR/i2c-hid.ko" "$DEST/i2c-hid.ko"
install -m 0644 "$PROJECT_DIR/i2c-hid-acpi.ko" "$DEST/i2c-hid-acpi.ko"

echo
echo "[4/7] Enabling modules at boot..."
cat > "$MODULES_LOAD" <<'EOF'
i2c_hid
i2c_hid_acpi
EOF

chmod 0644 "$MODULES_LOAD"
echo "Created $MODULES_LOAD"

echo
echo "[5/7] Updating module database..."
depmod -a "$KVER"

echo
echo "[6/7] Rebuilding initramfs..."
update-initramfs -u -k "$KVER"

echo
echo "[7/7] Checking installation..."
echo
echo "Resolved i2c_hid_acpi:"
modinfo -n i2c_hid_acpi

echo
echo "Module version:"
modinfo -F vermagic i2c_hid_acpi

echo
echo "=============================================="
echo " Installation complete"
echo "=============================================="
echo
echo "Reboot to activate the patched driver:"
echo "  sudo reboot"
echo

if command -v mokutil >/dev/null 2>&1; then
    if mokutil --sb-state 2>/dev/null | grep -qi "SecureBoot enabled"; then
        echo "WARNING: Secure Boot is enabled."
        echo "The locally built unsigned modules may be rejected by the kernel."
        echo "Disable Secure Boot or sign the modules before rebooting."
        echo
    fi
fi
