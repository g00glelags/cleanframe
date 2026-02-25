#!/usr/bin/env bash
set -euo pipefail

# Generates/applies a generic Electron/Chromium ::selection CSS file using
# CleanFrame GTK-derived app selection colors.

SCRIPT_NAME="$(basename "$0")"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXTRACTOR_SCRIPT="${REPO_DIR}/scripts/extract-gtk-selection-snippet.sh"

DEFAULT_OUTPUT_FILE="${HOME}/.config/cleanframe/electron-selection.css"
OUTPUT_FILE="${DEFAULT_OUTPUT_FILE}"
DRY_RUN=0
NO_BACKUP=0
PRINT_ONLY=0
APP_FLAVORS=()
PRINT_LOADER_HINTS=0
LIST_APPS=0
ALL_KNOWN=0

usage() {
  cat <<EOF
Uso:
  ${SCRIPT_NAME} [--app APP]... [--all-known] [--output PATH] [--print] [--print-loader-hints] [--dry-run] [--no-backup]

Objetivo:
  Gerar/aplicar um CSS de ::selection para apps Electron/Chromium (Teams,
  wrappers, custom CSS loaders), usando a selecao de app do GTK/CleanFrame.

Opcoes:
  --app APP       Preset de caminho (pode repetir). Use --list-apps para ver todos.
  --all-known     Gera CSS para todos os presets conhecidos (inclui Flatpak/Snap)
  --list-apps     Lista os presets suportados e sai
  --output PATH   Arquivo CSS de destino (padrao: ${DEFAULT_OUTPUT_FILE}; apenas alvo unico)
  --print         Imprime o CSS no stdout (nao grava arquivo)
  --print-loader-hints  Mostra dicas de como carregar o CSS no app/preset escolhido
  --dry-run       Mostra destino/cores sem gravar
  --no-backup     Nao cria backup .bak quando o arquivo ja existir
  -h, --help      Exibe esta ajuda

Exemplos:
  ${SCRIPT_NAME}
  ${SCRIPT_NAME} --app teams-for-linux
  ${SCRIPT_NAME} --all-known --dry-run
  ${SCRIPT_NAME} --app ferdium --print-loader-hints
  ${SCRIPT_NAME} --print
  ${SCRIPT_NAME} --output "\$HOME/.config/teams-for-linux/custom.css"
EOF
}

die() {
  printf 'ERRO: %s\n' "$*" >&2
  exit 1
}

log() {
  printf '%s\n' "$*"
}

list_known_apps() {
  cat <<'EOF'
Presets suportados:
- generic
- teams-for-linux
- teams-for-linux-snap
- ferdium
- ferdium-flatpak
- franz
- franz-flatpak
- slack
- slack-flatpak
- slack-snap
- discord
- discord-flatpak
- discord-snap
- element
- element-flatpak
- signal-desktop
- signal-desktop-flatpak
- obsidian
- obsidian-flatpak
- postman
- postman-flatpak
- insomnia
- insomnia-flatpak
- code
- code-insiders
- code-oss
- codium
- codium-flatpak
- cursor
EOF
}

known_apps_all() {
  cat <<'EOF'
teams-for-linux
teams-for-linux-snap
ferdium
ferdium-flatpak
franz
franz-flatpak
slack
slack-flatpak
slack-snap
discord
discord-flatpak
discord-snap
element
element-flatpak
signal-desktop
signal-desktop-flatpak
obsidian
obsidian-flatpak
postman
postman-flatpak
insomnia
insomnia-flatpak
code
code-insiders
code-oss
codium
codium-flatpak
cursor
EOF
}

while [[ $# -gt 0 ]]; do
  case "${1:-}" in
    --app)
      [[ -n "${2:-}" ]] || die "Informe um valor para --app"
      APP_FLAVORS+=("${2}")
      shift 2
      ;;
    --all-known)
      ALL_KNOWN=1
      shift
      ;;
    --list-apps)
      LIST_APPS=1
      shift
      ;;
    --output)
      OUTPUT_FILE="${2:-}"
      [[ -n "${OUTPUT_FILE}" ]] || die "Informe um caminho para --output"
      shift 2
      ;;
    --print)
      PRINT_ONLY=1
      shift
      ;;
    --print-loader-hints)
      PRINT_LOADER_HINTS=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --no-backup)
      NO_BACKUP=1
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

