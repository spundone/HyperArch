#!/usr/bin/env bash
#
# omatether — iPhone USB tethering (HyperWebster OS / Omarchy-compatible)
#
# Plug an iPhone in over USB and use its internet connection (the phone's
# Wi-Fi, or cellular if it isn't on Wi-Fi). Works headless — no GUI needed.
#
# Run with no arguments for the interactive TUI (requires gum), or:
#   omatether.sh <install|pair|unpair|status|priority|uninstall|help>
#
set -euo pipefail

NETFILE="/etc/systemd/network/10-iphone-tether.network"
DESKTOP_FILE="$HOME/.local/share/applications/omatether.desktop"
WINDOWS_CONF="$HOME/.config/caelestia/hypr-user.conf"

# Route metrics: Omarchy ships ethernet=100, wifi=600, wwan=700.
METRIC_FALLBACK=750   # tether used only when nothing better is up (default)
METRIC_PREFERRED=50   # tether beats ethernet/wifi while plugged in

RED=$'\e[31m'; GRN=$'\e[32m'; YLW=$'\e[33m'; DIM=$'\e[2m'; RST=$'\e[0m'
say()  { printf '%s\n' "$*"; }
ok()   { printf '%s\n' "${GRN}✓${RST} $*"; }
warn() { printf '%s\n' "${YLW}!${RST} $*"; }
die()  { printf '%s\n' "${RED}✗${RST} $*" >&2; exit 1; }

as_root() {
  if [[ $EUID -eq 0 ]]; then "$@"; else sudo "$@"; fi
}

# ---------------------------------------------------------------- probes ---

# Find the network interface backed by the ipheth driver, if any.
tether_iface() {
  local dev drv
  for dev in /sys/class/net/*; do
    drv=$(readlink -f "$dev/device/driver" 2>/dev/null) || continue
    [[ ${drv##*/} == ipheth ]] && { basename "$dev"; return 0; }
  done
  return 1
}

# Probes drain output fully ([[ -n $(...) ]]) rather than grep -q, which can
# SIGPIPE the producer and misreport under pipefail.
phone_on_usb()  { [[ -n $(lsusb 2>/dev/null | grep -i 'apple.*iphone' || true) ]]; }
phone_visible() { [[ -n $(idevice_id -l 2>/dev/null || true) ]]; }
phone_paired()  { idevicepair validate >/dev/null 2>&1; }

phone_name() { ideviceinfo -k DeviceName 2>/dev/null || echo "iPhone"; }

# Both must never fail: bare `x=$(...)` assignments under set -e abort the
# whole script (and close the TUI window) if the pipeline fails — which
# happens when the interface vanishes mid-check or no default route exists.
tether_ip() {
  local iface=$1
  ip -4 -br addr show "$iface" 2>/dev/null | awk '{print $3}' || true
}

# Interface currently carrying the default route (empty if offline).
active_uplink() {
  ip route get 1.1.1.1 2>/dev/null \
    | awk '{for(i=1;i<NF;i++) if($i=="dev"){print $(i+1); exit}}' || true
}

current_metric() {
  awk -F= '/^RouteMetric/{print $2; exit}' "$NETFILE" 2>/dev/null
}

net_test() {
  local iface=$1
  curl -sf --interface "$iface" --max-time 5 -o /dev/null https://www.google.com
}

# Poll until the tether has an IP and working internet, or time out (arg:
# seconds). First plug-in after a reboot can take 20-30s before iOS brings
# the interface up and DHCP completes — a fixed short sleep reports false
# "enable hotspot" advice.
tether_wait() {
  local deadline=$(( SECONDS + ${1:-45} )) iface
  while (( SECONDS < deadline )); do
    if iface=$(tether_iface) && [[ -n $(tether_ip "$iface") ]] && net_test "$iface"; then
      return 0
    fi
    sleep 2
  done
  return 1
}

# usbmuxd drops devices that were plugged in before it started
# ("device unconfigured") — a restart rescans the bus.
revive_usbmuxd() {
  as_root systemctl restart usbmuxd || { warn "Could not restart usbmuxd (sudo declined?)"; return 1; }
  sleep 2
}

# ------------------------------------------------------------ networkd -----

