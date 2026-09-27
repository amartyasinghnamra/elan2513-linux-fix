#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KVER="$(uname -r)"
BUILD="/lib/modules/$KVER/build"
DEST="/lib/modules/$KVER/updates/elan-touchscreen"
MODULES_LOAD="/etc/modules-load.d/elan2513.conf"

echo
echo "=============================================="
echo " ELAN2513 10ms Touchscreen Fix"
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
    exit 1
fi

if [[ ! -f "$PROJECT_DIR/i2c-hid-acpi.c" ]]; then
    echo "ERROR: i2c-hid-acpi.c not found."
    exit 1
fi

if ! grep -q 'msleep(10);' "$PROJECT_DIR/i2c-hid-acpi.c"; then
    echo "ERROR: 10 ms modification not found."
    exit 1
fi

echo "[1/6] Building modules..."

make -C "$BUILD" M="$PROJECT_DIR" clean
make -C "$BUILD" M="$PROJECT_DIR" modules

echo
echo "[2/6] Preparing destination..."
mkdir -p "$DEST"

echo
echo "[3/6] Backing up existing custom modules..."

for module in i2c-hid.ko i2c-hid-acpi.ko; do
    if [[ -f "$DEST/$module" && ! -f "$DEST/$module.stock-backup" ]]; then
        cp -a "$DEST/$module" "$DEST/$module.stock-backup"
        echo "Backed up $module"
    fi
done

echo
echo "[4/6] Installing 10 ms modules..."

install -m 0644 "$PROJECT_DIR/i2c-hid.ko" "$DEST/i2c-hid.ko"
install -m 0644 "$PROJECT_DIR/i2c-hid-acpi.ko" "$DEST/i2c-hid-acpi.ko"

echo
echo "[5/7] Enabling modules at boot..."

cat > "$MODULES_LOAD" <<'EOF'
i2c_hid
i2c_hid_acpi
EOF

chmod 0644 "$MODULES_LOAD"
echo "Created $MODULES_LOAD"

echo
echo "[6/7] Updating module database..."
depmod -a "$KVER"

echo
echo "[7/7] Rebuilding initramfs..."
update-initramfs -u -k "$KVER"

echo
echo "=============================================="
echo " Installation complete"
echo "=============================================="
echo
echo "Kernel:"
echo "  $KVER"
echo
echo "Resolved module:"
modinfo -n i2c_hid_acpi
echo
echo "10 ms source:"
grep -n 'msleep(10)' "$PROJECT_DIR/i2c-hid-acpi.c"
echo
echo "Reboot to activate:"
echo "  sudo reboot"
