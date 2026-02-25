#!/usr/bin/env bash
set -euo pipefail

# Applies CleanFrame GTK-derived selection colors into VSCode-compatible
# settings.json without overwriting unrelated user settings.

SCRIPT_NAME="$(basename "$0")"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXTRACTOR_SCRIPT="${REPO_DIR}/scripts/extract-gtk-selection-snippet.sh"

DRY_RUN=0
NO_BACKUP=0
SETTINGS_FILE=""
APP_FLAVOR="auto"

usage() {
  cat <<EOF
Uso:
  ${SCRIPT_NAME} [--settings-file PATH] [--app SABOR] [--dry-run] [--no-backup]

Objetivo:
  Ler a cor de selecao do GTK (CleanFrame) e aplicar em:
  workbench.colorCustomizations do VSCode/Code OSS/VSCodium.

Opcoes:
  --settings-file PATH   Caminho exato do settings.json (prioridade maxima)
  --app SABOR            auto | code | code-insiders | code-oss | codium | cursor
  --dry-run              Mostra o alvo e as cores, sem gravar
  --no-backup            Nao cria backup .bak
  -h, --help             Exibe esta ajuda

Exemplos:
  ${SCRIPT_NAME}
  ${SCRIPT_NAME} --app codium
  ${SCRIPT_NAME} --settings-file "\$HOME/.config/Code/User/settings.json"
EOF
}

die() {
  printf 'ERRO: %s\n' "$*" >&2
  exit 1
}

log() {
  printf '%s\n' "$*"
}

has_command() {
  command -v "$1" >/dev/null 2>&1
}

while [[ $# -gt 0 ]]; do
  case "${1:-}" in
    --settings-file)
      SETTINGS_FILE="${2:-}"
      [[ -n "${SETTINGS_FILE}" ]] || die "Informe um caminho para --settings-file"
      shift 2
      ;;
    --app)
      APP_FLAVOR="${2:-}"
      [[ -n "${APP_FLAVOR}" ]] || die "Informe um valor para --app"
      shift 2
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
has_command python3 || die "python3 nao encontrado."

resolve_settings_file() {
  if [[ -n "${SETTINGS_FILE}" ]]; then
    printf '%s\n' "${SETTINGS_FILE}"
    return 0
  fi

  local candidates=()
  case "${APP_FLAVOR}" in
    auto)
      candidates=(
        "${HOME}/.config/Code/User/settings.json"
        "${HOME}/.config/Code - Insiders/User/settings.json"
        "${HOME}/.config/Code - OSS/User/settings.json"
        "${HOME}/.config/VSCodium/User/settings.json"
        "${HOME}/.config/Cursor/User/settings.json"
      )
      ;;
    code)
      candidates=("${HOME}/.config/Code/User/settings.json")
      ;;
    code-insiders)
      candidates=("${HOME}/.config/Code - Insiders/User/settings.json")
      ;;
    code-oss)
      candidates=("${HOME}/.config/Code - OSS/User/settings.json")
      ;;
    codium)
      candidates=("${HOME}/.config/VSCodium/User/settings.json")
      ;;
    cursor)
      candidates=("${HOME}/.config/Cursor/User/settings.json")
      ;;
    *)
      die "Valor invalido para --app: ${APP_FLAVOR}"
      ;;
  esac

  local c
  for c in "${candidates[@]}"; do
    if [[ -f "${c}" ]]; then
      printf '%s\n' "${c}"
      return 0
    fi
  done

  # If nothing exists, return the first candidate so the script can create it.
  [[ ${#candidates[@]} -gt 0 ]] || die "Nenhum alvo de settings conhecido."
  printf '%s\n' "${candidates[0]}"
}

SETTINGS_FILE="$(resolve_settings_file)"
SETTINGS_DIR="$(dirname "${SETTINGS_FILE}")"

extract_env_output="$("${EXTRACTOR_SCRIPT}" --format env)"
eval "${extract_env_output}"

[[ -n "${CLEANFRAME_APP_SELECTION_BG:-}" ]] || die "Falha ao extrair CLEANFRAME_APP_SELECTION_BG"
[[ -n "${CLEANFRAME_APP_SELECTION_FG:-}" ]] || CLEANFRAME_APP_SELECTION_FG="#000000"

log "[INFO] settings.json alvo: ${SETTINGS_FILE}"
log "[INFO] Selecao GTK -> VSCode"
log "  background: ${CLEANFRAME_APP_SELECTION_BG}"
log "  foreground: ${CLEANFRAME_APP_SELECTION_FG}"

if [[ "${DRY_RUN}" -eq 1 ]]; then
  log "[DRY-RUN] Nenhuma alteracao aplicada."
  exit 0
fi

mkdir -p "${SETTINGS_DIR}"

if [[ "${NO_BACKUP}" -eq 0 && -f "${SETTINGS_FILE}" ]]; then
  cp -f "${SETTINGS_FILE}" "${SETTINGS_FILE}.bak"
  log "[INFO] Backup criado: ${SETTINGS_FILE}.bak"
fi

tmp_file="$(mktemp /tmp/cleanframe-vscode-settings.XXXXXX.json)"

python3 - "${SETTINGS_FILE}" "${tmp_file}" "${CLEANFRAME_APP_SELECTION_BG}" "${CLEANFRAME_APP_SELECTION_FG}" <<'PY'
import json
import sys
from pathlib import Path

settings_path = Path(sys.argv[1])
out_path = Path(sys.argv[2])
bg = sys.argv[3]
fg = sys.argv[4]

keys = {
    "editor.selectionBackground": bg,
    "editor.inactiveSelectionBackground": bg,
    "list.activeSelectionBackground": bg,
    "list.inactiveSelectionBackground": bg,
    "list.hoverBackground": bg,
    "list.activeSelectionForeground": fg,
    "list.inactiveSelectionForeground": fg,
    "list.hoverForeground": fg,
    "quickInputList.focusBackground": bg,
    "quickInputList.focusForeground": fg,
}

data = {}
if settings_path.exists():
    raw = settings_path.read_text(encoding="utf-8")
    if raw.strip():
      data = json.loads(raw)
      if not isinstance(data, dict):
          raise SystemExit("settings.json invalido: raiz JSON nao e objeto")

workbench = data.get("workbench.colorCustomizations")
if workbench is None:
    workbench = {}
elif not isinstance(workbench, dict):
    raise SystemExit("workbench.colorCustomizations existe, mas nao e objeto")

workbench.update(keys)
data["workbench.colorCustomizations"] = workbench

out_path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY

mv -f "${tmp_file}" "${SETTINGS_FILE}"
log "[OK] VSCode colorCustomizations atualizado com a selecao do GTK."

