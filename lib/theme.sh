# shellcheck shell=bash
# Mode resolution, palette merging, template rendering and live reload.

RS_MODES=(normal ironman ultimate hardcore group unranked hardcore-group)

# Maps any accepted name or shorthand to a canonical mode id.
resolve_mode() {
    case "${1,,}" in
        normal | main | regular)                    echo normal ;;
        ironman | im | iron)                        echo ironman ;;
        ultimate | uim | ultimate-ironman)          echo ultimate ;;
        hardcore | hcim | hardcore-ironman)         echo hardcore ;;
        group | gim | group-ironman)                echo group ;;
        unranked | ugim | unranked-group)           echo unranked ;;
        hardcore-group | hcgim | hardcore-group-ironman) echo hardcore-group ;;
        *) return 1 ;;
    esac
}

mode_display_name() {
    jq -r '.name' "$RS_REPO/palettes/$1.json"
}

current_mode() {
    local mode=""
    [[ -f $RS_STATE/mode ]] && mode="$(<"$RS_STATE/mode")"
    resolve_mode "${mode:-normal}" 2>/dev/null || echo normal
}

next_mode() {
    local cur i
    cur="$(current_mode)"
    for i in "${!RS_MODES[@]}"; do
        if [[ ${RS_MODES[$i]} == "$cur" ]]; then
            echo "${RS_MODES[$(((i + 1) % ${#RS_MODES[@]}))]}"
            return
        fi
    done
    echo normal
}

# Writes the merged palette (base + mode + settings + paths) as JSON.
build_palette_json() {
    local mode="$1"
    local settings='{}'
    [[ -f $(settings_file) ]] && settings="$(<"$(settings_file)")"
    jq -n \
        --slurpfile base "$RS_REPO/palettes/_base.json" \
        --slurpfile mode "$RS_REPO/palettes/$mode.json" \
        --argjson settings "$settings" \
        --arg home "$HOME" --arg repo "$RS_REPO" --arg state "$RS_STATE" \
        '($base[0] * $mode[0] * $settings * {home: $home, repo: $repo, state: $state})
         | .logo_path = (if .logo_type == "file"
                         then "\($repo)/assets/fastfetch/\(.logo).txt"
                         else .logo end)'
}

# Flattens palette JSON into KEY<TAB>VALUE lines, adding _hex/_rgb/_ansi
# variants for every #RRGGBB colour and resolving the fastfetch logo path.
palette_vars() {
    jq -r '
        to_entries[]
        | select(.value | type == "string" or type == "number" or type == "boolean")
        | [.key, (.value | tostring)] | @tsv
    ' <<<"$1" | while IFS=$'\t' read -r key value; do
        printf '%s\t%s\n' "$key" "$value"
        if [[ $value =~ ^#([0-9A-Fa-f]{6})$ ]]; then
            local hex="${BASH_REMATCH[1]}"
            printf '%s_hex\t%s\n' "$key" "$hex"
            local r=$((16#${hex:0:2})) g=$((16#${hex:2:2})) b=$((16#${hex:4:2}))
            printf '%s_rgb\t%s;%s;%s\n' "$key" "$r" "$g" "$b"
            printf '%s_ansi\t38;2;%s;%s;%s\n' "$key" "$r" "$g" "$b"
        fi
    done
}

# render_template SRC DEST  — replaces {{key}} placeholders.
render_template() {
    local src="$1" dest="$2" content key value
    content="$(<"$src")"
    shopt -u patsub_replacement 2>/dev/null || true
    while IFS=$'\t' read -r key value; do
        content="${content//"{{$key}}"/$value}"
    done <<<"$RS_VARS"
    if [[ $content == *"{{"*"}}"* ]]; then
        warn "Unfilled placeholder in $(basename "$src"): $(grep -o '{{[^}]*}}' <<<"$content" | sort -u | tr '\n' ' ')"
    fi
    mkdir -p "$(dirname "$dest")"
    local tmp
    tmp="$(mktemp "$(dirname "$dest")/.ricescape.XXXXXX")"
    printf '%s\n' "$content" >"$tmp"
    mv "$tmp" "$dest"
}

# Lists every rendered target path (relative to $HOME).
template_targets() {
    (cd "$RS_REPO/templates" && find . -type f -name '*.tmpl' | sed -e 's|^\./||' -e 's|\.tmpl$||' | sort)
}

render_all() {
    local rel
    while IFS= read -r rel; do
        render_template "$RS_REPO/templates/$rel.tmpl" "$HOME/$rel"
    done < <(template_targets)
}

wallpaper_tool() {
    if have awww; then echo awww
    elif have swww; then echo swww
    fi
}

set_wallpaper() {
    local mode="$1" tool img dir
    tool="$(wallpaper_tool)"
    [[ -n $tool ]] || return 0
    "$tool" query >/dev/null 2>&1 || return 0
    for dir in "$RS_USER_CONFIG/wallpapers" "$RS_REPO/wallpapers"; do
        for img in "$dir/$mode".{png,jpg,jpeg,webp}; do
            if [[ -f $img ]]; then
                "$tool" img "$img" >/dev/null 2>&1 || true
                return 0
            fi
        done
    done
    "$tool" clear "$(jq -r '.bg' <<<"$RS_PALETTE" | tr -d '#')" >/dev/null 2>&1 || true
}

reload_apps() {
    local mode="$1"
    # niri watches its config (and included files) and reloads by itself.
    pkill -USR1 -x kitty 2>/dev/null || true         # kitty re-reads its config
    have makoctl && makoctl reload >/dev/null 2>&1 || true
    if have gsettings; then
        gsettings set org.gnome.desktop.interface color-scheme prefer-dark 2>/dev/null || true
    fi
    set_wallpaper "$mode"
    # Quickshell watches palette.json and re-themes on its own.
}

# apply_mode MODE [quiet]
apply_mode() {
    local mode="$1" quiet="${2:-}"
    [[ -f $RS_REPO/palettes/$mode.json ]] || die "No palette for mode '$mode'."
    ensure_state_dir

    RS_PALETTE="$(build_palette_json "$mode")"
    RS_VARS="$(palette_vars "$RS_PALETTE")"

    local tmp
    tmp="$(mktemp "$RS_STATE/.palette.XXXXXX")"
    printf '%s\n' "$RS_PALETTE" >"$tmp" && mv "$tmp" "$RS_STATE/palette.json"
    printf '%s\n' "$mode" >"$RS_STATE/mode"

    render_all
    reload_apps "$mode"

    [[ -n $quiet ]] || info "You are now playing as: $(mode_display_name "$mode")"
}
