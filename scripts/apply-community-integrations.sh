#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

DO_QT=0
DO_FLATPAK=0
DO_ELECTRON=0
DO_TEAMS=0
DO_SLACK_INTEROP=0
DO_ALL=0
DRY_RUN=0
ELECTRON_ALL_KNOWN=0
GTK_THEME_NAME=""

log() {
  printf '%s\n' "$*"
}

warn() {
  printf 'WARN: %s\n' "$*" >&2
}

die() {
  printf 'ERRO: %s\n' "$*" >&2
  exit 1
}

has_command() {
  command -v "$1" >/dev/null 2>&1
}

run_cmd() {
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    printf '[dry-run]'
    for arg in "$@"; do
      printf ' %q' "$arg"
    done
    printf '\n'
    return 0
  fi
  "$@"
}

usage() {
  cat <<EOF
Uso:
  ${SCRIPT_NAME} [opcoes]

Objetivo:
  Aplicar integracoes comunitarias para melhorar a coerencia visual do
  CleanFrame em Qt, Flatpak e apps Electron (Teams/Slack e similares).

Sem flags, executa o preset padrao:
  --qt --flatpak --electron --teams --slack-interop

Opcoes:
  --all                    Mesmo comportamento do preset padrao
  --qt                     Configura Qt para seguir GTK (via environment.d)
  --flatpak                Aplica flatpak override (GTK_THEME + acesso tema/config)
  --electron               Gera CSS de selecao para Electron/wrappers
  --electron-all-known     Com --electron, gera CSS para todos os presets suportados
  --teams                  Ajusta ~/.config/teams-for-linux/custom.css (quando existir)
  --slack-interop          Cria/atualiza ssb-interop.js para injetar CSS no Slack
  --gtk-theme-name NOME    Forca GTK_THEME (padrao: tema atual via gsettings; fallback CleanFrame-Light)
  --dry-run                Mostra comandos/acoes sem gravar
  -h, --help               Exibe esta ajuda

Exemplos:
  ${SCRIPT_NAME}
  ${SCRIPT_NAME} --qt --flatpak
  ${SCRIPT_NAME} --electron --teams
  ${SCRIPT_NAME} --electron --electron-all-known
EOF
}

while [[ $# -gt 0 ]]; do
  case "${1:-}" in
    --all)
      DO_ALL=1
      shift
      ;;
    --qt)
      DO_QT=1
      shift
      ;;
    --flatpak)
      DO_FLATPAK=1
      shift
      ;;
    --electron)
      DO_ELECTRON=1
      shift
      ;;
    --electron-all-known)
      ELECTRON_ALL_KNOWN=1
      shift
      ;;
    --teams)
      DO_TEAMS=1
      shift
      ;;
    --slack-interop)
      DO_SLACK_INTEROP=1
      shift
      ;;
    --gtk-theme-name)
      GTK_THEME_NAME="${2:-}"
      [[ -n "${GTK_THEME_NAME}" ]] || die "Informe um valor para --gtk-theme-name"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Opcao invalida: $1"
      ;;
  esac
done

if [[ "${DO_ALL}" -eq 1 ]] || [[ "${DO_QT}${DO_FLATPAK}${DO_ELECTRON}${DO_TEAMS}${DO_SLACK_INTEROP}" == "00000" ]]; then
  DO_QT=1
  DO_FLATPAK=1
  DO_ELECTRON=1
  DO_TEAMS=1
  DO_SLACK_INTEROP=1
fi

resolve_gtk_theme_name() {
  if [[ -n "${GTK_THEME_NAME}" ]]; then
    printf '%s\n' "${GTK_THEME_NAME}"
    return 0
  fi

  if has_command gsettings; then
    local current_theme
    current_theme="$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'" || true)"
    if [[ -n "${current_theme}" ]]; then
      printf '%s\n' "${current_theme}"
      return 0
    fi
  fi

  printf 'CleanFrame-Light\n'
}

apply_qt_integration() {
  local theme_name="$1"
  local cmd=(bash "${REPO_DIR}/scripts/setup-qt-gtk-coherence.sh" --skip-install --gtk-theme-name "${theme_name}")
  [[ "${DRY_RUN}" -eq 1 ]] && cmd+=(--dry-run)

  if [[ ! -x "${REPO_DIR}/scripts/setup-qt-gtk-coherence.sh" ]]; then
    warn "Script nao encontrado: scripts/setup-qt-gtk-coherence.sh"
    return 0
  fi

  log ""
  log "[STEP] Qt/GTK coherence"
  run_cmd "${cmd[@]}"
}

apply_flatpak_override() {
  local theme_name="$1"

  if ! has_command flatpak; then
    warn "flatpak nao encontrado; pulando step --flatpak"
    return 0
  fi

  log ""
  log "[STEP] Flatpak override"

  run_cmd flatpak override --user --env=GTK_THEME="${theme_name}"
  run_cmd flatpak override --user --filesystem=xdg-config/gtk-3.0:ro
  run_cmd flatpak override --user --filesystem=xdg-config/gtk-4.0:ro
  run_cmd flatpak override --user --filesystem=xdg-data/themes:ro
  run_cmd flatpak override --user --filesystem="${HOME}/.themes:ro"
}