write_netfile() {
  local metric=$1
  as_root tee "$NETFILE" >/dev/null <<EOF
# Installed by omatether — iPhone USB tethering.
# Matches by driver so it wins over 20-ethernet.network's Name=eth* glob
# (networkd applies the lexically-first matching file).
[Match]
Driver=ipheth

[Link]
# Never block boot / network-online.target waiting for a phone.
RequiredForOnline=no

[Network]
DHCP=yes

# DNS is global-static via systemd-resolved on Omarchy; match the
# UseDNS=no convention of the stock 20-*.network files.
[DHCPv4]
UseDNS=no
RouteMetric=${metric}

[IPv6AcceptRA]
UseDNS=no
RouteMetric=${metric}
EOF
}

reload_networkd() {
  as_root networkctl reload
  local iface
  if iface=$(tether_iface); then
    as_root networkctl reconfigure "$iface" || true
  fi
}

# Delete our marker-delimited block. Only range-delete when BOTH markers are
# present — with the end marker missing, sed's range would eat everything
# from the begin marker to EOF, including unrelated user config.
strip_windowrules() {
  grep -q '>>> omatether windowrules begin' "$WINDOWS_CONF" || return 0
  if ! grep -q '<<< omatether windowrules end' "$WINDOWS_CONF"; then
    warn "windows.conf has our begin marker but no end marker — leaving it untouched."
    return 1
  fi
  sed -i '/>>> omatether windowrules begin/,/<<< omatether windowrules end/d' "$WINDOWS_CONF"
}

# Small centered floating window for the TUI (user-level Hyprland rule;
# remove-then-append so re-installs stay idempotent).
install_windowrules() {
  [[ -f $WINDOWS_CONF ]] || return 0   # not a Hyprland/Omarchy box — skip
  if ! grep -q 'omatether windowrules begin' "$WINDOWS_CONF"; then
    cp "$WINDOWS_CONF" "$WINDOWS_CONF.bak.$(date +%s)" || return 1
  fi
  strip_windowrules || return 1
  # Ensure the file ends with a newline, or our begin marker glues onto the
  # last existing line and the next strip would delete that line too.
  if [[ -s $WINDOWS_CONF && $(tail -c1 "$WINDOWS_CONF") != "" ]]; then
    printf '\n' >> "$WINDOWS_CONF"
  fi
  cat >> "$WINDOWS_CONF" <<'EOF'
# >>> omatether windowrules begin
# omatether — small floating window, centered.
windowrule = float on,  match:class ^(omatether)$
windowrule = center on, match:class ^(omatether)$
windowrule = size 520 400, match:class ^(omatether)$
# <<< omatether windowrules end
EOF
  hyprctl reload >/dev/null 2>&1 || true
}

remove_windowrules() {
  [[ -f $WINDOWS_CONF ]] || return 0
  strip_windowrules || return 1
  hyprctl reload >/dev/null 2>&1 || true
}

# --------------------------------------------------------- CLI commands ----

# NOTE: every risky step is explicitly guarded — the TUI calls this with
# `|| true`, which disables errexit inside the function, so an unguarded
# failure would otherwise plow on into the next step.
cmd_install() {
  say "Installing iPhone USB tethering support…"
  as_root pacman -S --needed --noconfirm usbmuxd libimobiledevice gum \
    || { warn "Package install failed — no internet, or sudo declined."; return 1; }
  ok "usbmuxd + libimobiledevice installed (usbmuxd starts on demand via udev)"

  # Preserve the current priority on reinstall; default to fallback.
  local metric
  metric=$(current_metric || true)
  metric=${metric:-$METRIC_FALLBACK}
  write_netfile "$metric" || { warn "Could not write $NETFILE."; return 1; }
  reload_networkd || { warn "networkd reload failed."; return 1; }
  ok "networkd profile written: $NETFILE (metric $metric)"

  # Floating TUI launcher (kitty). Uses a dedicated app-id (rather than
  # Omarchy's generic TUI.float) so our own windowrule can size it smaller.
  local self
  self=$(realpath "$0")
  mkdir -p "$(dirname "$DESKTOP_FILE")"
  cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=iPhone Tether
Comment=Use an iPhone's internet over USB
Exec=kitty --class omatether -e "$self"
Icon=phone
Terminal=false
Type=Application
Categories=Network;
EOF
  # elephant/Walker not used on HyperWebster
  install_windowrules || warn "Windowrule install skipped — see above."
  ok "Launcher installed: 'iPhone Tether' (kitty floating window)"

  # If the phone was plugged in before usbmuxd existed it won't be seen yet;
  # restart usbmuxd to rescan. (Do NOT `udevadm trigger` — re-firing add
  # events on a connected iPhone wedges it: "device unconfigured".)
  if phone_on_usb && ! phone_visible; then
    revive_usbmuxd || true
  fi

  say ""
  say "Run '$0' (no arguments) for the TUI, or '$0 pair' to pair now."
}

