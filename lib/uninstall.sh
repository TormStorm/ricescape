# shellcheck shell=bash
# Uninstall: Death walks you back out of Gielinor.
# Reverses every install step. Packages are only removed if ricescape added them.

PKG_BEFORE_FILE() { printf '%s/packages-before.txt' "$RS_STATE"; }
PKG_ADDED_FILE()  { printf '%s/packages-added.txt' "$RS_STATE"; }

# Called before the first package install. Keeps the oldest snapshot.
snapshot_packages_before() {
    ensure_state_dir
    [[ -f $(PKG_BEFORE_FILE) ]] || pacman -Qqe | sort >"$(PKG_BEFORE_FILE)"
}

# Called after package installs: records which of OUR packages were not on the
# system before. Packages the user installs themselves are never recorded.
record_added_packages() {
    [[ -f $(PKG_BEFORE_FILE) ]] || return 0
    local candidates p
    candidates="$( {
        read_list "$RS_REPO/packages/pacman.txt"
        read_list "$RS_REPO/packages/aur.txt"
        printf '%s\n' git base-devel gum jq stow paru-bin runelite
        if [[ -f $(PKG_ADDED_FILE) ]]; then cat "$(PKG_ADDED_FILE)"; fi
    } | sort -u )"
    while IFS= read -r p; do
        [[ -n $p ]] || continue
        pacman -Qq "$p" >/dev/null 2>&1 || continue
        if ! grep -qxF "$p" "$(PKG_BEFORE_FILE)"; then printf '%s\n' "$p"; fi
    done <<<"$candidates" >"$(PKG_ADDED_FILE).tmp"
    mv "$(PKG_ADDED_FILE).tmp" "$(PKG_ADDED_FILE)"
}

latest_backup() {
    find "$RS_STATE/backups" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | tail -n1
}

remove_rendered_files() {
    local rel target
    while IFS= read -r rel; do
        target="$HOME/$rel"
        if [[ -f $target ]] && grep -q 'ricescape:managed' "$target" 2>/dev/null; then
            rm -f "$target"
        fi
    done < <(template_targets)
}

remove_profile_blocks() {
    local f
    for f in "$HOME/.bash_profile" "$HOME/.zprofile" "$HOME/.profile"; do
        if [[ -f $f ]]; then sed -i '/^# >>> ricescape >>>$/,/^# <<< ricescape <<<$/d' "$f"; fi
    done
}

restore_backup() {
    local dir="$1"
    (cd "$dir" && find . -type f -o -type l) | sed 's|^\./||' | while IFS= read -r rel; do
        if [[ -e $HOME/$rel || -L $HOME/$rel ]]; then
            warn "Not restoring $rel: a file already exists there."
            continue
        fi
        mkdir -p "$HOME/$(dirname "$rel")"
        mv "$dir/$rel" "$HOME/$rel"
    done
}

run_uninstall() {
    require_arch

    npc_say "Death" \
        "Hello, mortal. So you wish to leave Gielinor? I can take you back to where you came from."
    if ! npc_confirm "Death" yes "Remove Ricescape from this system?"; then
        npc_say "Death" "Another time, then. I'll be waiting."
        return 0
    fi

    pkill -x quickshell 2>/dev/null || true

    info "Unlinking configs"
    if have stow && [[ -d $RS_REPO/home ]]; then
        stow --dir="$RS_REPO" --target="$HOME" --delete home || warn "stow could not unlink everything."
    fi
    remove_rendered_files
    remove_profile_blocks
    if [[ -L $RS_BIN_LINK ]]; then rm -f "$RS_BIN_LINK"; fi

    local backup
    backup="$(latest_backup)"
    if [[ -n $backup ]] && npc_confirm "Death" yes \
        "I kept the belongings you had before you arrived, in $(basename "$backup"). Shall I give them back?"; then
        restore_backup "$backup"
        info "Restored your previous configs from $backup"
    fi

    if [[ -s $(PKG_ADDED_FILE) ]]; then
        local pkgs
        mapfile -t pkgs <"$(PKG_ADDED_FILE)"
        if dlg_interactive; then
            npc_box "Death" "Ricescape installed these packages, which weren't on your system before: ${pkgs[*]}"
        else
            info "Packages added by Ricescape (kept; run 'ropes uninstall' interactively to remove them): ${pkgs[*]}"
        fi
        if npc_confirm "Death" no "Shall I take those packages too? (Things you installed yourself are left alone.)"; then
            # Only remove what is still installed; skip anything something else now needs.
            local installed=() p
            for p in "${pkgs[@]}"; do
            if pacman -Qq "$p" >/dev/null 2>&1; then installed+=("$p"); fi
        done
            if ((${#installed[@]})); then
                if ! sudo pacman -Rns --noconfirm "${installed[@]}"; then
                    # Something still needs part of the set: remove what we can, one by one.
                    for p in "${installed[@]}"; do
                        sudo pacman -Rns --noconfirm "$p" >/dev/null 2>&1 \
                            || warn "Kept $p: other software still needs it."
                    done
                fi
            fi
        fi
    fi

    if npc_confirm "Death" no "Shall I also forget your mode, settings and backups? ($RS_STATE)"; then
        rm -rf "$RS_STATE"
    fi

    local default_dest="$HOME/.local/share/ricescape"
    if [[ $RS_REPO == "$default_dest" ]] && npc_confirm "Death" no "And the ricescape files themselves, in $RS_REPO?"; then
        rm -rf "$RS_REPO"
    fi

    npc_say "Death" "It is done. You are free to go. Your next session will start without Ricescape."
    info "Ricescape has been removed. Log out to leave Niri."
}