apply_electron_selection_css() {
  local cmd=(bash "${REPO_DIR}/scripts/apply-electron-selection-css.sh")

  if [[ ! -x "${REPO_DIR}/scripts/apply-electron-selection-css.sh" ]]; then
    warn "Script nao encontrado: scripts/apply-electron-selection-css.sh"
    return 0
  fi

  if [[ "${ELECTRON_ALL_KNOWN}" -eq 1 ]]; then
    cmd+=(--all-known)
  else
    cmd+=(
      --app teams-for-linux
      --app teams-for-linux-snap
      --app slack
      --app slack-flatpak
      --app slack-snap
      --print-loader-hints
    )
  fi

  [[ "${DRY_RUN}" -eq 1 ]] && cmd+=(--dry-run)

  log ""
  log "[STEP] Electron selection CSS"
  run_cmd "${cmd[@]}"
}

patch_teams_custom_css() {
  local file="${HOME}/.config/teams-for-linux/custom.css"
  local backup="${file}.bak-cleanframe"

  log ""
  log "[STEP] teams-for-linux custom.css"

  if [[ ! -f "${file}" ]]; then
    warn "Arquivo nao encontrado: ${file} (pulando)"
    return 0
  fi

  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log "[dry-run] Atualizaria ${file} para usar selecao #A6E4FF"
    return 0
  fi

  cp -f "${file}" "${backup}"

  if grep -qi -- '--cleanframe-selection-bg:' "${file}"; then
    sed -i 's/--cleanframe-selection-bg:[[:space:]]*#00[Bb]8[Ff][Ff];/--cleanframe-selection-bg: #A6E4FF;/g' "${file}"
    sed -i 's/--cleanframe-selection-bg:[[:space:]]*#A6E4FF;/--cleanframe-selection-bg: #A6E4FF;/g' "${file}"
  else
    cat >> "${file}" <<'EOF'

/* CleanFrame selection override */
:root {
  --cleanframe-selection-bg: #A6E4FF;
  --cleanframe-selection-fg: #000000;
}

::selection,
*::selection {
  background: var(--cleanframe-selection-bg) !important;
  color: var(--cleanframe-selection-fg) !important;
}

input::selection,
textarea::selection,
[contenteditable="true"]::selection,
[role="textbox"]::selection {
  background: var(--cleanframe-selection-bg) !important;
  color: var(--cleanframe-selection-fg) !important;
}
EOF
  fi

  log "[OK] Atualizado: ${file}"
  log "[INFO] Backup: ${backup}"
}

write_slack_interop_file() {
  local dir="$1"
  local css_file="${dir}/cleanframe-selection.css"
  local js_file="${dir}/ssb-interop.js"
  local backup="${js_file}.bak-cleanframe"

  if [[ ! -d "${dir}" ]]; then
    warn "Diretorio Slack nao encontrado: ${dir} (pulando)"
    return 0
  fi

  if [[ ! -f "${css_file}" ]]; then
    warn "CSS nao encontrado em ${css_file}. Rode o step --electron primeiro."
    return 0
  fi

  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log "[dry-run] Criaria/atualizaria ${js_file}"
    return 0
  fi

  [[ -f "${js_file}" ]] && cp -f "${js_file}" "${backup}" || true

  cat > "${js_file}" <<'EOF'
const fs = require("fs");
const path = require("path");

function injectCleanFrameSelectionCss() {
  const cssPath = path.join(__dirname, "cleanframe-selection.css");
  let css;
  try {
    css = fs.readFileSync(cssPath, "utf8");
  } catch (err) {
    console.error("[CleanFrame] Failed to read CSS:", cssPath, err);
    return;
  }

  const apply = () => {
    if (!document || !document.head) return false;
    let style = document.getElementById("cleanframe-selection-style");
    if (!style) {
      style = document.createElement("style");
      style.id = "cleanframe-selection-style";
      document.head.appendChild(style);
    }
    style.textContent = css;
    return true;
  };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", () => {
      if (!apply()) setTimeout(apply, 500);
    }, { once: true });
  } else {
    if (!apply()) setTimeout(apply, 500);
  }
}

try {
  injectCleanFrameSelectionCss();
} catch (err) {
  console.error("[CleanFrame] Injection error:", err);
}
EOF

  log "[OK] Slack interop atualizado: ${js_file}"
  [[ -f "${backup}" ]] && log "[INFO] Backup: ${backup}"
}

apply_slack_interop() {
  log ""
  log "[STEP] Slack interop"
  write_slack_interop_file "${HOME}/.config/Slack"
  write_slack_interop_file "${HOME}/.var/app/com.slack.Slack/config/Slack"
}

show_restart_notes() {
  log ""
  log "Proximos passos:"
  log "1. Reinicie Teams/Slack para recarregar CSS/interop."
  log "2. Faca logout/login (ou reinicie a sessao grafica) para apps Qt lerem environment.d."
  log "3. Se algum wrapper Electron nao aplicar, verifique suporte a custom CSS/injecao."
}

main() {
  local theme_name
  theme_name="$(resolve_gtk_theme_name)"

  log "[INFO] CleanFrame community integrations"
  log "  GTK theme alvo : ${theme_name}"
  log "  dry-run        : ${DRY_RUN}"
  log "  qt             : ${DO_QT}"
  log "  flatpak        : ${DO_FLATPAK}"
  log "  electron       : ${DO_ELECTRON}"
  log "  teams          : ${DO_TEAMS}"
  log "  slack-interop  : ${DO_SLACK_INTEROP}"

  [[ "${DO_QT}" -eq 1 ]] && apply_qt_integration "${theme_name}"
  [[ "${DO_FLATPAK}" -eq 1 ]] && apply_flatpak_override "${theme_name}"
  [[ "${DO_ELECTRON}" -eq 1 ]] && apply_electron_selection_css
  [[ "${DO_TEAMS}" -eq 1 ]] && patch_teams_custom_css
  [[ "${DO_SLACK_INTEROP}" -eq 1 ]] && apply_slack_interop

  show_restart_notes
}

main "$@"
