#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

RUN_SCSS_SMOKE="false"
SCAN_BACKUPS="false"

while [[ $# -gt 0 ]]; do
  case "${1:-}" in
    --scss-smoke)
      RUN_SCSS_SMOKE="true"
      shift
      ;;
    --scan-backups)
      SCAN_BACKUPS="true"
      shift
      ;;
    -h|--help)
      cat <<'EOF'
Uso:
  bash scripts/audit-theme-gaps.sh [--scss-smoke] [--scan-backups]

Checks:
  - resquicios de "orchis" no projeto e instalacao
  - links GTK4 quebrados/legados em ~/.config/gtk-4.0
  - variantes CleanFrame -hdpi/-xhdpi instaladas
  - consistencia basica de index.theme
  - padroes GTK4 modernos no CSS instalado (informativo)
  - metricas de identidade visual GTK4 (fonte SCSS vs CSS instalado)
  - smoke compile de SCSS (opcional)
EOF
      exit 0
      ;;
    *)
      echo "Opcao invalida: ${1}" >&2
      exit 1
      ;;
  esac
done

if [[ -n "${XDG_DATA_HOME:-}" ]]; then
  USER_THEME_DIR="${XDG_DATA_HOME}/themes"
elif [[ -d "${HOME}/.themes" ]]; then
  USER_THEME_DIR="${HOME}/.themes"
else
  USER_THEME_DIR="${HOME}/.local/share/themes"
fi

GTK4_LINK_DIR="${HOME}/.config/gtk-4.0"

TOTAL_WARN=0
TOTAL_ERR=0

section() {
  echo
  echo "== $1 =="
}

warn() {
  TOTAL_WARN=$((TOTAL_WARN + 1))
  echo "[WARN] $*"
}

err() {
  TOTAL_ERR=$((TOTAL_ERR + 1))
  echo "[ERRO] $*"
}

ok() {
  echo "[OK] $*"
}

info() {
  echo "[INFO] $*"
}

check_orchis_in_repo() {
  section "Projeto: Resquicios Orchis"
  local hits
  hits="$(
    {
      rg -n -i "orchis" core.sh install.sh src scripts \
        --glob '!.git/**' \
        --glob '!node_modules/**' \
        --glob '!audit-theme-gaps.sh' \
        --glob '!**/audit-theme-gaps.sh' \
        --glob '*.sh' \
        --glob '*.scss' \
        --glob '*.css' \
        --glob '*.svg' \
        --glob '*.xml' \
        --glob '*.theme' \
        --glob '*.ini' \
        --glob '*.rc' || true
    } | rg -v '^(\./)?scripts/audit-theme-gaps\.sh:' || true
  )"
  if [[ -z "$hits" ]]; then
    ok "Nenhuma referencia a 'orchis' no repositorio."
  else
    warn "Referencias a 'orchis' encontradas no repositorio:"
    echo "$hits"
  fi
}