do_pair_once() {
  # Returns 0 on success; prints the failure reason otherwise.
  local out
  if out=$(idevicepair pair 2>&1); then
    ok "$out"
    return 0
  fi
  case $out in
    *passcode*)  warn "Phone is locked — unlock it." ;;
    *user\ denied*|*denied\ the\ trust*) warn "Trust was declined on the phone." ;;
    *Please\ accept*) warn "Trust dialog showing on the phone — tap Trust." ;;
    *) warn "$out" ;;
  esac
  return 1
}

cmd_pair() {
  command -v idevicepair >/dev/null || die "libimobiledevice not installed — run: $0 install"
  if ! phone_visible; then
    if phone_on_usb; then revive_usbmuxd || true; fi
    phone_visible || die "No iPhone detected over USB. Plug it in and try again."
  fi

  say "Pairing — unlock the iPhone and tap ${GRN}Trust${RST} when prompted…"
  do_pair_once || exit 1

  say ""
  say "Now enable the hotspot on the phone:"
  say "  Settings → Personal Hotspot → Allow Others to Join: ON"
  say "The connection comes up automatically. Check with:  $0 status"
}

cmd_unpair() {
  if idevicepair unpair; then
    ok "Unpaired."
  else
    die "Unpair failed — is a phone connected and paired?"
  fi
}

cmd_status() {
  local iface udid name

  udid=$(idevice_id -l 2>/dev/null | head -1 || true)
  if [[ -n $udid ]]; then
    name=$(phone_name)
    ok "iPhone connected over USB: $name"
    if phone_paired; then
      ok "Paired (trusted)"
    else
      warn "Not paired — run: $0 pair"
    fi
  else
    warn "No iPhone detected over USB"
  fi

  if iface=$(tether_iface); then
    local state addr
    state=$(networkctl status "$iface" 2>/dev/null | awk '/State:/{print $2; exit}' || true)
    ok "Tether interface: $iface ($state)"
    addr=$(tether_ip "$iface")
    if [[ -n $addr ]]; then
      ok "IPv4: $addr"
      ip route show default dev "$iface" 2>/dev/null | sed 's/^/  /' || true
      if net_test "$iface"; then
        ok "Internet via $iface works"
      else
        warn "No internet through $iface yet (is Personal Hotspot on?)"
      fi
    else
      warn "No IP yet — enable Personal Hotspot on the phone (Allow Others to Join)"
    fi
  else
    warn "No tether interface — phone unplugged, untrusted, or hotspot off"
  fi
}

cmd_priority() {
  [[ -f $NETFILE ]] || die "Not installed — run: $0 install"
  case ${1:-} in
    high)
      write_netfile "$METRIC_PREFERRED" || die "Could not write $NETFILE."
      reload_networkd || die "networkd reload failed."
      ok "Tether now PREFERRED (metric $METRIC_PREFERRED) — traffic routes via the phone when plugged in"
      ;;
    low)
      write_netfile "$METRIC_FALLBACK" || die "Could not write $NETFILE."
      reload_networkd || die "networkd reload failed."
      ok "Tether now FALLBACK (metric $METRIC_FALLBACK) — ethernet/wifi win when available"
      ;;
    "")
      say "Current metric: $(current_metric)  (ethernet=100, wifi=600)"
      say "Usage: $0 priority <high|low>"
      ;;
    *)
      die "Unknown priority '$1' — use high or low."
      ;;
  esac
}

cmd_uninstall() {
  as_root rm -f "$NETFILE"
  rm -f "$DESKTOP_FILE"
  remove_windowrules || warn "Windowrule removal skipped — see above."
  as_root networkctl reload
  # elephant/Walker not used on HyperWebster
  ok "Removed $NETFILE, the launcher and windowrules (usbmuxd/libimobiledevice left installed)"
}

# ----------------------------------------------------------------- TUI -----

