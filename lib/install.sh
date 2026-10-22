# shellcheck shell=bash
# The Learning the Ropes installer: one NPC per step, every step safe to re-run.

aur_helper() {
    if have paru; then echo paru
    elif have yay; then echo yay
    fi
}

detect_keyboard_layout() {
    local layout=""
    if have localectl; then
        layout="$(localectl status 2>/dev/null | awk -F': *' '/X11 Layout/ {print $2; exit}')"
        if [[ -z $layout ]]; then
            layout="$(localectl status 2>/dev/null | awk -F': *' '/VC Keymap/ {print $2; exit}')"
            layout="${layout%%-*}"
            [[ $layout == n/a ]] && layout=""
        fi
    fi
    printf '%s' "${layout:-us}"
}

detect_ui_font() {
    local font=""
    if have fc-list; then
        font="$(fc-list : family | grep -i 'runescape' | head -n1 | cut -d, -f1)"
    fi
    printf '%s' "${font:-JetBrainsMono Nerd Font}"
}

# --- Step 1: Gielinor Guide ----------------------------------------------------

step_gielinor_guide() {
    npc_say "Gielinor Guide" \
        "Greetings! I see you are a new player. Welcome to Ricescape, the most Old School desktop in all of Gielinor. Before you can leave this island, I must teach you the ropes."

    if ! npc_confirm "Gielinor Guide" yes \
        "This will install a Niri desktop with an OSRS-style interface on this Arch install. Shall we begin?"; then
        npc_say "Gielinor Guide" "Very well. Come back and talk to me whenever you're ready. Just run 'ropes'."
        exit 0
    fi

    local detected layout
    detected="$(settings_get keyboard_layout "$(detect_keyboard_layout)")"
    layout="$(npc_input "Gielinor Guide" \
        "First things first. Which keyboard layout do you use? (An xkb layout such as us, gb, no, de.)" \
        "$detected")"
    settings_set keyboard_layout "$layout"
    info "Keyboard layout: $layout"
}

# --- Step 2: Survival Expert -------------------------------------------------

step_survival_expert() {
    npc_say "Survival Expert" \
        "Every adventurer needs the basics to survive out there: a compositor, a terminal, sound, a network connection. I'll gather them from the official repositories. You'll need to enter your password for sudo."

    local pkgs
    mapfile -t pkgs < <(read_list "$RS_REPO/packages/pacman.txt")
    info "Installing ${#pkgs[@]} packages with pacman"
    sudo pacman -Syu --needed --noconfirm "${pkgs[@]}" || die "pacman could not install the packages."
}

# --- Step 3: Master Chef -----------------------------------------------------

