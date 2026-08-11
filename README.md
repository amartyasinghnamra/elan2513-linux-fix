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