# Foot spawns TUI.float windows at 80 cols and snaps to real geometry over
# ~40ms; render before that settles and gum boxes fragment. Poll until two
# consecutive width reads agree (max 250ms).
poll_terminal_size() {
  local prev curr i
  prev=$(tput cols 2>/dev/null || echo 80)
  for i in 1 2 3 4 5 6 7 8 9 10; do
    sleep 0.025
    curr=$(tput cols 2>/dev/null || echo 80)
    [[ $curr == "$prev" && $i -ge 2 ]] && return 0
    prev=$curr
  done
}

# Visible length of a string (ANSI codes stripped; multibyte-aware).
vis_len() {
  local s
  s=$(printf '%s' "$1" | sed 's/\x1b\[[0-9;]*m//g')
  printf '%s' "${#s}"
}

# Print a line horizontally centered in the terminal. Uses $TW (measured
# once per redraw) — tput inside redirected loops can misread the width.
center_line() {
  local pad
  pad=$(( (${TW:-80} - $(vis_len "$1")) / 2 ))
  (( pad < 0 )) && pad=0
  printf '%*s%s\n' "$pad" '' "$1"
}

tui_header() {
  local line
  while IFS= read -r line; do
    center_line "$line"
  done < <(gum style --border rounded --padding "0 2" --align center \
             --border-foreground 212 --bold "  HYPERWEBSTER · omatether" "${DIM}HyperWebster · iPhone USB internet${RST}")
  echo
}

# Wait for Enter so warnings aren't wiped by the next dashboard redraw.
pause() { gum input --placeholder "Press Enter to continue…" >/dev/null || true; }

tui_connect() {
  say ""
  if ! phone_visible; then
    if phone_on_usb; then revive_usbmuxd || true; fi
  fi
  if ! phone_visible; then
    # shellcheck disable=SC2016  # expansion happens in the child shell
    gum spin --title "Plug the iPhone in via USB…" -- bash -c \
      'for i in $(seq 1 24); do idevice_id -l 2>/dev/null | grep -q . && exit 0; sleep 5; done; exit 1' \
      || { warn "No iPhone appeared. Check the cable and try again."; pause; return 1; }
  fi

  if ! phone_paired; then
    say "Unlock the phone and tap ${GRN}Trust${RST} when the dialog appears."
    idevicepair pair >/dev/null 2>&1 || true   # trigger the Trust dialog
    # shellcheck disable=SC2016  # expansion happens in the child shell
    gum spin --title "Waiting for Trust… (unlock the phone)" -- bash -c \
      'for i in $(seq 1 24); do idevicepair pair >/dev/null 2>&1 && exit 0; sleep 5; done; exit 1' \
      || { warn "Pairing timed out. Unlock the phone and pick Connect again."; pause; return 1; }
    ok "Paired with $(phone_name)"
  fi

  # Poll for the connection — first plug-in after a reboot can take 20-30s
  # (functions exported so the gum spin child shell can run them).
  local iface=""
  export -f tether_wait tether_iface tether_ip net_test
  if gum spin --title "Bringing the connection up… (can take ~30s after a reboot)" -- \
       bash -c 'tether_wait 45'; then
    iface=$(tether_iface || true)
    ok "Connected — internet available through the phone (${iface:-tether})"
  else
    warn "Paired, but the phone hasn't offered a connection yet. Check:"
    say  "  • Settings → Personal Hotspot → Allow Others to Join: ON"
    say  "  • Unlock the phone once (needed after a phone restart)"
    say  "  • Still nothing? Unplug and replug the cable, then Connect again."
  fi
  pause
}

tui_switch() {
  local target=$1 iface metric=$METRIC_FALLBACK
  say ""
  [[ $target == phone ]] && metric=$METRIC_PREFERRED
  write_netfile "$metric" || { warn "Could not update $NETFILE (sudo declined?)"; pause; return 1; }
  reload_networkd || { warn "networkd reload failed."; pause; return 1; }
  gum spin --title "Applying routes…" -- sleep 3 || true

  local uplink
  uplink=$(active_uplink)
  iface=$(tether_iface || true)
  if [[ -n $uplink && $target == phone && $uplink == "$iface" ]]; then
    ok "All traffic now routes via the iPhone ($iface)"
  elif [[ -n $uplink && $target == normal && $uplink != "$iface" ]]; then
    ok "Back to normal — traffic routes via $uplink"
  else
    warn "Route didn't settle as expected (uplink: ${uplink:-none}). Check Status."
  fi
  pause
}

