#!/bin/bash

rd="\e[91m"   # Red (bright)
gr="\e[92m"   # Green (bright)
yl="\e[33m"   # Yellow
bl="\e[1;94m" # Blue (bold & bright)
rst="\e[0m"

if [ "$(id -u)" -ne 0 ]; then
  echo -e "$yl[!] This script must be run as root$rst" >&2
  exit 1
fi

usage_msg="Usage: $0 {enable|disable|start|stop|enstart|distop|status} [service1 service2 ...]"

if [ "$#" -lt 1 ]; then
  echo "$usage_msg" >&2
  exit 3
fi

# Handle user input
action_input="$1"
shift
svc_input=("$@")

# Action input validation
actions='enable|disable|start|stop|enstart|distop|status'
if [[ ! "$action_input" =~ ^($actions)$ ]]; then
  echo -e "$rd[⨯] Invalid input: $action_input.\n$usage_msg $rst" >&2
  exit 3
fi

# Add your services below
# e.g. default_svcs=('service1' 'service2')
default_svcs=()

# Append service input to svcs
if [ "${#svc_input[@]}" -gt 0 ]; then
  svcs+=("${default_svcs[@]}")
  # Check duplicate service
  for svc in "${svc_input[@]}"; do
    if [[ ! " ${svcs[@]} " =~ " $svc " ]]; then
      svcs+=("$svc")
    fi
  done

else
  svcs+=("${default_svcs[@]}")
fi

# Operation variables
start_op=false
ops=false

start_svc() {
  local svc_name="$1"

  if [ "$is_active" == "inactive" ]; then
    systemctl start "$svc_name"
    echo -e "$gr| [✓] $svc_name has been started.     |"
    start_op=true
  else
    echo -e "|$yl [!] $svc_name is already running.   $gr|"
  fi
}

stop_svc() {
  local svc_name="$1"

  if [ "$is_active" == "active" ]; then
    systemctl stop "$svc_name"
    echo -e "$gr| [✓] $svc_name has been stopped.     |"
    ops=true
  else
    echo -e "|$yl [!] $svc_name is not running.       $gr|"
  fi
}

enable_svc() {
  local svc_name="$1"

  if [ "$is_enabled" == "disabled" ]; then
    systemctl enable -q "$svc_name"
    echo -e "$gr| [✓] $svc_name has been enabled.     |"
    ops=true
  else
    echo -e "|$yl [!] $svc_name is already enabled.   $gr|"
  fi
}

disable_svc() {
  local svc_name="$1"

  if [ "$is_enabled" == "enabled" ]; then
    systemctl disable -q "$svc_name"
    echo -e "$gr| [✓] $svc_name has been disabled.    |"
    ops=true
  else
    echo -e "|$yl [!] $svc_name is already disabled.  $gr|"
  fi
}

status_svc() {
  local svc_name="$1"

  if [ "$is_active" == "active" ]; then
    echo -e "$gr| [✓] $svc_name is currently active   |"
  elif [ "$is_active" == "inactive" ]; then
    echo -e "|$yl [!] $svc_name is currently inactive $gr|"
  else
    echo -e "|$rd [⨯] $svc_name active status error   $gr|"
  fi

  if [ "$is_enabled" == "enabled" ]; then
    echo -e "$gr| [✓] $svc_name is currently enabled  |"
  elif [ "$is_enabled" == "disabled" ]; then
    echo -e "|$yl [!] $svc_name is currently disabled $gr|"
  else
    echo -e "|$rd [⨯] $svc_name loaded status error   $gr|"
  fi
}

enstart_svc() {
  local svc_name="$1"
  
  enable_svc "$svc_name"
  start_svc "$svc_name"
}

distop_svc() {
  local svc_name="$1"

  disable_svc "$svc_name"
  stop_svc "$svc_name"
}

manage_svc() {
  local action="$1"
  local svc_name="$2"

  echo -e "$gr+------------{$bl $svc $rst$gr}------------+"

  case "$action" in
  'enable') enable_svc "$svc_name" ;;
  'disable') disable_svc "$svc_name" ;;
  'start') start_svc "$svc_name" ;;
  'stop') stop_svc "$svc_name" ;;
  'enstart') enstart_svc "$svc_name" ;;
  'distop') distop_svc "$svc_name" ;;
  'status') status_svc "$svc_name" ;;
  *)
    echo -e "$rd[⨯] Invalid input: $action.\n$usage_msg $rst" >&2
    exit 3
    ;;
  esac

  echo -e "+$(printf -- '-%.0s' $(seq $((28 + $(echo -n "$svc_name" | wc -c)))))+\n"
}

# Check service existence
err_svcs=()
for svc in "${svcs[@]}"; do
  err="$(systemctl is-enabled "$svc" 2>&1 >/dev/null)"

  if [ -z "$err" ]; then
    is_active="$(systemctl is-active $svc)"
    is_enabled="$(systemctl is-enabled $svc)"
    manage_svc "$action_input" "$svc"
  else
    err_svcs+=("$svc")
    echo -e "$rd+----------{$bl $svc $rst$rd}-----------+"
    echo -e "| [⨯] $svc service not found. |" >&2
    echo -e "+$(printf -- '-%.0s' $(seq $((25 + $(echo -n "$svc" | wc -c)))))+\n"
  fi
done

# Reload daemon
if [ "$start_op" = true ]; then
  systemctl daemon-reload
  echo -e "$gr+------(daemon)-------+\n| [✓] Daemon Reloaded |"
  echo -e "+$(printf -- '-%.0s' {1..21})+$rst\n"
fi

# Invalid services (List them if any)
if [ "${#err_svcs[@]}" -gt 0 ]; then
  echo -e "$rd[⨯] Invalid services: (${#err_svcs[@]})" >&2
  for i in "${!err_svcs[@]}"; do
    echo -e "$rd - ${err_svcs[$i]}$rst" >&2
  done
  exit 4

# Valid services
elif [[ "$start_op" == false && "$ops" == false && "$action_input" != 'status' ]]; then
  exit 5
else
  exit 0
fi
