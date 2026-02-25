# Contribuindo para o CleanFrame

Obrigado por contribuir.

O CleanFrame prioriza:

- coerencia visual
- legibilidade
- previsibilidade
- compatibilidade pratica entre interfaces/toolkits

Nao priorizamos "efeito visual" se isso aumentar risco de regressao (popup ilegivel,
dialog quebrado, selecao invisivel, etc.).

## Antes de abrir issue

1. Leia `README.md` e `docs/TEST_MATRIX.md`.
2. Verifique se o problema e de:
   - tema GTK (core)
   - integracao Qt
   - Flatpak
   - Electron (Slack/Teams/wrappers)
3. Confirme se o app suporta custom CSS/injecao (quando for Electron).
4. Tente reproduzir com:
   - tema atualizado (`./install.sh`)
   - reinicio do app
   - logout/login (Qt / environment.d)

## Como reportar bug (preferencial)

Use o template de issue de bug visual/compatibilidade.

Inclua:

- distro e versao
- desktop environment (GNOME/Cinnamon/XFCE etc.)
- app afetado e versao
- forma de instalacao do app (repo, Flatpak, Snap, AppImage)
- screenshots (antes/depois, popup/dialog/menu)
- passos exatos para reproduzir
- resultado esperado vs atual
- workaround (se existir)

## Severidade (como triamos)

Maior prioridade:

- texto ilegivel (ex.: branco em branco)
- popup/menu/dialog com contraste quebrado
- selecao invisivel
- input sem foco visivel

Media prioridade:

- inconsistencias de estilo sem perda de legibilidade
- pequenos desvios entre GTK3/GTK4/Qt

Menor prioridade:

- ajustes puramente esteticos sem impacto funcional

## Contribuindo com patch

Regras praticas:

- mantenha o tema claro (light-only)
- prefira fallback legivel a estilo agressivo
- documente limitacoes de apps proprietarios / Electron
- evite regressao em estados: hover, focus, selected, disabled, backdrop

Se alterar comportamento visivel:

1. Atualize `CHANGELOG.md` (secao `Unreleased`)
2. Atualize `README.md` se houver novo workaround/integracao
3. Atualize `docs/TEST_MATRIX.md` se o teste necessario mudou

## Testes recomendados para PR

Minimo:

- validar app GTK3 ou GTK4 impactado
- validar popup/dialog relacionado
- validar selecao e foco (se aplicavel)
- anexar screenshot(s)

Se mexer em integracoes:

- `bash -n` no script alterado
- `--dry-run` quando disponivel
- registrar se testou Qt/Flatpak/Electron

## Escopo de suporte (importante)

Integracoes para Slack/Teams/Electron sao "best effort".
Mudancas nessas apps podem quebrar custom CSS/preload entre versoes.

## Licenca e creditos

Ao contribuir, preserve notas de creditos/licenca do upstream e da adaptacao local.
Veja `docs/LICENSE_AND_CREDITS.md`.
