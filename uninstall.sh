#!/usr/bin/env bash
set -euo pipefail

KVER="$(uname -r)"
DEST="/lib/modules/$KVER/updates/elan-touchscreen"

echo
echo "=============================================="
echo " ELAN2513 Linux Touchscreen Fix - Rollback"
echo "=============================================="
echo
echo "Kernel : $KVER"
echo

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Root privileges are required."
    echo
    echo "Run:"
    echo "  sudo ./uninstall.sh"
    exit 1
fi

if [[ ! -d "$DEST" ]]; then
    echo "No custom ELAN driver installation found."
    exit 0
fi

echo "[1/4] Restoring/removing custom modules..."

for module in i2c-hid.ko i2c-hid-acpi.ko; do
    backup="$DEST/$module.stock-backup"
    installed="$DEST/$module"

    if [[ -f "$backup" ]]; then
        cp -a "$backup" "$installed"
        rm -f "$backup"
        echo "Restored stock $module"
    else
        rm -f "$installed"
        echo "Removed custom $module"
    fi
done

echo
echo "[2/4] Removing empty custom directory..."

rmdir "$DEST" 2>/dev/null || true

echo
echo "[3/4] Updating module database..."

depmod -a "$KVER"

echo
echo "[4/4] Updating initramfs..."

if command -v update-initramfs >/dev/null 2>&1; then
    update-initramfs -u -k "$KVER"
elif command -v dracut >/dev/null 2>&1; then
    dracut --force --kver "$KVER"
else
    echo "WARNING: Neither update-initramfs nor dracut was found."
    echo "The modules were removed, but the initramfs was not rebuilt."
fi

echo
echo "=============================================="
echo " Rollback complete"
echo "=============================================="
echo
echo "Reboot to return fully to the stock driver:"
echo "  sudo reboot"
echo
