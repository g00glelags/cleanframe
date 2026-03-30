# CleanFrame - Guia para Agentes

## 1. Visao Geral

CleanFrame e um tema Linux `light-only` com foco em coerencia visual, legibilidade e previsibilidade. O objetivo principal nao e efeito visual agressivo; a prioridade e evitar regressao funcional em menus, dialogs, popups, inputs, tooltips, selecao e estados de foco.

O repositorio cobre multiplos alvos:

- GTK 2 / 3 / 4
- GNOME Shell (multiplas versoes)
- Cinnamon
- XFWM4
- Metacity
- Firefox `userChrome.css`
- GNOME Terminal
- integracoes para Qt, Flatpak, Snap e wrappers Electron

## 2. Stack Real

- Linguagens principais: `SCSS`, `CSS`, `Bash`, pequenos utilitarios em `Python`
- Build/lint: `npm`, `stylelint`
- Compilacao SCSS: `sass`, `npx sass` ou `sassc`
- Automacao operacional: `Makefile` + scripts em `scripts/`
- Instalacao: `install.sh` + bootstrap em `core.sh`

## 3. Arquitetura Atual

### Fonte canonica do tema

As fontes principais ficam em `src/_sass`. Os entrypoints sao finos:

- `src/gtk/3.0/gtk.scss` -> `src/_sass/gtk/_bundle-3.20.scss`
- `src/gtk/4.0/gtk.scss` -> `src/_sass/gtk/_bundle-4.0.scss`
- `src/cinnamon/cinnamon.scss` -> bundle em `src/_sass/cinnamon`
- `src/gnome-shell/shell-*/gnome-shell.scss` -> bundles por versao em `src/_sass/gnome-shell`

Regra pratica:

- prefira editar `src/_sass/**` quando a mudanca for compartilhada
- edite `src/gtk/**`, `src/cinnamon/**` e `src/gnome-shell/**` apenas para entrypoints, assets ou arquivos finais exigidos pelo alvo
- Firefox e algumas integracoes usam CSS fonte direto; nao trate tudo como artefato gerado

### Camada shell operacional

O bootstrap continua em `core.sh`, mas as responsabilidades foram modularizadas em `scripts/lib/`:

- `scripts/lib/metadata.sh` - metadados declarativos compartilhados
- `scripts/lib/common.sh` - helpers comuns e deteccao de compilador
- `scripts/lib/build.sh` - compilacao SCSS e normalizacao de CSS
- `scripts/lib/desktop.sh` - deteccao de versao e refresh de tema
- `scripts/lib/integrations.sh` - Flatpak, Snap e GNOME Terminal
- `scripts/lib/theme-install.sh` - montagem de artefatos e instalacao

### Pipeline de build

O projeto agora separa montagem e instalacao:

- `npm run build` ou `make build` montam artefatos em `build/`
- `install.sh` instala a partir do staged build, nao compila direto no destino final
- `build/` e artefato temporario local e nao entra no versionamento

Esse pipeline reduz risco de regressao, facilita depuracao e prepara empacotamento futuro.

### Metadados declarativos

Use `scripts/lib/metadata.sh` como fonte unica de verdade para:

- versoes suportadas do GNOME Shell
- mapeamento `major -> diretorio shell-*`
- labels de instalacao
- variantes XFWM

Se uma nova versao do GNOME Shell entrar no projeto, o primeiro ponto de ajuste deve ser esse arquivo.

## 4. Estrutura de Diretorios Chave

- `src/_sass/` - fonte principal de SCSS
- `src/gtk/3.0/` - entrypoint GTK3
- `src/gtk/4.0/` - entrypoint GTK4
- `src/gtk-2.0/` - tema GTK2 e assets legados
- `src/gnome-shell/shell-40-0` ate `shell-49-0` - variantes por versao do GNOME Shell
- `src/cinnamon/` - tema Cinnamon
- `src/xfwm4/` - decoracao XFWM4
- `src/firefox/` - customizacao Firefox
- `src/gnome-terminal/` - perfis/presets de terminal
- `scripts/` - comandos operacionais e auditorias
- `scripts/lib/` - modulos shell compartilhados
- `docs/` - matriz de testes, checklist de release e licenca/creditos
- `build/` - staged artifacts locais

## 5. Comandos Vitais

### Validacao

- `make check`
- `make check-strict`
- `make build`
- `make lint`
- `make scss-smoke`
- `npm run test`
- `npm run test:ci`
- `npm run build`
- `bash scripts/audit-theme-gaps.sh`
- `bash scripts/audit-color-leaks.sh`
- `bash scripts/audit-color-leaks.sh --strict`

### Instalacao e remocao

- `./install.sh`
- `./install.sh --shell 49 --sandbox`
- `./install.sh -A`
- `make install`
- `make uninstall`

### Higiene minima ao mexer em scripts

- `bash -n install.sh`
- `bash -n core.sh`
- `bash -n scripts/*.sh`
- `bash -n scripts/lib/*.sh`

