# shellcheck shell=bash
# NPC dialogue for ropes, styled after OSRS chat boxes.
# Uses gum when available; falls back to plain text otherwise.
# All dialogue UI goes to stderr so functions can return values on stdout.

RS_SKIP_DIALOGUE="${RS_SKIP_DIALOGUE:-0}"

DLG_NAME_COLOR='#FF981F'     # OSRS orange for NPC names
DLG_TEXT_COLOR='#E8DFC8'     # parchment-ish text
DLG_CONTINUE_COLOR='#5B9BFF' # the blue "Click here to continue"
DLG_BORDER_COLOR='#6B5E49'   # stone border
DLG_WIDTH=68

dlg_interactive() {
    [[ $RS_SKIP_DIALOGUE != 1 && -t 0 && -t 2 ]]
}

dlg_use_gum() {
    dlg_interactive && have gum
}

npc_slug() {
    tr '[:upper:] ' '[:lower:]-' <<<"$1"
}

npc_chathead() {
    local slug img
    slug="$(npc_slug "$1")"
    img="$RS_REPO/assets/chatheads/$slug.png"
    if [[ -f $img ]] && have chafa; then
        chafa --size 16x8 "$img" >&2 || true
    fi
}

npc_box() {
    local name="$1"; shift
    local text="$*"
    if dlg_use_gum; then
        npc_chathead "$name"
        gum style \
            --border thick --border-foreground "$DLG_BORDER_COLOR" \
            --padding "0 2" --width "$DLG_WIDTH" \
            "$(gum style --foreground "$DLG_NAME_COLOR" --bold "$name")" \
            "" \
            "$(gum style --foreground "$DLG_TEXT_COLOR" --width $((DLG_WIDTH - 6)) "$text")" >&2
    else
        printf '\n%s%s%s\n%s\n' "$C_ORANGE" "$name" "$C_RESET" "$text" | fold -s -w "$DLG_WIDTH" >&2
    fi
}

# npc_say "Name" "Text..."  — shows a line and waits for Enter.
npc_say() {
    dlg_interactive || return 0
    npc_box "$@"
    if have gum; then
        gum style --foreground "$DLG_CONTINUE_COLOR" "  Press Enter to continue" >&2
    else
        printf '  Press Enter to continue\n' >&2
    fi
    local _
    read -r -s _ || true
}

# npc_choose "Name" "Question" option...  — prints the chosen option.
# Non-interactive: prints the first option.
npc_choose() {
    local name="$1" question="$2"; shift 2
    if ! dlg_interactive; then
        printf '%s\n' "$1"
        return 0
    fi
    npc_box "$name" "$question"
    if have gum; then
        local choice
        choice="$(gum choose --header "Select an Option" --cursor "» " \
            --header.foreground "$DLG_NAME_COLOR" \
            --cursor.foreground "#FFFF00" --selected.foreground "#FFFF00" "$@")" \
            || die "You walk away from the conversation."
        printf '%s\n' "$choice"
    else
        local i=1 opt
        printf 'Select an Option\n' >&2
        for opt in "$@"; do printf '  %d. %s\n' "$i" "$opt" >&2; i=$((i + 1)); done
        local n
        while true; do
            read -r -p "> " n || die "You walk away from the conversation."
            if [[ $n =~ ^[0-9]+$ ]] && ((n >= 1 && n <= $#)); then
                printf '%s\n' "${!n}"
                return 0
            fi
        done
    fi
}

# npc_confirm "Name" yes|no "Question"  — returns 0 for yes.
# Non-interactive: uses the default.
npc_confirm() {
    local name="$1" default="$2" question="$3"
    if ! dlg_interactive; then
        [[ $default == yes ]]
        return
    fi
    local choice
    if [[ $default == yes ]]; then
        choice="$(npc_choose "$name" "$question" "Yes." "No.")"
    else
        choice="$(npc_choose "$name" "$question" "No." "Yes.")"
    fi
    [[ $choice == "Yes." ]]
}

# npc_input "Name" "Question" "default"  — prints the answer.
npc_input() {
    local name="$1" question="$2" default="$3"
    if ! dlg_interactive; then
        printf '%s\n' "$default"
        return 0
    fi
    npc_box "$name" "$question"
    local answer
    if have gum; then
        answer="$(gum input --value "$default" --prompt "» " \
            --prompt.foreground "#FFFF00")" || die "You walk away from the conversation."
    else
        read -r -p "» [$default] " answer || die "You walk away from the conversation."
    fi
    printf '%s\n' "${answer:-$default}"
}