[[ -x "${EXTRACTOR_SCRIPT}" ]] || die "Script extrator nao encontrado/executavel: ${EXTRACTOR_SCRIPT}"

if [[ "${LIST_APPS}" -eq 1 ]]; then
  list_known_apps
  exit 0
fi

resolve_output_for_app() {
  local app="$1"
  case "${app}" in
    generic)
      printf '%s\n' "${DEFAULT_OUTPUT_FILE}"
      ;;
    teams-for-linux)
      printf '%s\n' "${HOME}/.config/teams-for-linux/cleanframe-selection.css"
      ;;
    teams-for-linux-snap)
      printf '%s\n' "${HOME}/snap/teams-for-linux/common/cleanframe-selection.css"
      ;;
    ferdium)
      printf '%s\n' "${HOME}/.config/Ferdium/cleanframe-selection.css"
      ;;
    ferdium-flatpak)
      printf '%s\n' "${HOME}/.var/app/org.ferdium.Ferdium/config/Ferdium/cleanframe-selection.css"
      ;;
    franz)
      printf '%s\n' "${HOME}/.config/Franz/cleanframe-selection.css"
      ;;
    franz-flatpak)
      printf '%s\n' "${HOME}/.var/app/com.meetfranz.Franz/config/Franz/cleanframe-selection.css"
      ;;
    slack)
      printf '%s\n' "${HOME}/.config/Slack/cleanframe-selection.css"
      ;;
    slack-flatpak)
      printf '%s\n' "${HOME}/.var/app/com.slack.Slack/config/Slack/cleanframe-selection.css"
      ;;
    slack-snap)
      printf '%s\n' "${HOME}/snap/slack/common/cleanframe-selection.css"
      ;;
    discord)
      printf '%s\n' "${HOME}/.config/discord/cleanframe-selection.css"
      ;;
    discord-flatpak)
      printf '%s\n' "${HOME}/.var/app/com.discordapp.Discord/config/discord/cleanframe-selection.css"
      ;;
    discord-snap)
      printf '%s\n' "${HOME}/snap/discord/common/cleanframe-selection.css"
      ;;
    element)
      printf '%s\n' "${HOME}/.config/Element/cleanframe-selection.css"
      ;;
    element-flatpak)
      printf '%s\n' "${HOME}/.var/app/im.riot.Riot/config/Element/cleanframe-selection.css"
      ;;
    signal-desktop)
      printf '%s\n' "${HOME}/.config/Signal/cleanframe-selection.css"
      ;;
    signal-desktop-flatpak)
      printf '%s\n' "${HOME}/.var/app/org.signal.Signal/config/Signal/cleanframe-selection.css"
      ;;
    obsidian)
      printf '%s\n' "${HOME}/.config/obsidian/cleanframe-selection.css"
      ;;
    obsidian-flatpak)
      printf '%s\n' "${HOME}/.var/app/md.obsidian.Obsidian/config/obsidian/cleanframe-selection.css"
      ;;
    postman)
      printf '%s\n' "${HOME}/.config/Postman/cleanframe-selection.css"
      ;;
    postman-flatpak)
      printf '%s\n' "${HOME}/.var/app/com.getpostman.Postman/config/Postman/cleanframe-selection.css"
      ;;
    insomnia)
      printf '%s\n' "${HOME}/.config/Insomnia/cleanframe-selection.css"
      ;;
    insomnia-flatpak)
      printf '%s\n' "${HOME}/.var/app/rest.insomnia.Insomnia/config/Insomnia/cleanframe-selection.css"
      ;;
    code)
      printf '%s\n' "${HOME}/.config/Code/User/cleanframe-selection.css"
      ;;
    code-insiders)
      printf '%s\n' "${HOME}/.config/Code - Insiders/User/cleanframe-selection.css"
      ;;
    code-oss)
      printf '%s\n' "${HOME}/.config/Code - OSS/User/cleanframe-selection.css"
      ;;
    codium)
      printf '%s\n' "${HOME}/.config/VSCodium/User/cleanframe-selection.css"
      ;;
    codium-flatpak)
      printf '%s\n' "${HOME}/.var/app/com.vscodium.codium/config/VSCodium/User/cleanframe-selection.css"
      ;;
    cursor)
      printf '%s\n' "${HOME}/.config/Cursor/User/cleanframe-selection.css"
      ;;
    *)
      die "Valor invalido para --app: ${app} (use --list-apps)"
      ;;
  esac
}