### Novas Funcionalidades (Fase 1 - Estabilização)

- **Validação de pré-requisitos**: `make validate` ou `./install.sh` valida automaticamente
- **Fallback sem Perl**: Sistema funciona mesmo sem Perl (com normalização limitada)
- **Documentação de normalização CSS**: `docs/CSS_NORMALIZATION.md`
- **Script de atualização de versão**: `scripts/update-shell-version.sh [VERSÃO]`
- **Requisitos do sistema**: `REQUIREMENTS.md` com dependências e workarounds

Comandos novos:
- `make validate` - Valida pré-requisitos do sistema
- `bash scripts/update-shell-version.sh` - Mostra versões suportadas
- `bash scripts/update-shell-version.sh 50` - Cria estrutura para GNOME Shell 50

## 6. Convencoes de Engenharia

- Documentacao e notas operacionais em PT-BR.
- Codigo, nomes tecnicos e comentarios em ingles.
- O projeto e `light-only`. Nao introduza variante dark.
- Coerencia e legibilidade vencem estetica agressiva.
- Em mudancas visuais, sempre considerar `hover`, `focus`, `selected`, `disabled` e `backdrop`.
- Fallback legivel e melhor que customizacao elegante porem fragil.
- Integracoes de Electron/Slack/Teams sao `best effort`.
- Preserve creditos/licenca do upstream e da adaptacao local.

## 7. Regras Especificas para GTK/SCSS

- Evite espalhar hex literals novos; prefira tokens e helpers em `src/_sass/_colors.scss`.
- Antes de criar nova cor, confirme se ela pode ser derivada da palette atual.
- Mantenha separacao entre:
  - acento/foco geral
  - selecao de app/item
  - selecao dedicada do Calc
  - drop target / drag-and-drop
- A normalizacao de CSS pos-compilacao em `scripts/lib/build.sh` e parte da compatibilidade do produto. Nao remova isso sem validar runtimes antigos/libadwaita.
- Se mexer em CSS sensivel ao parser, valide especialmente:
  - `:not(...)`
  - pseudo-classes modernas
  - custom properties
  - `color-mix()`
  - artefatos do Dart Sass

## 8. Fonte da Verdade para Qualidade Visual

Arquivos obrigatorios para orientar alteracoes:

- `README.md`
- `CONTRIBUTING.md`
- `docs/TEST_MATRIX.md`
- `docs/RELEASE_CHECKLIST.md`
- `CHANGELOG.md`

Falhas criticas:

- texto ilegivel
- popup/menu/dialog ilegivel
- selecao invisivel
- input focado sem indicacao visual minima
- tooltip ilegivel

## 9. Fluxo Recomendado para Mudancas

1. Identifique o alvo: GTK, Shell, Cinnamon, XFWM, Firefox ou integracao externa.
2. Descubra se a mudanca e compartilhada (`src/_sass`) ou especifica de alvo.
3. Se a mudanca for operacional, escolha o modulo certo em `scripts/lib/`.
4. Edite o menor conjunto de fontes necessario.
5. Rode no minimo `make check`.
6. Se mexeu no pipeline shell/build, rode tambem `npm run build`.
7. Se houver risco de regressao ampla, rode `make check-strict`.
8. Se alterou comportamento visivel, atualize `CHANGELOG.md` e, se aplicavel, `README.md` ou `docs/TEST_MATRIX.md`.

## 10. Anti-Padroes

- editar arquivos instalados em `~/.themes` ou `/usr/share/themes` como fonte primaria
- introduzir hardcodes de cor sem passar pela palette/tokens
- duplicar mapeamentos de versao do GNOME Shell fora de `scripts/lib/metadata.sh`
- compilar direto no destino final quando o staged build resolve o caso
- focar apenas em screenshot e ignorar estados interativos
- assumir que Electron/Qt herdarao o tema sem integracao explicita
- remover fallbacks legados sem validar impacto em GTK2/GTK3/GTK4
- mudar creditos/licenca do upstream

## 11. Comandos e Arquivos para Investigacao Rapida

- `rg --files src scripts docs`
- `rg -n "selection|focus|tooltip|orchis|shell-" src scripts docs`
- `find src -maxdepth 2 -type d | sort`
- `sed -n '1,220p' package.json`
- `sed -n '1,240p' Makefile`
- `sed -n '1,240p' install.sh`
- `sed -n '1,260p' core.sh`
- `sed -n '1,260p' scripts/lib/theme-install.sh`
- `sed -n '1,220p' scripts/lib/metadata.sh`

## 12. Resumo Operacional

Se um agente for alterar o projeto, a abordagem correta e:

- tratar `src/_sass` como a espinha dorsal do design system
- tratar `scripts/lib/` como a espinha dorsal operacional
- usar `make check` como validacao minima
- usar `npm run build` quando mexer no pipeline de montagem/instalacao
- manter o projeto claro, legivel e conservador
- documentar qualquer workaround novo para sandbox, Qt ou Electron
