#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KVER="$(uname -r)"
BUILD="/lib/modules/$KVER/build"
DEST="/lib/modules/$KVER/updates/elan-touchscreen"
MODULE_DIR="$PROJECT_DIR/i2c-hid"

echo
echo "=============================================="
echo " ELAN2513 Linux Touchscreen Fix"
echo "=============================================="
echo
echo "Kernel : $KVER"
echo "Source : $PROJECT_DIR"
echo

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Root privileges are required."
    echo
    echo "Run:"
    echo "  sudo ./install.sh"
    exit 1
fi

if [[ ! -d "$BUILD" ]]; then
    echo "ERROR: Matching kernel build directory not found:"
    echo "  $BUILD"
    echo
    echo "Install the kernel headers/development package for:"
    echo "  $KVER"
    exit 1
fi

if [[ ! -f "$BUILD/Makefile" ]]; then
    echo "ERROR: Kernel build tree is incomplete:"
    echo "  $BUILD"
    exit 1
fi

if [[ ! -f "$MODULE_DIR/i2c-hid-acpi.c" ]]; then
    echo "ERROR: i2c-hid-acpi.c not found."
    exit 1
fi

if ! grep -q 'msleep(10);' "$MODULE_DIR/i2c-hid-acpi.c"; then
    echo "ERROR: ELAN 10 ms workaround was not found."
    exit 1
fi

echo "[1/7] Checking kernel configuration..."

if [[ -f "$BUILD/.config" ]]; then
    echo "      Kernel configuration found."
else
    echo "      Kernel .config is not directly available."
    echo "      Continuing; the kernel build system will validate compatibility."
fi

echo
echo "[2/7] Building modules..."

make -C "$BUILD" M="$MODULE_DIR" clean
make -C "$BUILD" M="$MODULE_DIR" modules

for module in i2c-hid.ko i2c-hid-acpi.ko; do
    if [[ ! -f "$MODULE_DIR/$module" ]]; then
        echo "ERROR: Build did not produce $module"
        exit 1
    fi
done

echo
echo "[3/7] Checking module compatibility..."

RUNNING_VERMAGIC="$(modinfo -F vermagic "$MODULE_DIR/i2c-hid-acpi.ko")"

if [[ -z "$RUNNING_VERMAGIC" ]]; then
    echo "ERROR: Could not read module vermagic."
    exit 1
fi

if [[ "$RUNNING_VERMAGIC" != "$KVER "* ]]; then
    echo "ERROR: Built module does not match the running kernel."
    echo
    echo "Running kernel:"
    echo "  $KVER"
    echo
    echo "Module vermagic:"
    echo "  $RUNNING_VERMAGIC"
    exit 1
fi

echo "      Module vermagic:"
echo "        $RUNNING_VERMAGIC"
echo "      Kernel:"
echo "        $KVER"
echo "      Compatibility verified."

echo
echo "[4/7] Preparing destination..."

mkdir -p "$DEST"

echo
echo "[5/7] Installing modules..."

for module in i2c-hid.ko i2c-hid-acpi.ko; do
    if [[ -f "$DEST/$module" && ! -f "$DEST/$module.stock-backup" ]]; then
        echo "Backing up existing custom module: $module"
        cp -a "$DEST/$module" "$DEST/$module.stock-backup"
    fi

    install -m 0644 "$MODULE_DIR/$module" "$DEST/$module"
done

depmod -a "$KVER"

echo
echo "[6/7] Updating initramfs..."

if command -v update-initramfs >/dev/null 2>&1; then
    update-initramfs -u -k "$KVER"
elif command -v dracut >/dev/null 2>&1; then
    dracut --force --kver "$KVER"
else
    echo "WARNING: Neither update-initramfs nor dracut was found."
    echo "The modules were installed, but the initramfs was not rebuilt."
fi

echo
echo "[7/7] Verifying installation..."

RESOLVED="$(modinfo -n i2c_hid_acpi)"

if [[ "$RESOLVED" != "$DEST/i2c-hid-acpi.ko" ]]; then
    echo "ERROR: modprobe does not resolve to the custom module."
    echo "Resolved:"
    echo "  $RESOLVED"
    exit 1
fi

echo
echo "=============================================="
echo " Installation complete"
echo "=============================================="
echo
echo "Kernel:"
echo "  $KVER"
echo
echo "Custom module:"
echo "  $RESOLVED"
echo
echo "Workaround:"
grep -n 'msleep(10)' "$MODULE_DIR/i2c-hid-acpi.c"
echo
echo "Reboot to activate:"
echo "  sudo reboot"
echo
