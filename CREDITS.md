# Créditos e Autoria / Credits & Attribution

CleanFrame é um tema para Linux distribuído sob a licença **GNU General Public License v3.0 (GPL-3.0)**.
Este documento descreve a autoria da adaptação CleanFrame, os projetos upstream nos quais ela foi baseada e as atribuições de direitos autorais de todos os componentes inclusos.

---

## 1. Autor e Mantenedor do CleanFrame / CleanFrame Author & Maintainer

O **CleanFrame** foi adaptado, reestruturado e é mantido por:

- **Marcos Sfair Mariani** (`sfairmm`)
- **E-mail:** [g00gle.lags@gmail.com](mailto:g00gle.lags@gmail.com)
- **Telegram:** [@sfairmm](https://t.me/sfairmm)
- **Repositório GitHub:** [https://github.com/g00glelags/cleanframe](https://github.com/g00glelags/cleanframe)
- **Espelho Codeberg:** [https://codeberg.org/g00gle_lags/cleanframe](https://codeberg.org/g00gle_lags/cleanframe)

### Principais contribuições, modificações e inovações introduzidas no CleanFrame:
- **Filosofia estritamente Light-Only:** Remoção de variantes dark para garantir foco absoluto na legibilidade, contraste e eliminação de falhas de cor.
- **Engenharia de tokens e paleta semântica:**
  - Isolamento de seleção por contexto (`#87CFFF` para seleção de itens em apps com texto preto; `#00B8FF` para override do LibreOffice Calc; `#1A73E8` para rubberband da área de trabalho).
  - Eliminação de "color leaks" em menus, popups, tooltips, dialogs e inputs.
- **Pipeline de normalização GTK4 CSS:** Compatibilidade robusta com os parsers do GNOME Shell 40 ao 49 e runtimes libadwaita/GTK4 modernos (normalização de `:not()`, remoção segura de seletores que quebram parsers legados).
- **Compatibilidade e correções para apps específicos:**
  - Correção e launcher seguro para FileZilla (`run-filezilla-safe.sh`) mitigando bugs visuais do wxWidgets/GTK3.
  - Variante dedicada para LibreOffice Calc (`install-calc-theme-variant.sh`).
- **Automação de integrações com o ecossistema:**
  - Presets de consistência para Flatpak (`--flatpak`) e Snap (`--snap`).
  - Coerência Qt/GTK (`setup-qt-gtk-coherence.sh`).
  - Geração de CSS de seleção unificado para apps Electron (`apply-electron-selection-css.sh`, cobrindo Slack, Teams e outros).
  - Perfis para GNOME Terminal e XFCE Terminal.
- **Controles de janela aperfeiçoados:** Botão maximizar padronizado (quadrado consistente em qualquer estado), hover com raio ampliado e alinhamento perfeito entre GTK CSD, Metacity e XFWM4.
- **Pipeline modular de build e validação:** Separação entre montagem (`build/`) e instalação (`install.sh`), com scripts em `scripts/lib/` e suíte de auditorias (`make check`, `make validate`).

---

## 2. Projetos Upstream e Base Original / Upstream Foundations

O CleanFrame é uma obra derivada e utiliza como alicerce o trabalho de excelentes projetos da comunidade de software livre:

### Orchis Theme
- **Autor Original:** Vince Liuice ([@vinceliuice](https://github.com/vinceliuice))
- **Repositório:** [https://github.com/vinceliuice/Orchis-theme](https://github.com/vinceliuice/Orchis-theme)
- **Licença:** GNU General Public License v3.0 (GPL-3.0)
- **Contribuição:** Estrutura base de SCSS para GTK 2/3/4, GNOME Shell, Cinnamon e XFWM4. Wallpapers em `wallpaper/`.

### Materia Theme
- **Autor Original:** nana-4 ([@nana-4](https://github.com/nana-4))
- **Repositório:** [https://github.com/nana-4/materia-theme](https://github.com/nana-4/materia-theme)
- **Licença:** GNU General Public License v2.0 or later (GPL-2.0+)
- **Contribuição:** Origem histórica e conceitos de design de elevação Material que inspiraram a arquitetura SCSS original.

### Firefox GNOME Theme
- **Autores:** Rafael Mardojai ([@rafaelmardojai](https://github.com/rafaelmardojai)) e contribuidores; baseado no trabalho original de Sai Kurogetsu ([@kurogetsusai](https://github.com/kurogetsusai)).
- **Repositório:** [https://github.com/rafaelmardojai/firefox-gnome-theme](https://github.com/rafaelmardojai/firefox-gnome-theme)
- **Contribuição:** CSS integrado em `src/firefox/` para integração visual do navegador Firefox com a barra de títulos e botões GTK.

### GNOME Shell & Adwaita
- **Autores:** GNOME Design and Development Teams, Red Hat, Inc., Intel Corporation.
- **Licença:** GNU LGPL v2.1+ / GNU GPL v2.0+
- **Contribuição:** Definições base de widgets e estilos em `src/_sass/gnome-shell/`.

### Bridge Theme
- **Autor:** ScionicSpectre
- **Contribuição:** Definições herdadas do motor de estilo GTK2 em `src/gtk-2.0/gtkrc`.

---

## 3. Ícones e Recursos Visuais / Icons & Graphic Assets

- Os ícones simbólicos SVG inclusos nos diretórios de assets (`src/gnome-shell/assets/`, `src/cinnamon/assets/`, `src/firefox/chrome/CleanFrame/icons/`) são distribuídos sob **Creative Commons Attribution-ShareAlike 4.0 International (CC-BY-SA 4.0)** ou **GNU GPL v3.0**.
- Papéis de parede em `wallpaper/` foram desenhados por Vince Liuice como parte do projeto Orchis.

---

## 4. Declaração de Licença / License Notice

CleanFrame é software livre: você pode redistribuí-lo e/ou modificá-lo sob os termos da **GNU General Public License (GPL)** conforme publicada pela Free Software Foundation, versão 3 da licença, ou (a seu critério) qualquer versão posterior.

Este programa é distribuído na esperança de que seja útil, mas **SEM QUALQUER GARANTIA**; sem mesmo a garantia implícita de COMERCIABILIDADE ou ADEQUAÇÃO A UM DETERMINADO PROPÓSITO. Consulte o arquivo `COPYING` para obter todos os detalhes.
