#!/usr/bin/env bash
set -euo pipefail

# Installs common Qt/GTK integration packages and configures Qt apps to
# follow GTK desktop settings (theme, icons, fonts/dialog integration)
# using QGnomePlatform when available.

SCRIPT_NAME="$(basename "$0")"
ENV_FILE_DEFAULT="${HOME}/.config/environment.d/90-qt-gtk-coherence.conf"

DRY_RUN=0
SKIP_INSTALL=0
FORCE_PLATFORM_THEME=""
ENV_FILE="${ENV_FILE_DEFAULT}"
FORCE_GTK_THEME_NAME=""

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

desktop_env_value() {
  local parts=(
    "${XDG_CURRENT_DESKTOP:-}"
    "${XDG_SESSION_DESKTOP:-}"
    "${DESKTOP_SESSION:-}"
  )
  printf '%s\n' "${parts[*]}"
}

detect_qt_first_desktop_reason() {
  local env_blob
  env_blob="$(desktop_env_value | tr '[:lower:]' '[:upper:]')"

  if [[ "${env_blob}" == *"PLASMA"* ]] || [[ "${env_blob}" == *"KDE"* ]]; then
    printf 'Sessao KDE Plasma detectada (desktop baseado em Qt por padrao).\n'
    return 0
  fi

  if [[ "${env_blob}" == *"LXQT"* ]]; then
    printf 'Sessao LXQt detectada (desktop baseado em Qt por padrao).\n'
    return 0
  fi

  return 1
}

run_cmd() {
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    printf '[dry-run] %q' "$1"
    shift || true
    for arg in "$@"; do
      printf ' %q' "${arg}"
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
  Instalar pacotes de integracao Qt/GTK e configurar Qt para seguir
  as configuracoes do GTK, melhorando a coerencia visual entre janelas.

Opcoes:
  --skip-install              Nao instala pacotes, apenas configura o ambiente
  --platform-theme VALOR      Forca QT_QPA_PLATFORMTHEME (ex: gnome, gtk3)
  --gtk-theme-name NOME       Exporta GTK_THEME com este nome (padrao: tema atual via gsettings; fallback CleanFrame-Light)
  --env-file CAMINHO          Arquivo de ambiente (padrao: ${ENV_FILE_DEFAULT})
  --dry-run                   Mostra comandos sem executar
  -h, --help                  Exibe esta ajuda

Exemplos:
  ${SCRIPT_NAME}
  ${SCRIPT_NAME} --skip-install
  ${SCRIPT_NAME} --platform-theme gnome
  ${SCRIPT_NAME} --gtk-theme-name CleanFrame-Light
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-install)
      SKIP_INSTALL=1
      shift
      ;;
    --platform-theme)
      FORCE_PLATFORM_THEME="${2:-}"
      [[ -n "${FORCE_PLATFORM_THEME}" ]] || die "Informe um valor para --platform-theme"
      shift 2
      ;;
    --gtk-theme-name)
      FORCE_GTK_THEME_NAME="${2:-}"
      [[ -n "${FORCE_GTK_THEME_NAME}" ]] || die "Informe um valor para --gtk-theme-name"
      shift 2
      ;;
    --env-file)
      ENV_FILE="${2:-}"
      [[ -n "${ENV_FILE}" ]] || die "Informe um caminho para --env-file"
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

PKG_MANAGER=""
PRIV_CMD=()

detect_pkg_manager() {
  if has_command apt-get; then
    PKG_MANAGER="apt"
  elif has_command dnf; then
    PKG_MANAGER="dnf"
  elif has_command pacman; then
    PKG_MANAGER="pacman"
  elif has_command zypper; then
    PKG_MANAGER="zypper"
  else
    PKG_MANAGER=""
  fi
}

init_privilege_cmd() {
  if [[ "${EUID}" -eq 0 ]]; then
    PRIV_CMD=()
    return 0
  fi

  if has_command sudo; then
    PRIV_CMD=(sudo)
    return 0
  fi

  die "Este script precisa de privilegios para instalar pacotes. Execute como root ou instale 'sudo'."
}

package_exists() {
  local pkg="$1"

  case "${PKG_MANAGER}" in
    apt)
      apt-cache show "${pkg}" >/dev/null 2>&1
      ;;
    dnf)
      dnf -q info "${pkg}" >/dev/null 2>&1
      ;;
    pacman)
      pacman -Si "${pkg}" >/dev/null 2>&1
      ;;
    zypper)
      zypper --non-interactive info "${pkg}" >/dev/null 2>&1
      ;;
    *)
      return 1
      ;;
  esac
}

install_one_package() {
  local pkg="$1"

  if ! package_exists "${pkg}"; then
    warn "Pacote nao encontrado para ${PKG_MANAGER}: ${pkg} (ignorando)"
    return 0
  fi

  case "${PKG_MANAGER}" in
    apt)
      run_cmd "${PRIV_CMD[@]}" apt-get install -y "${pkg}"
      ;;
    dnf)
      run_cmd "${PRIV_CMD[@]}" dnf install -y "${pkg}"
      ;;
    pacman)
      run_cmd "${PRIV_CMD[@]}" pacman -S --needed --noconfirm "${pkg}"
      ;;
    zypper)
      run_cmd "${PRIV_CMD[@]}" zypper --non-interactive install "${pkg}"
      ;;
    *)
      die "Gerenciador de pacotes nao suportado"
      ;;
  esac
}

refresh_package_metadata() {
  case "${PKG_MANAGER}" in
    apt)
      run_cmd "${PRIV_CMD[@]}" apt-get update
      ;;
    dnf)
      # Usually not required explicitly; dnf refreshes metadata as needed.
      :
      ;;
    pacman)
      # Avoid full sync by default; pacman will fail if cache is outdated.
      :
      ;;
    zypper)
      run_cmd "${PRIV_CMD[@]}" zypper --non-interactive refresh
      ;;
    *)
      :
      ;;
  esac
}

install_integration_packages() {
  local packages=()

  detect_pkg_manager
  [[ -n "${PKG_MANAGER}" ]] || {
    warn "Nenhum gerenciador suportado detectado (apt/dnf/pacman/zypper)."
    warn "Vou seguir apenas com a configuracao de ambiente."
    return 0
  }

  case "${PKG_MANAGER}" in
    apt)
      packages=(
        qgnomeplatform-qt5
        qgnomeplatform-qt6
        adwaita-qt
        adwaita-qt6
        qt5ct
        qt6ct
        xdg-desktop-portal-gtk
      )
      ;;
    dnf)
      packages=(
        qgnomeplatform-qt5
        qgnomeplatform-qt6
        adwaita-qt5
        adwaita-qt6
        qt5ct
        qt6ct
        xdg-desktop-portal-gtk
      )
      ;;
    pacman)
      packages=(
        qgnomeplatform-qt5
        qgnomeplatform-qt6
        adwaita-qt5
        adwaita-qt6
        qt5ct
        qt6ct
        xdg-desktop-portal-gtk
      )
      ;;
    zypper)
      packages=(
        qgnomeplatform-qt5
        qgnomeplatform-qt6
        adwaita-qt5
        adwaita-qt6
        qt5ct
        qt6ct
        xdg-desktop-portal-gtk
      )
      ;;
  esac

  log "Gerenciador detectado: ${PKG_MANAGER}"
  init_privilege_cmd
  refresh_package_metadata
  for pkg in "${packages[@]}"; do
    install_one_package "${pkg}"
  done
}

