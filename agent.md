# CleanFrame - Contexto Tecnico

## 1. Visao Geral

CleanFrame e um tema Linux `light-only` com foco em coerencia visual, legibilidade e previsibilidade. O objetivo do projeto nao e perseguir efeitos visuais agressivos; o criterio principal e evitar regressao funcional em menus, dialogs, popups, inputs, tooltips, selecao e estados de foco.

O repositorio cobre mais de um alvo visual:

- GTK 2 / 3 / 4
- GNOME Shell (multiplas versoes)
- Cinnamon
- XFWM4
- Metacity
- Firefox `userChrome.css`
- GNOME Terminal
- scripts de integracao para Qt, Flatpak, Snap e wrappers Electron

## 2. Stack Real

- Linguagens principais: `SCSS`, `CSS`, `Bash`, pequenos utilitarios em `Python`
- Build/lint: `npm`, `stylelint`
- Compilacao SCSS: `sass`, `npx sass` ou `sassc`
- Automacao operacional: `Makefile` + scripts em `scripts/`
- Instalacao: `install.sh` + helpers em `core.sh`

Dependencias observadas:

- `stylelint`
- `stylelint-config-standard-scss`
- compilador Sass disponivel no host

## 3. Arquitetura do Tema

### Fonte canonica

As fontes principais do tema ficam em `src/_sass`. Entrypoints finos apenas encaminham para bundles:

- `src/gtk/3.0/gtk.scss` -> `src/_sass/gtk/_bundle-3.20.scss`
- `src/gtk/4.0/gtk.scss` -> `src/_sass/gtk/_bundle-4.0.scss`
- `src/cinnamon/cinnamon.scss` -> bundle em `src/_sass/cinnamon`
- `src/gnome-shell/shell-*/gnome-shell.scss` -> bundles por versao em `src/_sass/gnome-shell`

Regra pratica:

- prefira editar `src/_sass/**` quando a mudanca for estrutural ou compartilhada
- edite `src/gtk/**`, `src/cinnamon/**` e `src/gnome-shell/**` apenas quando estiver tratando entrypoints, assets ou arquivos finais exigidos pelo alvo
- Firefox e parte das integracoes usam CSS fonte direto; nao trate tudo como artefato gerado

### Camadas relevantes

- `src/_sass/_colors.scss`: tokens, helpers de cor e regras de contraste
- `src/_sass/_variables.scss`: espacamentos, fontes, raios, sombras e timings
- `src/_sass/gtk/**`: widgets GTK, apps e compatibilidade GTK3/GTK4/libadwaita
- `src/_sass/gnome-shell/**`: widgets e bundles por versao do Shell
- `src/_sass/cinnamon/**`: estilo do Cinnamon
- `src/gtk/assets`, `src/gnome-shell/assets`, `src/cinnamon/assets`: assets de runtime
- `src/xfwm4`, `src/metacity-1`, `src/plank`: superficies complementares do tema

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
- `scripts/` - auditorias, integracoes e troubleshooters
- `docs/` - matriz de testes, checklist de release e licenca/creditos

## 5. Comandos Vitais

### Validacao

- `make check` - lint SCSS + color audit default + smoke compile
- `make check-strict` - lint SCSS + color audit estrito + smoke compile
- `make lint` - lint de `src/**/*.scss`
- `make scss-smoke` - compila entrypoints principais
- `npm run test`
- `npm run test:ci`
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
- `bash -n scripts/<arquivo>.sh`

## 6. Convencoes de Engenharia

- Documentacao e notas operacionais em PT-BR.
- Codigo, nomes tecnicos e comentarios em ingles.
- O projeto e `light-only`. Nao introduza variante dark.
- Coerencia e legibilidade vencem estetica agressiva.
- Em mudancas visuais, sempre considerar estados `hover`, `focus`, `selected`, `disabled` e `backdrop`.
- Fallback legivel e melhor que customizacao elegante porem fragil.
- Integracoes de Electron/Slack/Teams sao `best effort`; nao prometa heranca total de tema.
- Preserve creditos/licenca do upstream e da adaptacao local.

## 7. Regras Especificas para GTK/SCSS

- Evite espalhar hex literals novos em widgets; prefira tokens e helpers existentes em `src/_sass/_colors.scss`.
- Antes de criar nova cor, confirme se ela pode ser derivada da palette atual.
- Mantenha separacao entre:
  - acento/foco geral
  - selecao de app/item
  - selecao dedicada do Calc
  - drop target / drag-and-drop
- Lembre que `core.sh` aplica normalizacoes para compatibilidade GTK3/GTK4 apos compilacao. Nao remova isso sem validar runtimes antigos/libadwaita.
- Se mexer em parser-sensitive CSS, valide especialmente:
  - `:not(...)`
  - pseudo-classes modernas
  - custom properties
  - `color-mix()`
  - artefatos de compilacao do Dart Sass

## 8. Fonte da Verdade para Qualidade Visual

Arquivos obrigatorios para orientar qualquer alteracao:

- `README.md`
- `CONTRIBUTING.md`
- `docs/TEST_MATRIX.md`
- `docs/RELEASE_CHECKLIST.md`
- `CHANGELOG.md`

Falhas criticas segundo a matriz do projeto:

- texto ilegivel
- popup/menu/dialog ilegivel
- selecao invisivel
- input focado sem indicacao visual minima
- tooltip ilegivel

## 9. Fluxo Recomendado para Mudancas

1. Identifique o alvo: GTK, Shell, Cinnamon, XFWM, Firefox ou integracao externa.
2. Descubra se a mudanca e compartilhada (`src/_sass`) ou especifica de alvo.
3. Edite o menor conjunto de fontes necessario.
4. Rode no minimo `make check`.
5. Se houver risco de regressao ampla, rode `make check-strict` e `bash scripts/audit-theme-gaps.sh`.
6. Se alterou comportamento visivel, atualize `CHANGELOG.md` e, se aplicavel, `README.md` ou `docs/TEST_MATRIX.md`.

## 10. Anti-Padroes

- editar arquivos instalados em `~/.themes` ou `/usr/share/themes` como fonte primaria
- introduzir hardcodes de cor sem passar pela palette/tokens
- focar apenas em screenshot e ignorar estados interativos
- assumir que Electron/Qt herdarao o tema sem integracao explicita
- remover fallbacks legados sem validar impacto em GTK2/GTK3/GTK4
- mudar creditos/licenca do upstream

## 11. Comandos e Arquivos para Investigacao Rapida

- `rg --files src scripts docs`
- `rg -n "A6E4FF|selection|focus|tooltip|orchis" src scripts docs`
- `find src -maxdepth 2 -type d | sort`
- `sed -n '1,220p' package.json`
- `sed -n '1,260p' Makefile`
- `sed -n '1,260p' install.sh`
- `sed -n '1,260p' core.sh`

## 12. Resumo Operacional

Se um agente for alterar o tema, a abordagem correta e:

- tratar `src/_sass` como a espinha dorsal do design system
- usar `make check` como validacao minima
- manter o projeto claro, legivel e conservador
- documentar qualquer workaround novo para sandbox, Qt ou Electron