if [[ "${ALL_KNOWN}" -eq 1 ]]; then
  while IFS= read -r app; do
    [[ -n "${app}" ]] && APP_FLAVORS+=("${app}")
  done < <(known_apps_all)
fi

# Deduplicate while preserving order
if [[ ${#APP_FLAVORS[@]} -gt 0 ]]; then
  dedup_apps=()
  for app in "${APP_FLAVORS[@]}"; do
    seen=0
    for added in "${dedup_apps[@]:-}"; do
      if [[ "${added}" == "${app}" ]]; then
        seen=1
        break
      fi
    done
    [[ "${seen}" -eq 0 ]] && dedup_apps+=("${app}")
  done
  APP_FLAVORS=("${dedup_apps[@]}")
fi

print_loader_hints() {
  local app="$1"
  local css_path="$2"

  case "${app}" in
    teams-for-linux)
      cat <<EOF
[HINT] teams-for-linux
- O wrapper precisa suportar CSS customizado (varia por versao/build).
- Se houver campo/flag de CSS customizado, aponte para:
  ${css_path}
- Procure nas preferencias por algo como "custom CSS", "user CSS" ou "inject CSS".
- Reinicie o app apos alterar o CSS.
EOF
      ;;
    ferdium)
      cat <<EOF
[HINT] Ferdium
- O CSS geralmente e aplicado por servico (Custom CSS do service/workspace).
- Cole o conteudo do arquivo abaixo no campo de Custom CSS do service (Teams/Slack/etc.):
  ${css_path}
- Se usar extensao/script externo de injecao, aponte esse arquivo e reinicie o Ferdium.
EOF
      ;;
    franz)
      cat <<EOF
[HINT] Franz
- Franz normalmente aplica CSS por recipe/service (Custom CSS).
- Cole o conteudo do arquivo abaixo no custom CSS do service ou use seu loader de CSS:
  ${css_path}
- Reinicie o Franz/service para recarregar estilos.
EOF
      ;;
    code|code-insiders|code-oss|codium|codium-flatpak|cursor)
      cat <<EOF
[HINT] ${app}
- Este arquivo CSS so sera usado se voce tiver um loader/extensao de custom CSS para VSCode/Codium/Cursor.
- Para tema nativo do editor, prefira o script:
  scripts/apply-vscode-selection-colors.sh
- Se for usar loader CSS, aponte para:
  ${css_path}
EOF
      ;;
    *-flatpak)
      cat <<EOF
[HINT] ${app}
- Preset Flatpak: o arquivo foi pensado para ficar dentro de ~/.var/app/... do app.
- O app/wrapper ainda precisa suportar CSS customizado/injecao.
- Se houver campo de custom CSS, aponte para:
  ${css_path}
- Reinicie o app apos alterar o CSS.
EOF
      ;;
    *-snap)
      cat <<EOF
[HINT] ${app}
- Preset Snap: arquivo em ~/snap/<app>/common para persistir entre revisoes.
- O app/wrapper ainda precisa suportar CSS customizado/injecao.
- Se houver campo de custom CSS, aponte para:
  ${css_path}
- Reinicie o app apos alterar o CSS.
EOF
      ;;
    generic|"")
      cat <<EOF
[HINT] Generic Electron/Chromium
- Configure seu wrapper/loader para injetar/carregar este arquivo CSS:
  ${css_path}
- Reinicie o app apos aplicar.
EOF
      ;;
    *)
      ;;
  esac
}

extract_env_output="$("${EXTRACTOR_SCRIPT}" --format env)"
eval "${extract_env_output}"

