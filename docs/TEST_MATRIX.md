# Matriz de Testes (CleanFrame)

Objetivo: validar coerencia visual e legibilidade, nao apenas estetica.

## Regra de Aceite (Core)

Falha critica se ocorrer qualquer caso abaixo:

- texto branco em fundo branco (ou contraste ilegivel)
- popup/dialog/menu com texto ilegivel
- selecao invisivel ou quase invisivel
- input focado sem indicacao visual minima
- tooltip ilegivel

## Ambientes Prioritarios

- GNOME (GTK-first)
- Cinnamon
- XFCE

Qt-first (KDE/LXQt) pode ser validado, mas nao e alvo principal de coercao visual.

## Matriz Minima por Release

### 1) GTK (Core)

- [ ] GTK3 app (ex.: Thunar/Nemo/FileZilla)
- [ ] GTK4 app (ex.: Text Editor / app GNOME recente)
- [ ] Menus contextuais legiveis
- [ ] Dialogs (abrir/salvar) legiveis
- [ ] Tooltips legiveis
- [ ] Inputs focados legiveis
- [ ] Selecao de texto (`#A6E4FF`) legivel
- [ ] Lista/linha selecionada legivel
- [ ] Disabled/read-only distinguiveis
- [ ] Backdrop window (janela sem foco) ainda legivel

### 2) Terminal

- [ ] GNOME Terminal com selecao legivel
- [ ] Highlight foreground/background corretos
- [ ] Cursor/foreground/background permanecem legiveis

### 3) Flatpak

- [ ] 1 app GTK via Flatpak com tema aplicado
- [ ] Sem regressao visual em menu/dialog
- [ ] `flatpak override --user --show` contem `GTK_THEME` e filesystems necessarios

### 4) Qt (Coerencia)

- [ ] `~/.config/environment.d/90-qt-gtk-coherence.conf` presente
- [ ] App Qt abre com visual coerente (ex.: Telegram, VLC, qBittorrent)
- [ ] Inputs e dialogs legiveis
- [ ] Sem texto branco em fundo branco

### 5) Electron / Wrappers (Best Effort)

- [ ] CSS de selecao gerado (`cleanframe-selection.css`)
- [ ] Teams wrapper (ou equivalente) carrega custom CSS
- [ ] Slack (normal/Flatpak) injeta CSS quando `ssb-interop.js` for suportado
- [ ] Selecao de texto visivel em editor/input/webview

## Estados Visuais a Conferir (Checklist rapido)

- [ ] normal
- [ ] hover
- [ ] active
- [ ] focus
- [ ] selected
- [ ] disabled
- [ ] backdrop/inactive
- [ ] warning/error dialogs

## Evidencias Recomendadas

- screenshot do desktop (file manager + menu)
- screenshot de dialog/popup
- screenshot do terminal selecionando texto
- screenshot de app Electron com selecao aplicada
- notas de versao do app/DE testado

## Template de Registro (por teste)

- Ambiente:
- Distro:
- Desktop:
- Versao GTK/Qt (se relevante):
- App testado:
- Resultado:
- Falhas:
- Workaround:
