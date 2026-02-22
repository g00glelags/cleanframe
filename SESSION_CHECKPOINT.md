# Checkpoint de Sessão - CleanFrame Theme

Data: 2026-02-20

## Estado Atual (concluído)

### Paleta / tokens semânticos
- Separação de seleção por contexto:
  - App selection: `#87CFFF` + texto preto
  - Calc cell selection override: `#00B8FF` + texto preto
  - Desktop selection: `#1A73E8` + texto branco
- Fundo de superfícies GTK suaves e barras:
  - `#FAFAFA`, `#E2E2E2`, `#E3DCD5` (onde aplicado)
- Calendário Cinnamon:
  - Selecionado: `#1F883D` com texto branco
  - Hover de dias escurecido progressivamente

### Correções de vazamento de cor
- Desktop rubberband (arrasto na área de trabalho) isolado de seleção de apps.
- Seleção em Nemo/Thunar fixada para token de app (`#87CFFF` + preto).
- Ajustes globais de `row:selected` em GTK3/GTK4 para evitar escurecimento indevido.

### Abas (tabs)
- Aba ativa/foco padronizada com token `#E6F7FF`.
- Aplicado em notebook/tabbar para Nemo/Thunar/XFCE Terminal/GNOME Terminal.

### Notas de manutenção (nuances de cor)
- Centralizar ajustes finos de cor em `src/_sass/_color-palette-default.scss` e evitar hardcode em arquivos de app.
- Tokens dedicados para manutenção futura:
  - `$notebook-tab-active-bg: #E6F7FF`
  - `$notebook-tab-inactive-bg: #E6E6E6`
  - `$app-selection-bg: #87CFFF`
  - `$calc-cell-selection-bg: #00B8FF`

### Botões de janela (min/max/close)
- Ícones padrão ativos:
  - minimizar: traço
  - maximizar: quadrado
  - fechar: x
- Maximizar forçado para quadrado em qualquer estado (normal/maximizada/meia tela/tile):
  - GTK (`maximize-symbolic` forçado no botão)
  - Metacity (`unmaximize` alinhado ao `maximize`)
  - Xfwm (`maximize-toggled-*` alinhado a `maximize-*`)
- Hover redondo restaurado e ampliado (círculo generoso).
- Bolinhas dos 3 botões restauradas no CSD GTK.

### GNOME 49 (base pronta)
- Criado alvo `shell-49-0`.
- Criado `bundle-49-0`.
- Criado `widgets-49-0` (baseado em 48 para evolução específica do 49).
- `core.sh` atualizado para detectar/suportar GNOME 49.
- `scripts/scss-smoke.sh` atualizado para 49.

## Arquivos-chave alterados (resumo)
- `src/_sass/_color-palette-default.scss`
- `src/_sass/_colors.scss`
- `src/_sass/gtk/_common-3.20.scss`
- `src/_sass/gtk/_common-4.0.scss`
- `src/_sass/gtk/apps/_nemo.scss`
- `src/_sass/gtk/apps/_gnome-4.0.scss`
- `src/_sass/gtk/apps/_libadwaita.scss`
- `src/_sass/gnome-shell/_bundle-49-0.scss`
- `src/_sass/gnome-shell/_widgets-49-0.scss`
- `src/gnome-shell/shell-49-0/gnome-shell.scss`
- `core.sh`
- `scripts/scss-smoke.sh`
- assets de ícones max/unmax em GTK/Metacity/Xfwm

## Validação feita
- `npm run build:scss:smoke` passando após os ajustes finais.

## Próximo passo sugerido (quando retomar)
1. Testar visualmente em sessão real GNOME 49 e ajustar somente `widgets-49-0` para divergências específicas.
2. Revalidar cache/instalação após cada ajuste visual (reinstalar tema + reiniciar sessão/apps alvo).
