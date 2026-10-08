#!/usr/bin/env bash
# Private network on the Ethernet cable between the computer running the model and the
# mini PC running NOMAD (no router needed). This computer gets a fixed address (10.77.0.1),
# hands out addresses to the mini PC (DHCP) and shares its internet connection (NAT)
# so NOMAD can download its content. macOS and Linux (NetworkManager); Windows: link.ps1
#
#   sudo network/link.sh up       # set it up (on macOS again after every restart)
#   sudo network/link.sh down     # undo everything
#   network/link.sh status        # what is set up, which address the mini PC got
#
# Options (environment): NOMAD_LINK_IF (e.g. en7, eth1; default: the wired adapter with
# a cable that is not used for the internet), NOMAD_LINK_NAT=0 (macOS: no internet for the mini PC)
set -Eeuo pipefail

readonly LINK_IP=10.77.0.1
readonly NET=10.77.0.0
readonly MASK=255.255.255.0
readonly RANGE_FIRST=10.77.0.10
readonly RANGE_LAST=10.77.0.50
readonly OS=$(uname -s)

# macOS
readonly BOOTPD_CONF=/etc/bootpd.plist
readonly BOOTPD_BACKUP=/etc/bootpd.plist.nomad-backup
readonly BOOTPD_DAEMON=/System/Library/LaunchDaemons/bootps.plist
readonly LEASES=/var/db/dhcpd_leases
readonly PF_ANCHOR=com.apple/250.NomadLink
readonly STATE_DIR=/var/run/nomad-link

# Linux
readonly NM_CONNECTION=nomad-link

say() {
  printf '\033[1;32m[link]\033[0m %s\n' "$*"
}

die() {
  printf '\033[1;31m[link]\033[0m %s\n' "$*" >&2
  exit 1
}

need_root() {
  ((EUID == 0)) || die "Run with sudo: sudo $0 $1"
}

# Interface used for the internet
wan_device() {
  if [[ $OS == Darwin ]]; then
    route -n get default 2>/dev/null | awk '/interface:/ {print $2}'
  else
    ip route show default 2>/dev/null | awk '{for (i = 1; i < NF; i++) if ($i == "dev") {print $(i + 1); exit}}'
  fi
}

# Wired adapter with a cable in it (not Wi-Fi, not Thunderbolt Bridge, not the internet one)
link_device() {
  if [[ -n ${NOMAD_LINK_IF:-} ]]; then
    echo "$NOMAD_LINK_IF"
    return
  fi
  local dev wan
  wan=$(wan_device)
  if [[ $OS == Darwin ]]; then
    for dev in $(networksetup -listallhardwareports | awk '/^Hardware Port: .*(LAN|Ethernet)/ {getline; print $2}'); do
      [[ $dev != "$wan" ]] && ifconfig "$dev" 2>/dev/null | grep -q 'status: active' && { echo "$dev"; return; }
    done
  else
    for dev in /sys/class/net/*; do
      dev=${dev##*/}
      [[ $dev != "$wan" && -e /sys/class/net/$dev/device && ! -e /sys/class/net/$dev/wireless ]] || continue
      [[ $(cat "/sys/class/net/$dev/carrier" 2>/dev/null) == 1 ]] && { echo "$dev"; return; }
    done
  fi
  die "No wired adapter with a cable found. Plug in the cable or set NOMAD_LINK_IF"
}

link_address() {
  if [[ $OS == Darwin ]]; then
    ipconfig getifaddr "$1" || echo none
  else
    ip -4 -o addr show dev "$1" | awk '{print $4}' | head -1 | grep . || echo none
  fi
}

# --- macOS: fixed address + bootpd (DHCP) + pf (NAT) ---

# Network service name for a device, e.g. en7 -> "USB 10/100/1000 LAN"
mac_service() {
  networksetup -listnetworkserviceorder \
    | awk -v dev="$1" '/^\([0-9*]+\)/ {sub(/^\([0-9*]+\) /, ""); name=$0} $0 ~ "Device: " dev "\\)" {print name}'
}

mac_write_bootpd() {
  local dev=$1 router='' dns=''
  if [[ -f $BOOTPD_CONF && ! -f $BOOTPD_BACKUP ]] && ! grep -q nomad-link "$BOOTPD_CONF"; then
    cp "$BOOTPD_CONF" "$BOOTPD_BACKUP"
  fi
  if [[ ${NOMAD_LINK_NAT:-1} == 1 ]]; then
    router="<key>dhcp_router</key><string>${LINK_IP}</string>"
    dns='<key>dhcp_domain_name_server</key><array><string>1.1.1.1</string><string>8.8.8.8</string></array>'
  fi
  cat >"$BOOTPD_CONF" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>bootp_enabled</key><false/>
	<key>dhcp_enabled</key><array><string>${dev}</string></array>
	<key>Subnets</key>
	<array>
		<dict>
			<key>name</key><string>nomad-link</string>
			<key>net_address</key><string>${NET}</string>
			<key>net_mask</key><string>${MASK}</string>
			<key>net_range</key><array><string>${RANGE_FIRST}</string><string>${RANGE_LAST}</string></array>
			<key>allocate</key><true/>
			<key>lease_max</key><integer>86400</integer>
			${router}
			${dns}
		</dict>
	</array>
</dict>
</plist>
EOF
}