has_platform_theme_plugin() {
  local needle="$1"
  local matches=()

  shopt -s nullglob
  matches+=(
    /usr/lib*/qt*/plugins/platformthemes/*"${needle}"*
    /usr/lib*/plugins/platformthemes/*"${needle}"*
    /usr/lib/*/qt*/plugins/platformthemes/*"${needle}"*
  )
  shopt -u nullglob

  [[ "${#matches[@]}" -gt 0 ]]
}

select_platform_theme() {
  if [[ -n "${FORCE_PLATFORM_THEME}" ]]; then
    printf '%s\n' "${FORCE_PLATFORM_THEME}"
    return 0
  fi

  if has_platform_theme_plugin "qgnomeplatform"; then
    printf 'gnome\n'
    return 0
  fi

  if has_platform_theme_plugin "qgtk3"; then
    printf 'gtk3\n'
    return 0
  fi

  # Safe default in GNOME/Cinnamon/XFCE environments when plugin search is inconclusive.
  printf 'gnome\n'
}

read_gtk_setting() {
  local schema="$1"
  local key="$2"

  if ! has_command gsettings; then
    printf 'N/D\n'
    return 0
  fi

  gsettings get "${schema}" "${key}" 2>/dev/null | sed "s/^'//; s/'$//" || printf 'N/D\n'
}

resolve_gtk_theme_name_for_env() {
  local gtk_theme_name

  if [[ -n "${FORCE_GTK_THEME_NAME}" ]]; then
    printf '%s\n' "${FORCE_GTK_THEME_NAME}"
    return 0
  fi

  gtk_theme_name="$(read_gtk_setting org.gnome.desktop.interface gtk-theme)"
  if [[ -z "${gtk_theme_name}" || "${gtk_theme_name}" == "N/D" ]]; then
    gtk_theme_name="CleanFrame-Light"
  fi

  printf '%s\n' "${gtk_theme_name}"
}

write_env_file() {
  local platform_theme="$1"
  local gtk_theme_name="$2"
  local env_dir

  env_dir="$(dirname "${ENV_FILE}")"
  run_cmd mkdir -p "${env_dir}"

  if [[ "${DRY_RUN}" -eq 1 ]]; then
    cat <<EOF
[dry-run] Escreveria em ${ENV_FILE}:
QT_QPA_PLATFORMTHEME=${platform_theme}
QT_WAYLAND_DECORATION=adwaita
GTK_THEME=${gtk_theme_name}
EOF
    return 0
  fi

  cat > "${ENV_FILE}" <<EOF
# Generated by ${SCRIPT_NAME}
# Makes Qt apps follow GTK desktop integration when supported.
QT_QPA_PLATFORMTHEME=${platform_theme}
QT_WAYLAND_DECORATION=adwaita
GTK_THEME=${gtk_theme_name}
EOF
}

show_summary() {
  local platform_theme="$1"
  local gtk_theme
  local icon_theme
  local font_name
  local cursor_theme

  gtk_theme="$(read_gtk_setting org.gnome.desktop.interface gtk-theme)"
  icon_theme="$(read_gtk_setting org.gnome.desktop.interface icon-theme)"
  font_name="$(read_gtk_setting org.gnome.desktop.interface font-name)"
  cursor_theme="$(read_gtk_setting org.gnome.desktop.interface cursor-theme)"

  log ""
  log "Resumo:"
  log "  GTK theme     : ${gtk_theme}"
  log "  Icon theme    : ${icon_theme}"
  log "  Font          : ${font_name}"
  log "  Cursor theme  : ${cursor_theme}"
  log "  QT platform   : ${platform_theme}"
  log "  Env file      : ${ENV_FILE}"
}

show_next_steps() {
  cat <<EOF

Proximos passos:
1. Faça logout/login (ou reinicie a sessao grafica) para carregar o arquivo em ~/.config/environment.d.
2. Teste um app Qt (ex.: qBittorrent, VLC, Telegram Desktop, qt6ct/qt5ct).
3. Se algum app ficar inconsistente, tente:
   ${SCRIPT_NAME} --platform-theme gtk3

Dica (teste temporario na sessao atual):
  export QT_QPA_PLATFORMTHEME=\$(grep '^QT_QPA_PLATFORMTHEME=' "${ENV_FILE}" | cut -d= -f2-)
EOF
}

main() {
  local platform_theme
  local gtk_theme_name
  local skip_reason

  if skip_reason="$(detect_qt_first_desktop_reason)"; then
    log "Configuracao nao aplicada."
    log "Motivo: ${skip_reason}"
    log "Contexto desktop: ${XDG_CURRENT_DESKTOP:-N/D} | ${XDG_SESSION_DESKTOP:-N/D} | ${DESKTOP_SESSION:-N/D}"
    log ""
    log "Este script e voltado para ambientes GTK-first (GNOME/Cinnamon/XFCE/MATE etc.)."
    log "Em desktops Qt-first, forcar Qt a seguir GTK pode piorar a consistencia visual."
    exit 0
  fi

  if [[ "${SKIP_INSTALL}" -eq 0 ]]; then
    install_integration_packages
  else
    log "Instalacao de pacotes ignorada (--skip-install)."
  fi

  platform_theme="$(select_platform_theme)"
  gtk_theme_name="$(resolve_gtk_theme_name_for_env)"
  write_env_file "${platform_theme}" "${gtk_theme_name}"
  show_summary "${platform_theme}"
  show_next_steps
}

main "$@"
