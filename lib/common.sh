# shellcheck shell=bash
# Shared paths and helpers for ropes. Sourced, never executed.

RS_REPO="${RS_REPO:?RS_REPO must be set by the caller}"
RS_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/ricescape"
RS_USER_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/ricescape"
RS_BIN_LINK="$HOME/.local/bin/ropes"

# OSRS-ish terminal colours for plain log lines.
if [[ -t 2 ]]; then
    C_YELLOW=$'\e[38;2;255;255;0m'
    C_ORANGE=$'\e[38;2;255;152;31m'
    C_RED=$'\e[38;2;220;60;50m'
    C_DIM=$'\e[2m'
    C_RESET=$'\e[0m'
else
    C_YELLOW='' C_ORANGE='' C_RED='' C_DIM='' C_RESET=''
fi

info() { printf '%s»%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
warn() { printf '%s!%s %s\n' "$C_ORANGE" "$C_RESET" "$*" >&2; }
die()  { printf '%sOh dear, you are dead!%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; exit 1; }
dim()  { printf '%s%s%s\n' "$C_DIM" "$*" "$C_RESET" >&2; }

have() { command -v "$1" >/dev/null 2>&1; }

require_arch() {
    [[ -f /etc/arch-release ]] || die "ricescape only supports Arch Linux (btw)."
    [[ $EUID -ne 0 ]] || die "Run ropes as your normal user, not root. It will ask for sudo when needed."
    have sudo || die "sudo is not installed. Install it and add your user to the wheel group first."
}

ensure_state_dir() {
    mkdir -p "$RS_STATE" "$RS_STATE/backups"
}

# --- settings.json (keyboard layout, fonts, ...) -----------------------------

settings_file() { printf '%s/settings.json' "$RS_STATE"; }

settings_get() {
    local key="$1" default="${2:-}" file
    file="$(settings_file)"
    if [[ -f $file ]]; then
        local value
        value="$(jq -r --arg k "$key" '.[$k] // empty' "$file")"
        [[ -n $value ]] && { printf '%s' "$value"; return; }
    fi
    printf '%s' "$default"
}

settings_set() {
    local key="$1" value="$2" file tmp
    ensure_state_dir
    file="$(settings_file)"
    [[ -f $file ]] || printf '{}\n' >"$file"
    tmp="$(mktemp "$RS_STATE/.settings.XXXXXX")"
    jq --arg k "$key" --arg v "$value" '.[$k] = $v' "$file" >"$tmp" && mv "$tmp" "$file"
}

# Reads a package list, dropping comments and blank lines.
read_list() {
    sed -e 's/#.*//' -e 's/[[:space:]]*$//' "$1" | grep -v '^[[:space:]]*$' || true
}
