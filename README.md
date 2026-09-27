# ELAN2513 Linux Touchscreen Fix

A kernel-module fix for the ELAN2513 I2C HID touchscreen (`04F3:2C3F`)
on the tested HP Pavilion 15-eg3xxx platform.

## Fix

The ELAN2513 controller requires the ACPI power resource:

    \\_SB.PC00.I2C0.PTPL

to be transitioned with `_OFF` before HID initialization.

This repository applies that sequence only to:

    ELAN2513:00

The driver waits the tested 10 ms after the transition.

The same preparation callback is also used during normal resume so the
device can perform the required ACPI power-resource transition before the
HID power-on sequence.

## Tested hardware

    HP Pavilion Laptop 15-eg3xxx
    ELAN2513:00
    04F3:2C3F

## Tested kernel

    Ubuntu
    7.0.0-34-generic

Other kernel versions may work, but they are not claimed as tested by this
release because the modules are built directly against the running kernel.

## Installation on Ubuntu

Install the build requirements:

    sudo apt update
    sudo apt install git build-essential linux-headers-$(uname -r)

Clone the exact tested release:

    git clone --branch v0.2.0-kernel-7.0.0-34 --depth 1 https://github.com/amartyasinghnamra/elan2513-linux-fix.git
    cd elan2513-linux-fix

Install:

    sudo ./install.sh

Reboot:

    sudo reboot

The installer:

1. Builds `i2c-hid` and `i2c-hid-acpi` against the currently running kernel.
2. Installs the patched modules under:
   `/lib/modules/<kernel>/updates/elan-touchscreen/`
3. Creates:
   `/etc/modules-load.d/elan2513.conf`
4. Runs `depmod`.
5. Rebuilds the initramfs for the running kernel.

No manual source modification is required.

The fix does not require `acpi_call`, manual sysfs binding, manual `modprobe`,
or an `acpid` lid workaround.

## Verify after reboot

Check the kernel:

    uname -r

Check the module path:

    modinfo -n i2c_hid_acpi

It should resolve to:

    /lib/modules/<kernel>/updates/elan-touchscreen/i2c-hid-acpi.ko

Check the I2C driver binding:

    readlink /sys/bus/i2c/devices/i2c-ELAN2513:00/driver

Expected:

    /sys/bus/i2c/drivers/i2c_hid_acpi

Check the HID device:

    find /sys/bus/hid/devices -maxdepth 1 -type l -name '0018:04F3:*' -print

Check libinput:

    sudo libinput list-devices | grep -A15 -B2 -i ELAN2513

Check ACPI power state:

    cat /sys/bus/acpi/devices/ELAN2513:00/power_state
    cat /sys/bus/acpi/devices/ELAN2513:00/real_power_state

Check kernel messages:

    sudo dmesg | grep -iE 'ELAN2513|PTPL|04F3:2C3F|hid-multitouch|i2c_hid'

A successful boot should show the ELAN2513 device through `i2c_hid_acpi`,
the HID ID `04F3:2C3F`, and a touch-capable libinput device.

## Suspend / resume test

After the touchscreen is working after boot:

    systemctl suspend

After waking, test the touchscreen physically and run:

    cat /sys/bus/acpi/devices/ELAN2513:00/power_state
    cat /sys/bus/acpi/devices/ELAN2513:00/real_power_state

Then:

    sudo libinput list-devices | grep -A15 -B2 -i ELAN2513

The driver contains a resume preparation callback which reapplies the
required PTPL power-resource transition before the normal HID power-on
operation.

## Rollback

From the repository:

    sudo ./uninstall.sh

Then reboot:

    sudo reboot

The rollback removes the patched modules, removes the automatic module
loading configuration, updates the module database, and rebuilds the
initramfs.

## Requirements

- Ubuntu/Linux system with matching kernel headers
- GCC and kernel build tools
- Root privileges
- I2C HID and ACPI support
- Compatible ELAN2513 hardware

### Secure Boot

These locally built modules are unsigned.

If Secure Boot is enabled, the kernel may refuse to load them. Disable
Secure Boot or sign the modules before rebooting.

## Ubuntu Live testing

The fix can be tested from an Ubuntu Live USB on compatible hardware.

Boot Ubuntu and select **Try Ubuntu**.

Install the build requirements:

    sudo apt update
    sudo apt install git build-essential linux-headers-$(uname -r)

Clone the exact release:

    git clone --branch v0.2.0-kernel-7.0.0-34 --depth 1 https://github.com/amartyasinghnamra/elan2513-linux-fix.git
    cd elan2513-linux-fix

Check the environment:

    uname -r
    cat /sys/class/dmi/id/product_name

Install:

    sudo ./install.sh

Reboot:

    sudo reboot

After reboot, use the verification commands above.

Ubuntu Live sessions normally do not persist changes after the session is
shut down unless persistent storage is configured.

## Scope and safety

The ELAN-specific ACPI handling is explicitly limited to the ACPI client
name `ELAN2513:00`. Other I2C HID devices continue through the normal
driver path.

The repository contains out-of-tree Linux kernel driver sources. Locally
built unsigned modules can cause the kernel to report an out-of-tree or
unsigned module taint. This is expected.

## License

The modified files originate from the Linux kernel and retain their
respective upstream licensing and copyright notices.