step_master_chef() {
    local helper
    helper="$(aur_helper)"

    if [[ -z $helper ]]; then
        npc_say "Master Chef" \
            "Ah, a fresh face! Some recipes aren't in the official cookbook. For those we need an AUR helper. I'll cook you up some paru from source."
        local build
        build="$(mktemp -d)"
        info "Building paru-bin from the AUR"
        git clone --depth 1 https://aur.archlinux.org/paru-bin.git "$build/paru-bin" \
            || die "Could not download paru-bin from the AUR."
        (cd "$build/paru-bin" && makepkg -si --noconfirm) || die "Building paru failed."
        rm -rf "$build"
        helper=paru
    else
        npc_say "Master Chef" "I see you already have $helper in your kitchen. Excellent, we'll cook with that."
    fi

    local pkgs
    mapfile -t pkgs < <(read_list "$RS_REPO/packages/aur.txt")

    if npc_confirm "Master Chef" no \
        "Would you like me to add RuneLite to the menu as well? It's the popular third-party OSRS client, from the AUR."; then
        pkgs+=(runelite)
    fi

    if ((${#pkgs[@]})); then
        info "Installing ${#pkgs[@]} AUR package(s) with $helper"
        "$helper" -S --needed --noconfirm "${pkgs[@]}" || die "$helper could not install the AUR packages."
    fi
}

# --- Step 4: Mining Instructor -------------------------------------------------

step_mining_instructor() {
    local font
    font="$(detect_ui_font)"
    settings_set ui_font "$font"
    settings_set mono_font "$(settings_get mono_font 'JetBrainsMono Nerd Font')"

    if [[ $font == *[Rr]une[Ss]cape* ]]; then
        npc_say "Mining Instructor" \
            "I've prospected your system and struck gold: the '$font' font is installed. The interface will use it."
    else
        npc_say "Mining Instructor" \
            "I've prospected your system, but there's no RuneScape font ore here. Ricescape can't ship it for you. If you find a fan-made OSRS font, drop the .ttf into ~/.local/share/fonts and run 'ropes apply'. Until then I'll use JetBrains Mono."
    fi
}

# --- Step 5: Combat Instructor -------------------------------------------------

# Files that ricescape will own: stowed files plus rendered templates.
managed_targets() {
    (cd "$RS_REPO/home" && find . \( -type f -o -type l \) | sed 's|^\./||' | sort)
    template_targets
}

step_combat_instructor() {
    local backup rel target moved=0
    backup="$RS_STATE/backups/$(date +%Y%m%d-%H%M%S)"

    while IFS= read -r rel; do
        target="$HOME/$rel"
        [[ -e $target || -L $target ]] || continue
        # Already ours: a symlink into the repo, or a file we rendered.
        if [[ -L $target && $(readlink -f "$target") == "$RS_REPO"/* ]]; then continue; fi
        if [[ -f $target && ! -L $target ]] && grep -q 'ricescape:managed' "$target" 2>/dev/null; then continue; fi
        mkdir -p "$backup/$(dirname "$rel")"
        mv "$target" "$backup/$rel"
        moved=$((moved + 1))
    done < <(managed_targets)

    if ((moved)); then
        npc_say "Combat Instructor" \
            "Never fight without a backup plan. I've moved $moved of your existing config files out of harm's way, into $backup."
    else
        npc_say "Combat Instructor" \
            "I checked your configs for anything that could be lost in battle. Nothing in the way, so we're clear to fight."
    fi
}

# --- Step 6: Account Guide -----------------------------------------------------

profile_block() {
    cat <<'EOF'
# >>> ricescape >>>
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac
if [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = /dev/tty1 ] && command -v niri-session >/dev/null; then
    exec niri-session
fi
# <<< ricescape <<<
EOF
}

path_block() {
    cat <<'EOF'
# >>> ricescape >>>
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac
# <<< ricescape <<<
EOF
}

# write_block FILE CONTENT — replaces any existing ricescape block.
write_block() {
    local file="$1" block="$2"
    if [[ ! -f $file && $(basename "$file") == .bash_profile ]]; then
        # Same as Arch's /etc/skel/.bash_profile, so .bashrc still loads.
        printf '%s\n' '[[ -f ~/.bashrc ]] && . ~/.bashrc' >"$file"
    fi
    touch "$file"
    sed -i '/^# >>> ricescape >>>$/,/^# <<< ricescape <<<$/d' "$file"
    printf '\n%s\n' "$block" >>"$file"
}

step_account_guide() {
    npc_say "Account Guide" \
        "Let me set up your account. I'll link the ricescape configs into place and put the 'ropes' command on your path."

    mkdir -p "$HOME/.local/bin" "$HOME/.config"
    ln -sfn "$RS_REPO/bin/ropes" "$RS_BIN_LINK"

    info "Linking configs with stow"
    stow --no-folding --dir="$RS_REPO" --target="$HOME" --restow home \
        || die "stow found conflicts. Run 'ropes install' again so the Combat Instructor can back them up."

    # Network: only enable NetworkManager when nothing else manages the network.
    if systemctl is-enabled --quiet NetworkManager 2>/dev/null; then
        :
    elif systemctl is-active --quiet systemd-networkd 2>/dev/null || systemctl is-active --quiet iwd 2>/dev/null; then
        warn "systemd-networkd or iwd is running, so NetworkManager was left disabled."
    elif npc_confirm "Account Guide" yes "Shall I enable NetworkManager so you can manage Wi-Fi from the desktop?"; then
        sudo systemctl enable --now NetworkManager || warn "Could not enable NetworkManager."
    fi
    sudo systemctl enable bluetooth >/dev/null 2>&1 || true

    local shell_rc
    case "$(basename "${SHELL:-bash}")" in
        zsh) shell_rc="$HOME/.zprofile" ;;
        *)   shell_rc="$HOME/.bash_profile" ;;
    esac

    local choice
    choice="$(npc_choose "Account Guide" "How would you like to log in to Gielinor?" \
        "Start Niri automatically when I log in on tty1." \
        "I'll start it myself with niri-session, or I use a display manager.")"
    if [[ $choice == Start* ]]; then
        write_block "$shell_rc" "$(profile_block)"
        info "Niri will start when you log in on tty1 ($shell_rc)"
    else
        write_block "$shell_rc" "$(path_block)"
    fi
}

# --- Step 7: Brother Brace -----------------------------------------------------

step_brother_brace() {
    npc_say "Brother Brace" \
        "Greetings. Let me teach you the quick prayers of this desktop. Super+Return opens a terminal, Super+D opens your inventory of apps, and Super+Q closes a window."
    npc_say "Brother Brace" \
        "Super+Left and Super+Right scroll between columns, Super+1 to 9 switch worlds, Super+M lets you talk to the Ironman tutor, and Super+Escape opens the logout panel. Super+Shift+Slash shows every bind."
}

# --- Step 8: Ironman tutor -----------------------------------------------------

choose_mode_dialogue() {
    local options=() m
    for m in "${RS_MODES[@]}"; do options+=("$(mode_display_name "$m")"); done

    local current choice
    current="$(current_mode)"
    npc_say "Ironman tutor" \
        "Hello, adventurer. I'm the Ironman tutor. I decide what restrictions your desktop lives by. Each mode comes with its own colours."
    choice="$(npc_choose "Ironman tutor" \
        "You're currently playing as $(mode_display_name "$current"). Which mode would you like?" "${options[@]}")"

    for m in "${RS_MODES[@]}"; do
        if [[ $(mode_display_name "$m") == "$choice" ]]; then
            printf '%s\n' "$m"
            return
        fi
    done
    printf '%s\n' "$current"
}

step_ironman_tutor() {
    local mode
    mode="$(choose_mode_dialogue)"
    case "$mode" in
        hardcore | hardcore-group)
            npc_say "Ironman tutor" \
                "Hardcore, eh? In the game you only get one life. For now your desktop is spared, but I'll be watching." ;;
        normal)
            npc_say "Ironman tutor" "A regular account? Fair enough. Trade, bank, live a little." ;;
        *)
            npc_say "Ironman tutor" "Very well. Stand alone, gather your own loot, and remember: you use Arch, btw." ;;
    esac
    apply_mode "$mode"
}

# --- Step 9: Magic Instructor --------------------------------------------------

step_magic_instructor() {
    npc_say "Magic Instructor" \
        "Well done, you've learned the ropes! Before you go, a last tip: run 'ropes update' to update everything, and 'ropes mode' to change modes at any time."

    if [[ -n ${WAYLAND_DISPLAY:-} ]]; then
        npc_say "Magic Instructor" \
            "You're already in a graphical session. Log out and start Niri to see your new home. Off you go, to Lumbridge!"
        return
    fi

    local choice
    choice="$(npc_choose "Magic Instructor" "Shall I teleport you to Lumbridge?" \
        "Yes, start Niri now." \
        "Reboot first." \
        "Not yet, I'll stay here.")"
    case "$choice" in
        Yes*)    exec niri-session ;;
        Reboot*) sudo systemctl reboot ;;
        *)       info "Run 'niri-session' when you're ready." ;;
    esac
}

# --- Entry points ------------------------------------------------------------

run_install() {
    require_arch
    ensure_state_dir
    have gum || dim "Tip: install gum for the full NPC dialogue experience."

    step_gielinor_guide
    snapshot_packages_before
    step_survival_expert
    step_master_chef
    record_added_packages
    step_mining_instructor
    step_combat_instructor
    step_account_guide
    step_brother_brace
    step_ironman_tutor
    step_magic_instructor
}

run_update() {
    require_arch
    ensure_state_dir
    npc_say "Gielinor Guide" "Welcome back! Let me see what's new in Gielinor."

    if git -C "$RS_REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        info "Pulling the latest ricescape"
        git -C "$RS_REPO" pull --ff-only || warn "Could not fast-forward. Your local repo has changes, so it was left alone."
    fi

    local pkgs helper
    mapfile -t pkgs < <(read_list "$RS_REPO/packages/pacman.txt")
    sudo pacman -Syu --needed --noconfirm "${pkgs[@]}" || die "pacman could not install the packages."

    helper="$(aur_helper)"
    mapfile -t pkgs < <(read_list "$RS_REPO/packages/aur.txt")
    if [[ -n $helper ]]; then
        "$helper" -Sua --noconfirm || warn "$helper could not update AUR packages."
        if ((${#pkgs[@]})); then
            "$helper" -S --needed --noconfirm "${pkgs[@]}" || warn "$helper could not install the AUR packages."
        fi
    fi

    record_added_packages
    step_combat_instructor
    stow --no-folding --dir="$RS_REPO" --target="$HOME" --restow home || die "stow found conflicts."
    apply_mode "$(current_mode)" quiet
    info "Ricescape is up to date. You are a $(mode_display_name "$(current_mode)")."
}
