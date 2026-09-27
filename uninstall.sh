#!/usr/bin/env bash
set -euo pipefail

KVER="$(uname -r)"
DEST="/lib/modules/$KVER/updates/elan-touchscreen"
MODULES_LOAD="/etc/modules-load.d/elan2513.conf"

if [[ $EUID -ne 0 ]]; then
    echo "Please run:"
    echo "  sudo ./uninstall.sh"
    exit 1
fi

echo
echo "=============================================="
echo " ELAN2513 Touchscreen Fix Rollback"
echo "=============================================="
echo
echo "Kernel: $KVER"
echo

echo "[1/4] Removing automatic module loading..."
rm -f "$MODULES_LOAD"

echo
echo "[2/4] Removing patched modules..."
rm -f "$DEST/i2c-hid.ko"
rm -f "$DEST/i2c-hid-acpi.ko"
rm -f "$DEST"/*.ko.* 2>/dev/null || true
rmdir "$DEST" 2>/dev/null || true

echo
echo "[3/4] Updating module database..."
depmod -a "$KVER"

echo
echo "[4/4] Rebuilding initramfs..."
update-initramfs -u -k "$KVER"

echo
echo "=============================================="
echo " Rollback complete"
echo "=============================================="
echo
echo "The stock kernel I2C HID modules will be used after reboot."
echo
echo "Reboot:"
echo "  sudo reboot"
