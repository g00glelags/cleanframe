# Changelog

Todas as mudancas relevantes deste projeto devem ser registradas aqui.

Este arquivo segue a ideia de "Keep a Changelog" e versionamento semantico
quando aplicavel.

## [Unreleased]

### Added

- Arquivo raiz `CREDITS.md` com atribuições completas do mantenedor (`sfairmm`), histórico de projetos upstream (Orchis, Materia, Firefox GNOME Theme, Adwaita) e licenças de assets.
- Script de empacotamento `scripts/package-release.sh` e comando `make package` para gerar arquivos prontos para release comunitária (`.tar.xz`, `.zip` e `SHA256SUMS.txt` em `dist/`).
- Configuração de perfil e cores do terminal em modo light ativado por padrão no instalador (`install.sh`), com suporte à flag `--no-terminal` para desativar.
- Geracao automatica de `gtk-dark.css` apontando para `gtk.css` em GTK 3.0 e GTK 4.0 para evitar regressao para Adwaita Dark em apps com preferencia dark.
- Flag `-l, --libadwaita, --link` no `install.sh` (e inclusao no preset `-A / --all`) para vincular o tema em `~/.config/gtk-4.0`.
- Suporte a `gtk-dark.css` em `uninstall_link` e `link_libadwaita`.

### Fixed

- Correção do indicador de arrasto (*drag-and-drop*) na barra lateral de atalhos e listas do Thunar (`GtkTreeView`): remoção do hack de borda de 9999px que cobria os rótulos e itens com um bloco cinza monolítico, substituindo por uma linha indicadora limpa e precisa de 2px no topo (`.before`) e na base (`.after`) com fundo transparente.
- Destino de soltura no Thunar, Nemo e GTK3 genérico aperfeiçoado: para soltura dentro de pastas (`.into`), utiliza moldura suave com preenchimento translúcido sem encobrir texto ou ícones.
- Atualização da cor do indicador de soltura e borda de destino (`$drag-drop-target-outline`) para verde vibrante (`#35A854`), proporcionando contraste nítido e feedback visual imediato.
- Correção de emuladores de terminal baseados em VTE (GNOME Terminal, XFCE Terminal, Tilix) que ficavam pretos/escuros por falta de estilo de fallback no GTK; adicionadas regras explícitas de fundo claro (`$base`) e texto preto (`$text`) em `vte-terminal` e perfil padrão light no GNOME Terminal (`CleanFrame Light`).
- Correção da cor e contorno do nome do usuário no menu do Cinnamon (`.user-widget-label` e `.appmenu-sidebar-user-box`), definindo preto puro (`$black`) e `text-shadow: none` para eliminar texto branco ilegível e aberrações cromáticas em fundo claro.
- Suporte e estilização completa para o menu moderno do Cinnamon 6+ (`menu@cinnamon.org`) cobrindo as classes `.appmenu-*` (sidebar, categorias, botões de aplicativos, favoritos, busca e botões do sistema), restaurando a legibilidade e o alinhamento visual.
- Recarregamento automático e contínuo do tema no Cinnamon Shell via D-Bus (`RestartCinnamon`) e gsettings em `scripts/lib/desktop.sh`.
- Correção de truncamento e corrupção de regras CSS com seletores multilinha na etapa de otimização de build, eliminando erro de parsing no GTK3.
- Correção de incompatibilidade de sintaxe de pseudofunção `if(sass(...))` em 20 arquivos SCSS e remoção de flag de depreciação `if-function` no Dart Sass.
- Correção da verificacao prematura de `sassc` em `scripts/scss-smoke.sh`, permitindo uso direto do Dart Sass (`sass` ou `npx sass`).
- Correção da criação de diretório pai inexistente em `copy_theme_payload` (`scripts/lib/theme-install.sh`).
- Eliminacao da dependencia de `bc` em `scripts/lib/build.sh` (cálculo de reducao minificada via `awk`/Bash).
- Correcao do comando `sed` com glob no instalador do Whiskermenu em `scripts/lib/theme-install.sh`.
- Correcao da variavel `${lcolors[@]}` para `${colors[@]}` em `scripts/lib/theme-install.sh`.
- Atualizacao do teste de foco de entrada em `scripts/verify-installed-theme-colors.sh` para refletir a paleta atual (`#00AEEF`).
- Correcao do comentário de metadados em `index.theme` para a identidade do CleanFrame.
- Substituicao de literal `#f6f6f6` pelo token semantico `$surface-soft` em `src/_sass/_colors.scss`.

### Changed

- Desacoplamento do `npm` no `Makefile`: alvos de build, auditorias e testes executam scripts Bash/Python nativamente; `npm` e requerido apenas para `stylelint`.
- Normalizacao de fallback CSS movida para funcao nativa em `build.sh`, evitando geracao dinamica de scripts temporarios no diretorio do projeto.
- Atualizacao da matriz de testes `docs/TEST_MATRIX.md` com o token de selecao vigente (`#8FD9FF`).

- Manifesto e escopo comunitario no `README.md` (foco em coerencia visual e legibilidade).
- Script `scripts/apply-community-integrations.sh` para integrar Qt/Flatpak/Electron/Teams/Slack.
- Documentos de suporte para release:
  - `docs/TEST_MATRIX.md`
  - `docs/RELEASE_CHECKLIST.md`
  - `docs/LICENSE_AND_CREDITS.md`
- `CONTRIBUTING.md` com diretrizes de contribuicao focadas em regressao visual/legibilidade.
- Templates de issue para:
  - bug visual/compatibilidade
  - ajuste visual/melhoria
- `pull request template` para padronizar validacao de mudancas visuais/integracoes.
- `SUPPORT.md` e `SECURITY.md` com escopo de suporte e politica de reporte.

### Changed

- Documentacao reorganizada para explicitar limites de integracao em Qt/Flatpak/Electron.

### Notes

- Antes da primeira tag comunitaria, promover esta secao para uma versao (`vX.Y.Z`)
  com data e registrar os testes executados.
