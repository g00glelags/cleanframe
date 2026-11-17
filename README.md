# CleanFrame Theme

[![License: GPL-3.0](https://img.shields.io/badge/License-GPL_v3-blue.svg)](COPYING)
[![Theme: Light-Only](https://img.shields.io/badge/Theme-Light--Only-success.svg)](#principios)
[![GNOME Shell](https://img.shields.io/badge/GNOME_Shell-40_to_49-orange.svg)](#escopo)
[![GTK Support](https://img.shields.io/badge/GTK-2%20%7C%203%20%7C%204-purple.svg)](#escopo)

Tema claro para Linux com foco em coerência visual, legibilidade e previsibilidade no uso diário.

O objetivo do CleanFrame não é ser o tema "mais bonito" ou repleto de efeitos translúcidos que cansam a visão. O objetivo é ser **confiável**: menus, popups, caixas de diálogo, seleções, entradas de texto, terminais e widgets devem permanecer nítidos, legíveis e com contraste impecável no maior número de interfaces possível (GTK 2/3/4, Qt, Flatpak, Snap e apps Electron).

---

### Mantenedor / Autor da Adaptação:
- **Autor:** Marcos Sfair Mariani (`sfairmm`)
- **E-mail:** [g00gle.lags@gmail.com](mailto:g00gle.lags@gmail.com)
- **Telegram:** [@sfairmm](https://t.me/sfairmm)
- **Repositório GitHub:** [https://github.com/g00glelags/cleanframe](https://github.com/g00glelags/cleanframe)
- **Espelho Codeberg:** [https://codeberg.org/g00gle_lags/cleanframe](https://codeberg.org/g00gle_lags/cleanframe)

---

## Princípios

- Tema claro apenas (light-only)
- Coerencia visual acima de efeitos visuais
- Legibilidade e contraste como prioridade
- Fallback seguro quando um app nao herda tema automaticamente
- Integracoes extras documentadas (Qt, Flatpak, Electron)

## Escopo

O repositorio contem:

- tema base (GTK/Cinnamon/XFWM/GNOME Shell e variantes relacionadas)
- scripts de integracao e compatibilidade (Qt/GTK, Flatpak, Electron, terminal)
- scripts de troubleshooting para apps especificos

## Instalacao Rapida

```bash
./install.sh
```

## Presets para Flatpak e Snap

O instalador pode aplicar presets de ambiente para melhorar a consistencia do
tema em apps sandbox.

```bash
# Flatpak (GTK_THEME + permissoes de leitura de tema/config)
./install.sh --flatpak

# Snap (gera preset em ~/.config/environment.d)
./install.sh --snap

# Ambos
./install.sh --sandbox
```

Observacoes:

- `--flatpak` usa `flatpak override --user`.
- `--snap` cria `~/.config/environment.d/90-cleanframe-theme.conf` com `GTK_THEME=CleanFrame-Light`.
- No Snap, pode ser necessario encerrar sessao e entrar novamente para o ambiente propagar.

## Integracoes Comunitarias (Qt / Flatpak / Electron)

Para aproximar a coerencia visual em apps que nao seguem GTK automaticamente:

```bash
bash scripts/apply-community-integrations.sh
```

Exemplos:

```bash
# Apenas Qt/GTK (sem instalar pacotes)
bash scripts/apply-community-integrations.sh --qt

# Apenas CSS de selecao para wrappers Electron
bash scripts/apply-community-integrations.sh --electron

# Gerar CSS para todos os presets conhecidos do script Electron
bash scripts/apply-community-integrations.sh --electron --electron-all-known

# Habilitar injecao de CSS no Slack (normal + Flatpak), quando suportado
bash scripts/apply-community-integrations.sh --slack-interop
```

Importante:

- Apps Electron (Slack/Teams/wrappers) normalmente nao herdam a selecao GTK do conteudo web.
- O CleanFrame gera CSS de selecao, mas o app precisa suportar custom CSS / injecao.
- `teams-for-linux` costuma suportar `custom.css`; Slack pode exigir `ssb-interop.js`.

## Limites Conhecidos (Importante para suporte)

- Qt precisa de sessao com variaveis de ambiente carregadas (`~/.config/environment.d`), geralmente apos logout/login.
- Flatpak pode exigir override e permissao de leitura do tema/config.
- Electron depende de suporte da versao/build para custom CSS ou preload interop.
- Nem todo widget interno de app proprietario respeita o tema do sistema.

## Variante Dedicada para LibreOffice Calc

Para manter a selecao geral do sistema e usar outra cor apenas no Calc:

```bash
# 1) instale/atualize o tema base
./install.sh

# 2) gere a variante CleanFrame-Light-Calc (selecao #00b8ff)
./scripts/install-calc-theme-variant.sh

# 3) abra o Calc forcando a variante
./scripts/run-calc-with-theme.sh
```

Opcional:

```bash
CALC_SELECTION_BG='#00b8ff' ./scripts/install-calc-theme-variant.sh
```

## FileZilla (Modo Seguro)

Se o FileZilla apresentar bug visual (drop target preto / renomear deformado),
rode com launcher isolado:

```bash
./scripts/run-filezilla-safe.sh
```

Opcional (testar com seu tema atual):

```bash
FILEZILLA_GTK_THEME='CleanFrame-Light' ./scripts/run-filezilla-safe.sh
```

## Empacotamento e Build para Distribuição Comunitária

Para gerar o build do tema e criar os arquivos compactados prontos para distribuição comunitária (GitHub Releases, Gnome-Look / Pling):

```bash
# Compilar tema montado em build/
make build

# Gerar pacotes de distribuição (.tar.xz e .zip) em dist/
make package
```

## Release Comunitária

Documentos de referência para testes, validação e licenciamento:

- `CREDITS.md` - Atribuições e créditos completos
- `COPYING` - Licença GNU General Public License v3.0
- `docs/TEST_MATRIX.md` - Matriz de testes em GTK, Cinnamon e Shell
- `docs/RELEASE_CHECKLIST.md` - Checklist pré-release
- `docs/LICENSE_AND_CREDITS.md` - Conformidade de licenciamento e upstream

## Licença e Créditos

CleanFrame é um software livre distribuído sob a licença **GNU General Public License v3.0 (GPL-3.0)**.

O projeto é mantido por **sfairmm** ([g00gle.lags@gmail.com](mailto:g00gle.lags@gmail.com)) e deriva respeitosamente de grandes trabalhos da comunidade:
- **Orchis Theme** por Vince Liuice ([@vinceliuice](https://github.com/vinceliuice))
- **Materia Theme** por nana-4 ([@nana-4](https://github.com/nana-4))
- **Firefox GNOME Theme** por Rafael Mardojai e Sai Kurogetsu
- **Adwaita / GNOME Shell** por GNOME Design Team / Red Hat, Inc.

Veja a lista completa de contribuições e notas legais em [CREDITS.md](CREDITS.md) e [COPYING](COPYING).