mac_start_nat() {
  local wan
  wan=$(wan_device)
  [[ ${NOMAD_LINK_NAT:-1} == 1 ]] || return 0
  if [[ -z $wan || $wan == "$1" ]]; then
    say "No internet right now; the mini PC will be offline (run up again later)"
    return
  fi
  sysctl -qw net.inet.ip.forwarding=1 >/dev/null
  echo "nat on ${wan} inet from ${NET}/24 to any -> (${wan})" | pfctl -q -a "$PF_ANCHOR" -f - 2>/dev/null
  [[ -s $STATE_DIR/pf-token ]] || pfctl -E 2>&1 | awk '/Token/ {print $NF}' >"$STATE_DIR/pf-token"
  say "Internet for the mini PC through ${wan}"
}

mac_up() {
  local dev=$1 service
  service=$(mac_service "$dev")
  [[ -n $service ]] || die "No network service for ${dev}"
  mkdir -p "$STATE_DIR"
  echo "$service" >"$STATE_DIR/service"
  networksetup -setmanual "$service" "$LINK_IP" "$MASK"
  mac_write_bootpd "$dev"
  launchctl enable system/com.apple.bootpd
  launchctl bootout system "$BOOTPD_DAEMON" 2>/dev/null || true
  launchctl bootstrap system "$BOOTPD_DAEMON"
  mac_start_nat "$dev"
}

mac_down() {
  pfctl -q -a "$PF_ANCHOR" -F all 2>/dev/null || true
  [[ ! -s $STATE_DIR/pf-token ]] || pfctl -X "$(cat "$STATE_DIR/pf-token")" >/dev/null 2>&1 || true
  sysctl -qw net.inet.ip.forwarding=0 >/dev/null
  launchctl bootout system "$BOOTPD_DAEMON" 2>/dev/null || true
  launchctl disable system/com.apple.bootpd
  if [[ -f $BOOTPD_BACKUP ]]; then
    mv "$BOOTPD_BACKUP" "$BOOTPD_CONF"
  else
    rm -f "$BOOTPD_CONF"
  fi
  local service
  service=$(cat "$STATE_DIR/service" 2>/dev/null || mac_service "$(link_device)")
  [[ -z $service ]] || networksetup -setdhcp "$service"
  rm -rf "$STATE_DIR"
}

mac_status() {
  echo "DHCP server:    $(launchctl print system/com.apple.bootpd >/dev/null 2>&1 && echo on || echo off)"
  echo "Internet share: $([[ $(sysctl -n net.inet.ip.forwarding) == 1 ]] && echo on || echo off)"
  echo "Mini PC:"
  # Leases outlive the devices: show only those this Mac sees on the cable right now
  local ip name found=0
  while read -r ip name; do
    arp -n "$ip" 2>/dev/null | grep -q ' at [0-9a-f]' || continue
    echo "  ${ip}  ${name}"
    found=1
  done < <(awk -F= '/name=/ {n=$2} /ip_address=/ {print $2, n}' "$LEASES" 2>/dev/null)
  ((found)) || echo "  not seen yet (is the mini PC on and set to DHCP?)"
}

# --- Linux: NetworkManager "shared" mode does the address, DHCP and NAT ---

linux_up() {
  command -v nmcli >/dev/null || die "NetworkManager (nmcli) is needed"
  nmcli connection delete "$NM_CONNECTION" >/dev/null 2>&1 || true
  nmcli connection add type ethernet ifname "$1" con-name "$NM_CONNECTION" autoconnect yes \
    ipv4.method shared ipv4.addresses "${LINK_IP}/24" ipv6.method disabled >/dev/null
  nmcli connection up "$NM_CONNECTION" >/dev/null
}

linux_down() {
  nmcli connection delete "$NM_CONNECTION" >/dev/null 2>&1 || true
}

linux_status() {
  echo "Shared network: $(nmcli -t -f NAME connection show --active 2>/dev/null | grep -qx "$NM_CONNECTION" && echo on || echo off)"
  echo "Mini PC:"
  local leases
  leases=$(cat /var/lib/NetworkManager/dnsmasq-*.leases 2>/dev/null || true)
  if [[ -n $leases ]]; then
    awk '{print "  " $3 "  " $4 "  (" $2 ")"}' <<<"$leases"
  else
    echo "  no address handed out yet (is the mini PC on and set to DHCP?)"
  fi
}

up() {
  need_root up
  local dev
  dev=$(link_device)
  say "Cable adapter ${dev}: ${LINK_IP}"
  if [[ $OS == Darwin ]]; then mac_up "$dev"; else linux_up "$dev"; fi
  say "Done. The mini PC gets an address from ${RANGE_FIRST}-${RANGE_LAST} (check: ./nomad status)"
}

down() {
  need_root down
  if [[ $OS == Darwin ]]; then mac_down; else linux_down; fi
  say "Removed: fixed address, DHCP and internet sharing"
}

status() {
  local dev
  dev=$(link_device)
  echo "Cable adapter:  ${dev}$([[ $OS == Darwin ]] && echo " ($(mac_service "$dev"))")"
  echo "Address:        $(link_address "$dev")"
  if [[ $OS == Darwin ]]; then mac_status; else linux_status; fi
}

case ${1:-} in
  up) up ;;
  down) down ;;
  status) status ;;
  *) die "Usage: $0 up|down|status" ;;
esac