check_orchis_in_installed() {
  section "Instalacao: Resquicios Orchis"

  local targets=()
  [[ -d "$USER_THEME_DIR" ]] && targets+=("$USER_THEME_DIR")
  [[ -d "${HOME}/.local/share/themes" && "${HOME}/.local/share/themes" != "$USER_THEME_DIR" ]] && targets+=("${HOME}/.local/share/themes")
  [[ -d "${HOME}/.themes" && "${HOME}/.themes" != "$USER_THEME_DIR" ]] && targets+=("${HOME}/.themes")
  [[ -d "/usr/share/themes" ]] && targets+=("/usr/share/themes")

  if [[ ${#targets[@]} -eq 0 ]]; then
    info "Nenhum diretório de temas encontrado."
    return
  fi

  local rg_globs=(--glob '!**/node_modules/**')
  if [[ "$SCAN_BACKUPS" != "true" ]]; then
    rg_globs+=(--glob '!**/bkp/**' --glob '!**/backup/**')
  fi

  local hits
  hits="$(rg -n -i "orchis" "${targets[@]}" "${rg_globs[@]}" 2>/dev/null || true)"
  if [[ -z "$hits" ]]; then
    ok "Sem referencias a 'orchis' nos temas instalados (escopo auditado)."
  else
    warn "Referencias a 'orchis' encontradas em temas instalados:"
    echo "$hits"
  fi
}

check_cleanframe_variants() {
  section "Instalacao: Variantes CleanFrame"

  local dirs
  dirs="$(find "$USER_THEME_DIR" -maxdepth 1 -mindepth 1 -type d -name 'CleanFrame*' 2>/dev/null | sort || true)"
  if [[ -z "$dirs" ]]; then
    warn "Nenhum tema CleanFrame encontrado em ${USER_THEME_DIR}."
    return
  fi

  echo "$dirs"

  local hidpi_dirs
  hidpi_dirs="$(echo "$dirs" | rg -- '-(hdpi|xhdpi)$' || true)"
  if [[ -n "$hidpi_dirs" ]]; then
    warn "Variantes HiDPI instaladas detectadas (-hdpi/-xhdpi)."
    echo "$hidpi_dirs"
  else
    ok "Sem variantes HiDPI instaladas no diretorio ativo."
  fi
}

check_gtk4_links() {
  section "GTK4: Links em ~/.config/gtk-4.0"

  if [[ ! -d "$GTK4_LINK_DIR" ]]; then
    warn "${GTK4_LINK_DIR} nao existe."
    return
  fi

  local f target
  for f in assets gtk.css gtk-dark.css; do
    if [[ ! -L "${GTK4_LINK_DIR}/${f}" ]]; then
      if [[ -e "${GTK4_LINK_DIR}/${f}" ]]; then
        warn "${GTK4_LINK_DIR}/${f} existe mas nao e symlink."
      else
        warn "${GTK4_LINK_DIR}/${f} ausente."
      fi
      continue
    fi

    target="$(readlink -f "${GTK4_LINK_DIR}/${f}" 2>/dev/null || true)"
    if [[ -z "$target" || ! -e "$target" ]]; then
      err "Symlink quebrado: ${GTK4_LINK_DIR}/${f}"
      continue
    fi

    if [[ "$target" == *Orchis* || "$target" == *orchis* ]]; then
      warn "Link GTK4 ainda aponta para Orchis: ${GTK4_LINK_DIR}/${f} -> ${target}"
    elif [[ "$target" == *CleanFrame* ]]; then
      ok "${f} -> ${target}"
    else
      warn "${f} aponta para outro tema/arquivo: ${target}"
    fi
  done
}

check_index_theme_consistency() {
  section "Instalacao: Consistencia index.theme"

  local indexes
  indexes="$(find "$USER_THEME_DIR" -maxdepth 2 -type f -path '*/CleanFrame*/index.theme' 2>/dev/null | sort || true)"
  if [[ -z "$indexes" ]]; then
    warn "Nenhum index.theme de CleanFrame encontrado em ${USER_THEME_DIR}."
    return
  fi

  while IFS= read -r idx; do
    [[ -z "$idx" ]] && continue
    local name gtk metacity dir base
    dir="$(dirname "$idx")"
    base="$(basename "$dir")"
    name="$(rg -n '^Name=' "$idx" | head -n1 | cut -d= -f2- || true)"
    gtk="$(rg -n '^GtkTheme=' "$idx" | head -n1 | cut -d= -f2- || true)"
    metacity="$(rg -n '^MetacityTheme=' "$idx" | head -n1 | cut -d= -f2- || true)"

    if [[ "$name" != "$base" || "$gtk" != "$base" || "$metacity" != "$base" ]]; then
      warn "Inconsistencia em ${idx} (dir=${base}, Name=${name}, GtkTheme=${gtk}, MetacityTheme=${metacity})"
    else
      ok "${base}: Name/GtkTheme/MetacityTheme consistentes"
    fi
  done <<< "$indexes"
}

check_gtk4_css_patterns() {
  section "GTK4: Padroes de parser no CSS instalado (informativo)"

  local css="${USER_THEME_DIR}/CleanFrame-Light/gtk-4.0/gtk.css"
  if [[ ! -f "$css" ]]; then
    warn "CSS GTK4 nao encontrado: ${css}"
    return
  fi

  local patterns='^:root|var\(--|color-mix\(|:not\([^)]*,|-gtk-outline-radius|focus-within|focus-visible'
  local hits
  hits="$(rg -n -- "$patterns" "$css" || true)"

  if [[ -z "$hits" ]]; then
    info "CSS GTK4 parece em modo compat (safe parser) ou sem sintaxe moderna detectada."
  else
    info "CSS GTK4 contem sintaxe moderna (esperado no modo visual completo):"
    printf '%s\n' "$hits" | sed -n '1,30p'
  fi
}

count_matches() {
  local pattern="$1"
  shift
  { rg -n -- "$pattern" "$@" 2>/dev/null || true; } | wc -l | tr -d ' '
}

check_gtk4_visual_identity() {
  section "GTK4: Identidade visual (SCSS vs CSS instalado)"

  local installed_css="${USER_THEME_DIR}/CleanFrame-Light/gtk-4.0/gtk.css"
  if [[ ! -f "$installed_css" ]]; then
    warn "CSS GTK4 nao encontrado para auditoria de identidade: ${installed_css}"
    return
  fi

  local src_paths=("src/gtk/4.0" "src/_sass/gtk")

  local src_var src_mix src_grad src_orange src_accent src_warn
  local css_var css_mix css_grad css_orange css_accent css_warn

  src_var="$(count_matches 'var\(--' "${src_paths[@]}")"
  src_mix="$(count_matches 'color-mix\(' "${src_paths[@]}")"
  src_grad="$(count_matches 'linear-gradient\(' "${src_paths[@]}")"
  src_orange="$(count_matches 'orange_[1-5]|#f57c00|#ffd600' "${src_paths[@]}")"
  src_accent="$(count_matches 'accent(_bg_color|_fg_color|_color)|--accent-' "${src_paths[@]}")"
  src_warn="$(count_matches 'warning(_bg_color|_fg_color|_color)' "${src_paths[@]}")"

  css_var="$(count_matches 'var\(--' "$installed_css")"
  css_mix="$(count_matches 'color-mix\(' "$installed_css")"
  css_grad="$(count_matches 'linear-gradient\(' "$installed_css")"
  css_orange="$(count_matches 'orange_[1-5]|#f57c00|#ffd600' "$installed_css")"
  css_accent="$(count_matches 'accent(_bg_color|_fg_color|_color)|--accent-' "$installed_css")"
  css_warn="$(count_matches 'warning(_bg_color|_fg_color|_color)' "$installed_css")"

  printf '%-18s %8s %8s\n' "Metrica" "SCSS" "Instalado"
  printf '%-18s %8s %8s\n' "var(--" "$src_var" "$css_var"
  printf '%-18s %8s %8s\n' "color-mix(" "$src_mix" "$css_mix"
  printf '%-18s %8s %8s\n' "linear-gradient(" "$src_grad" "$css_grad"
  printf '%-18s %8s %8s\n' "orange/alerta" "$src_orange" "$css_orange"
  printf '%-18s %8s %8s\n' "accent tokens" "$src_accent" "$css_accent"
  printf '%-18s %8s %8s\n' "warning tokens" "$src_warn" "$css_warn"

  if [[ "$src_mix" -gt 0 && "$css_mix" -eq 0 && "$src_var" -gt 0 && "$css_var" -eq 0 ]]; then
    warn "Drift visual forte: CSS GTK4 instalado sem var()/color-mix(), possivel 'safe parser' ativo."
  fi

  if [[ "$css_accent" -eq 0 || "$css_warn" -eq 0 ]]; then
    warn "Tokens de acento/alerta ausentes no CSS instalado; identidade visual pode estar degradada."
  fi

  if [[ "$css_grad" -lt 20 ]]; then
    warn "Poucos gradientes no CSS GTK4 instalado (${css_grad}); pode indicar simplificacao excessiva."
  fi
}

check_xfwm_assets_presence() {
  section "Projeto: Assets XFWM multi-DPI"

  local missing=0
  for p in \
    "src/xfwm4/xpm/assets" \
    "src/xfwm4/xpm/assets-hdpi" \
    "src/xfwm4/xpm/assets-xhdpi" \
    "src/xfwm4/svg/assets" \
    "src/xfwm4/svg/assets-hdpi" \
    "src/xfwm4/svg/assets-xhdpi"; do
    if [[ -d "$p" ]]; then
      ok "Existe: $p"
    else
      warn "Ausente: $p"
      missing=1
    fi
  done

  [[ "$missing" -eq 0 ]] && info "Geração de assets multi-DPI do projeto parece completa."
}

run_scss_smoke() {
  section "SCSS Smoke"

  if [[ "$RUN_SCSS_SMOKE" != "true" ]]; then
    info "Pulado. Use --scss-smoke para compilar entrypoints."
    return
  fi

  if bash scripts/scss-smoke.sh; then
    ok "SCSS smoke passou."
  else
    err "SCSS smoke falhou."
  fi
}

check_orchis_in_repo
check_orchis_in_installed
check_cleanframe_variants
check_gtk4_links
check_index_theme_consistency
check_gtk4_css_patterns
check_gtk4_visual_identity
check_xfwm_assets_presence
run_scss_smoke

section "Resumo"
echo "Warnings: ${TOTAL_WARN}"
echo "Erros   : ${TOTAL_ERR}"

if [[ "$TOTAL_ERR" -gt 0 ]]; then
  exit 2
fi

exit 0
