#!/usr/bin/env bash
# Ricescape bootstrap.
#
#   curl -fsSL https://raw.githubusercontent.com/TormStorm/ricescape/main/install.sh | bash
#
# Remove everything again (from a clone: ./install.sh --uninstall):
#   curl -fsSL https://raw.githubusercontent.com/TormStorm/ricescape/main/install.sh | bash -s -- --uninstall
#
# Installs the few tools the installer needs, fetches the repo into
# ~/.local/share/ricescape (or uses this clone), and hands over to `ropes`.
set -euo pipefail

REPO_URL="${RICESCAPE_REPO:-https://github.com/TormStorm/ricescape.git}"
BRANCH="${RICESCAPE_BRANCH:-main}"
DEST="${RICESCAPE_DIR:-$HOME/.local/share/ricescape}"

say() { printf '\e[38;2;255;255;0m»\e[0m %s\n' "$*"; }
die() { printf '\e[38;2;220;60;50mOh dear, you are dead!\e[0m %s\n' "$*" >&2; exit 1; }

[[ -f /etc/arch-release ]] || die "Ricescape only supports Arch Linux (btw)."
[[ $EUID -ne 0 ]] || die "Run this as your normal user, not root. It will ask for sudo when needed."
command -v sudo >/dev/null || die "sudo is not installed."

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/ricescape"

SELF_DIR=""
if [[ -n ${BASH_SOURCE[0]:-} && -f ${BASH_SOURCE[0]} ]]; then
    SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Hands control to ropes, giving it the terminal even when piped from curl.
run_ropes() {
    local ropes="$1"; shift
    if [[ -r /dev/tty ]]; then
        exec "$ropes" "$@" </dev/tty
    else
        exec "$ropes" "$@" --skip-dialogue
    fi
}

if [[ ${1:-} == --uninstall || ${1:-} == uninstall ]]; then
    shift
    for candidate in "$SELF_DIR/bin/ropes" "$DEST/bin/ropes"; do
        [[ -x $candidate ]] && run_ropes "$candidate" uninstall "$@"
    done
    die "Ricescape doesn't seem to be installed (no ropes found in $DEST)."
fi

say "Welcome to Ricescape. Preparing Tutorial Island..."

# Remember what was installed before, so uninstall only removes what we add.
mkdir -p "$STATE"
[[ -f $STATE/packages-before.txt ]] || pacman -Qqe | sort >"$STATE/packages-before.txt"

sudo pacman -Syu --needed --noconfirm git base-devel gum jq stow

# Running from a local clone? Use it instead of cloning again.
if [[ -n $SELF_DIR && -x $SELF_DIR/bin/ropes ]]; then
    DEST="$SELF_DIR"
    say "Using the local clone at $DEST"
elif [[ -d $DEST/.git ]]; then
    say "Updating $DEST"
    git -C "$DEST" pull --ff-only
else
    say "Cloning ricescape into $DEST"
    mkdir -p "$(dirname "$DEST")"
    git clone --branch "$BRANCH" "$REPO_URL" "$DEST"
fi

mkdir -p "$HOME/.local/bin"
ln -sfn "$DEST/bin/ropes" "$HOME/.local/bin/ropes"

run_ropes "$DEST/bin/ropes" install "$@"
