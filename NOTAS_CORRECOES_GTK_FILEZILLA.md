# Notas de Correcoes (GTK / FileZilla / CleanFrame)

## Resumo desta rodada

### Corrigido

- `GTK4`:
  - Remocao/normalizacao de sintaxe que quebrava parser em algumas builds:
    - `:root { ... }` (custom properties)
    - `:not(a, b)` -> `:not(a):not(b)`
    - `:focus-within` / `:focus-visible` -> fallback `:focus`
    - `-gtk-outline-radius`
    - declaracoes com `var(--...)` e `color-mix(...)` (normalizacao conservadora)
- `GTK Inspector`:
  - corrigido bug de transparencia/translucidez do inspector em `GTK3` via overrides em `src/_sass/gtk/apps/_misc.scss`
- `FileZilla (wxWidgets/GTK3)`:
  - selecao customizada (fundo `#a6e4ff`, texto `#000000`) aplicada
  - edicao inline (rename) corrigida / texto legivel
  - removidos erros de parser introduzidos por fallback com `!important`
- `install.sh`:
  - modo fail-fast (`set -Ee -o pipefail`)
  - `trap ERR` com mensagem de linha/comando
  - ajuda de diagnostico para `Permission denied`
- `core.sh`:
  - validacao de permissao antes de instalar (evita falso "Done." com tema antigo)

### Nao corrigido (limitacao atual)

- `FileZilla`: ao arrastar pasta no **grid** (painel de subdiretorios), o destino ainda fica preto.
  - Foram testados overrides especificos e agressivos no tema GTK3.
  - Como o problema persiste mesmo com fallback amplo (`*:drop(active)` no escopo do FileZilla), a causa mais provavel e:
    - desenho customizado do `wxWidgets/FileZilla` (fora do alcance do CSS GTK), ou
    - widget com renderizacao que ignora estados CSS GTK esperados.

## Arquivos principais alterados nesta rodada

- `core.sh`
- `install.sh`
- `src/_sass/gtk/apps/_misc.scss`
- `src/_sass/gtk/apps/_calc-last.scss`

## Blocos temporarios (remover depois se necessario)

Em `src/_sass/gtk/apps/_calc-last.scss`:

- `TEMP(FileZilla wx grid DnD)`
- `TEMP(FileZilla wx grid selection)`

Esses blocos foram adicionados como fallback agressivo para teste/diagnostico.
Se causarem regressao visual em outros apps, podem ser removidos com seguranca.

## Observacoes sobre warnings restantes

- Warnings do tipo:
  - `GtkImage ... reported baselines ... -2147483648 ...`
- Esses warnings aparecem com `GTK_DEBUG=interactive` em alguns apps (ex.: `file-roller`) e **nao sao erro de parser CSS do tema**.
- Em geral sao warnings internos de layout/baseline do app/GTK.

## Comandos de validacao usados

```bash
# instalar tema (sem sudo, em ~/.themes)
./install.sh -A

# validar parser GTK4 (nao deve retornar os padroes antigos)
rg -n -- '^:root|var\(--|color-mix\(|:not\([^)]*,|-gtk-outline-radius|focus-within|focus-visible' \
  ~/.themes/CleanFrame-Light/gtk-4.0/gtk.css

# testar FileZilla
GTK_THEME=CleanFrame-Light filezilla

# testar inspector / file-roller
unset GTK_THEME
GTK_DEBUG=interactive file-roller
```