cmd_tui() {
  command -v gum >/dev/null || die "gum is required for the TUI — run: $0 install"
  poll_terminal_size

  while true; do
    TW=$(tput cols 2>/dev/null || echo 80)
    clear
    tui_header

    # --- gather state ---
    local iface="" addr="" uplink="" metric mode phone_line tether_line uplink_line
    local connected=false paired=false
    metric=$(current_metric || true)
    mode="fallback"; [[ $metric == "$METRIC_PREFERRED" ]] && mode="preferred"
    iface=$(tether_iface || true)
    [[ -n $iface ]] && addr=$(tether_ip "$iface")
    uplink=$(active_uplink)

    if phone_visible; then
      paired=false; phone_paired && paired=true
      if $paired; then
        phone_line="${GRN}${RST}  $(phone_name) — paired"
      else
        phone_line="${YLW}${RST}  iPhone detected — not trusted yet"
      fi
    elif phone_on_usb; then
      phone_line="${YLW}${RST}  iPhone on USB — not responding (will retry)"
    else
      phone_line="${DIM}  No iPhone plugged in${RST}"
    fi

    if [[ -n $iface && -n $addr ]]; then
      connected=true
      tether_line="${GRN}󰛳${RST}  Tether up: $iface  $addr"
    elif [[ -n $iface ]]; then
      tether_line="${YLW}󰛳${RST}  Interface $iface up, no IP (hotspot off?)"
    else
      tether_line="${DIM}󰛳  No tether connection${RST}"
    fi

    if [[ -n $uplink && $uplink == "$iface" ]]; then
      uplink_line="${GRN}${RST}  Internet via iPhone"
    elif [[ -n $uplink ]]; then
      uplink_line="󰈀  Internet via $uplink ${DIM}(phone is $mode)${RST}"
    else
      uplink_line="${RED}󰈂${RST}  No internet route"
    fi

    center_line "$phone_line"
    center_line "$tether_line"
    center_line "$uplink_line"
    echo

    # --- context-aware menu ---
    local -a menu=()
    [[ -f $NETFILE ]] || menu+=("Install tethering support")
    if ! $connected; then
      menu+=("Connect phone")
    fi
    if $connected && [[ $uplink != "$iface" ]]; then
      menu+=("Switch internet → iPhone")
    fi
    if [[ $mode == preferred ]]; then
      menu+=("Switch back → ethernet/wifi")
    fi
    menu+=("Status (full check)" "Refresh" "Quit")

    # Center the menu as a block: pad every label by a common offset
    # (2 extra cols account for gum's cursor prefix).
    local maxlen=0 mpad m
    for m in "${menu[@]}"; do (( ${#m} > maxlen )) && maxlen=${#m}; done
    mpad=$(( (TW - maxlen) / 2 - 2 )); (( mpad < 0 )) && mpad=0
    local -a pmenu=()
    for m in "${menu[@]}"; do pmenu+=("$(printf '%*s%s' "$mpad" '' "$m")"); done

    local choice
    choice=$(gum choose --header "$(printf '%*s%s' "$((mpad + 2))" '' 'What do you want to do?')" "${pmenu[@]}") || break
    choice=${choice#"${choice%%[![:space:]]*}"}   # trim the centering pad
    # Every action is guarded with || true: a non-zero return from a bare
    # call here would trip set -e and close the TUI window without a trace.
    case $choice in
      "Install tethering support")      cmd_install || true; pause ;;
      "Connect phone")                  tui_connect || true ;;
      "Switch internet → iPhone")       tui_switch phone || true ;;
      "Switch back → ethernet/wifi")    tui_switch normal || true ;;
      "Status (full check)")            say ""; cmd_status || true; pause ;;
      "Refresh")                        ;;
      "Quit"|"")                        break ;;
    esac
  done
}

# ---------------------------------------------------------------- main -----

case ${1:-tui} in
  tui)       cmd_tui ;;
  install)   cmd_install ;;
  pair)      cmd_pair ;;
  unpair)    cmd_unpair ;;
  status)    cmd_status ;;
  priority)  shift; cmd_priority "${1:-}" ;;
  uninstall) cmd_uninstall ;;
  help|-h|--help)
    sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
    ;;
  *) die "Unknown command: $1 (try: $0 help)" ;;
esac
