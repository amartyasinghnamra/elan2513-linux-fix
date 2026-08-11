#!/usr/bin/env bash
set -euo pipefail

KVER="$(uname -r)"
DEST="/lib/modules/$KVER/updates/elan-touchscreen"

if [[ $EUID -ne 0 ]]; then
    echo "Please run:"
    echo "  sudo ./uninstall.sh"
    exit 1
fi

echo
echo "ELAN2513 10ms driver rollback"
echo "Kernel: $KVER"
echo

if [[ ! -d "$DEST" ]]; then
    echo "No custom ELAN driver directory found."
    exit 0
fi

if [[ -f "$DEST/i2c-hid.ko.stock-backup" ]]; then
    cp -a "$DEST/i2c-hid.ko.stock-backup" "$DEST/i2c-hid.ko"
    echo "Restored stock i2c-hid.ko"
else
    rm -f "$DEST/i2c-hid.ko"
fi

if [[ -f "$DEST/i2c-hid-acpi.ko.stock-backup" ]]; then
    cp -a "$DEST/i2c-hid-acpi.ko.stock-backup" "$DEST/i2c-hid-acpi.ko"
    echo "Restored stock i2c-hid-acpi.ko"
else
    rm -f "$DEST/i2c-hid-acpi.ko"
fi

depmod -a "$KVER"
update-initramfs -u -k "$KVER"

echo
echo "Rollback complete."
echo "Reboot:"
echo "  sudo reboot"
