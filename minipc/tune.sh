#!/usr/bin/env bash
# Tunes a fresh Debian on a small mini PC for NOMAD: compressed RAM swap (zram),
# a name on the network (nomad.local), and a quiet console. Safe to run again.
#
#   sudo minipc/tune.sh
set -Eeuo pipefail

say() {
  printf '\033[1;32m[tune]\033[0m %s\n' "$*"
}

((EUID == 0)) || { echo "Run with sudo: sudo $0" >&2; exit 1; }

say "Installing zram and mDNS (nomad.local)"
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq zram-tools avahi-daemon >/dev/null

# Half of the RAM as compressed swap: 4 GB RAM behaves like ~6 GB
printf 'ALGO=zstd\nPERCENT=50\nPRIORITY=100\n' >/etc/default/zramswap
systemctl restart zramswap

# HP thin clients (t630, t620, ...) return broken WMI data, which fills the screen
# with "ACPI BIOS Error (bug)"; these modules are not needed on a server
if grep -qi '^HP' /sys/class/dmi/id/sys_vendor 2>/dev/null; then
  say "HP: turning off the HP WMI modules"
  printf '# HP BIOS returns broken WMI data (ACPI BIOS Error spam)\nblacklist hp_wmi\nblacklist wmi_bmof\nblacklist hp_bioscfg\n' \
    >/etc/modprobe.d/nomad-hp-wmi.conf
  modprobe -r hp_wmi wmi_bmof hp_bioscfg 2>/dev/null || true
  update-initramfs -u >/dev/null 2>&1
fi

say "Showing only critical kernel messages on the screen"
echo 'kernel.printk = 3 4 1 3' >/etc/sysctl.d/90-nomad-console.conf
sysctl -q -p /etc/sysctl.d/90-nomad-console.conf
if ! grep -q 'loglevel=3' /etc/default/grub; then
  sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 loglevel=3"/' /etc/default/grub
  update-grub >/dev/null 2>&1
fi

say "Done: $(swapon --show=NAME,SIZE --noheadings | tr '\n' ' ')"
