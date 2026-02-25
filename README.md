# CleanFrame Theme

Tema claro com foco em coerencia visual e legibilidade no uso diario.

O objetivo do CleanFrame nao e ser o tema "mais bonito". O objetivo e ser
confiavel: menus, popups, dialogs, selecao, inputs, terminal e widgets devem
continuar legiveis e previsiveis no maior numero de interfaces possivel
(GTK/Qt/apps sandbox/Electron com integracao documentada).

## Principios

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

## Release Comunitaria (WIP)

Documentos para manter a release consistente com o proposito do projeto:

- `docs/TEST_MATRIX.md`
- `docs/RELEASE_CHECKLIST.md`
- `docs/LICENSE_AND_CREDITS.md`

## Licenca e Creditos

Este projeto deriva/adapta a base do tema Orchis (e historico relacionado).
Veja detalhes, creditos e notas de adaptacao em:

- `docs/LICENSE_AND_CREDITS.md`
- `COPYING`
- `original/Orchis-theme-master/README.md`