[[ -n "${CLEANFRAME_APP_SELECTION_BG:-}" ]] || die "Falha ao extrair CLEANFRAME_APP_SELECTION_BG"
[[ -n "${CLEANFRAME_APP_SELECTION_FG:-}" ]] || CLEANFRAME_APP_SELECTION_FG="#000000"

css_content() {
  cat <<EOF
/* Generated by ${SCRIPT_NAME} */
/* Source: CleanFrame GTK app-selection tokens (avoid accent/focus blue). */

:root {
  --cleanframe-app-selection-bg: ${CLEANFRAME_APP_SELECTION_BG};
  --cleanframe-app-selection-fg: ${CLEANFRAME_APP_SELECTION_FG};
}

::selection {
  background: var(--cleanframe-app-selection-bg) !important;
  color: var(--cleanframe-app-selection-fg) !important;
}

input::selection,
textarea::selection,
[contenteditable="true"]::selection {
  background: var(--cleanframe-app-selection-bg) !important;
  color: var(--cleanframe-app-selection-fg) !important;
}
EOF
}

log "[INFO] Selecao GTK -> Electron CSS"
log "  background: ${CLEANFRAME_APP_SELECTION_BG}"
log "  foreground: ${CLEANFRAME_APP_SELECTION_FG}"

if [[ "${PRINT_ONLY}" -eq 1 ]]; then
  css_content
  if [[ "${PRINT_LOADER_HINTS}" -eq 1 ]]; then
    echo
    if [[ ${#APP_FLAVORS[@]} -eq 0 ]]; then
      print_loader_hints "generic" "${OUTPUT_FILE}"
    else
      for app in "${APP_FLAVORS[@]}"; do
        print_loader_hints "${app}" "$(resolve_output_for_app "${app}")"
      done
    fi
  fi
  exit 0
fi

targets=()
if [[ ${#APP_FLAVORS[@]} -eq 0 ]]; then
  targets+=("generic|${OUTPUT_FILE}")
else
  if [[ "${OUTPUT_FILE}" != "${DEFAULT_OUTPUT_FILE}" && ${#APP_FLAVORS[@]} -gt 0 ]]; then
    if [[ ${#APP_FLAVORS[@]} -gt 1 ]]; then
      die "--output com multiplos --app/--all-known nao e suportado."
    fi
    targets+=("${APP_FLAVORS[0]}|${OUTPUT_FILE}")
  else
    for app in "${APP_FLAVORS[@]}"; do
      targets+=("${app}|$(resolve_output_for_app "${app}")")
    done
  fi
fi

log "[INFO] Alvos CSS: ${#targets[@]}"
for target in "${targets[@]}"; do
  app="${target%%|*}"
  path="${target#*|}"
  log "  - ${app}: ${path}"
done

if [[ "${DRY_RUN}" -eq 1 ]]; then
  log "[DRY-RUN] Nenhuma alteracao aplicada."
  if [[ "${PRINT_LOADER_HINTS}" -eq 1 ]]; then
    for target in "${targets[@]}"; do
      app="${target%%|*}"
      path="${target#*|}"
      print_loader_hints "${app}" "${path}"
    done
  fi
  exit 0
fi

for target in "${targets[@]}"; do
  app="${target%%|*}"
  path="${target#*|}"

  mkdir -p "$(dirname "${path}")"

  if [[ "${NO_BACKUP}" -eq 0 && -f "${path}" ]]; then
    cp -f "${path}" "${path}.bak"
    log "[INFO] Backup criado: ${path}.bak"
  fi

  tmp_file="$(mktemp /tmp/cleanframe-electron-selection.XXXXXX.css)"
  css_content > "${tmp_file}"
  mv -f "${tmp_file}" "${path}"
  log "[OK] CSS gerado para ${app}: ${path}"
done

log "[INFO] Configure cada wrapper/app para carregar o(s) arquivo(s) acima."
if [[ "${PRINT_LOADER_HINTS}" -eq 1 ]]; then
  for target in "${targets[@]}"; do
    app="${target%%|*}"
    path="${target#*|}"
    print_loader_hints "${app}" "${path}"
  done
fi
