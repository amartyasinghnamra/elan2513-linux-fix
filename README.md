# ELAN2513 Linux Touchscreen Fix

A kernel-module workaround for the ELAN2513 I2C HID touchscreen
(Vendor `04F3`, Product `2C3F`).

## What this changes

For the ELAN2513 ACPI device, the driver explicitly powers off the
`PTPL` ACPI power resource before probing the HID core and waits
10 milliseconds before continuing.

The workaround is applied only to:

    ELAN2513:00

The modified delay is:

    msleep(10);

## Install

Clone the repository:

    git clone https://github.com/amartyasinghnamra/elan2513-linux-fix.git
    cd elan2513-linux-fix

Then:

    sudo ./install.sh

Reboot:

    sudo reboot

## Uninstall / rollback

From the repository:

    sudo ./uninstall.sh

Then reboot.

## Requirements

- Linux kernel with matching headers installed
- GCC / kernel build tools
- Root privileges
- I2C HID touchscreen support

The installer builds the modules against the currently running kernel.

## Hardware

Tested with:

    ELAN2513:00
    04F3:2C3F

## Notes

The module is an out-of-tree kernel module and therefore causes the
kernel to report that it has been tainted.

This is expected for a locally built unsigned kernel module.

## License

The modified files originate from the Linux kernel and retain their
respective upstream licensing and copyright notices.

## Testing on Ubuntu Live

The fix can be tested from an Ubuntu Live USB without installing the operating system permanently.

### 1. Boot Ubuntu Live

Boot an Ubuntu Live USB and select **Try Ubuntu**.

Connect to the internet.

### 2. Install build requirements

Open Terminal and run:

```bash
sudo apt update
sudo apt install git build-essential linux-headers-$(uname -r)
```

### 3. Clone the repository

```bash
git clone https://github.com/amartyasinghnamra/elan2513-linux-fix.git
cd elan2513-linux-fix
```

### 4. Check the running kernel and hardware

```bash
uname -r
cat /sys/class/dmi/id/product_name
```

### 5. Install the workaround

```bash
sudo ./install.sh
```

The installer builds the kernel modules against the currently running kernel.

### 6. Reboot

```bash
sudo reboot
```

### 7. Verify the driver

```bash
uname -r
modinfo -n i2c_hid_acpi
```

The module should resolve to the custom `updates/elan-touchscreen` location.

### 8. Check the ELAN touchscreen

```bash
sudo dmesg | grep -iE "ELAN TEST|PTPL|ELAN2513|04F3:2C3F|hid-multitouch"
```

A successful workaround should contain messages similar to:

```text
ELAN TEST: forcing PTPL._OFF before HID core probe
ELAN TEST: PTPL._OFF status=0x0
```

The touchscreen should then appear as:

```text
ELAN2513:00 04F3:2C3F Touchscreen
```

### Important

Ubuntu Live sessions normally do not persist changes after shutdown unless persistent storage is configured.

This test is intended to verify that the workaround works on a clean Ubuntu environment.
