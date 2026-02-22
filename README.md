# CleanFrame theme

## Installation

Para instalar o tema, execute:

```bash
./install.sh
```

## Presets para Flatpak e Snap

O instalador pode aplicar presets de ambiente para melhorar a consistencia do tema em apps sandbox.

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

## Variante dedicada para LibreOffice Calc

Para manter a selecao geral do sistema e usar outra cor apenas no Calc:

```bash
# 1) instale/atualize o tema base
./install.sh

# 2) gere a variante CleanFrame-Light-Calc (selecao #00b8ff)
./scripts/install-calc-theme-variant.sh

# 3) abra o Calc forçando a variante
./scripts/run-calc-with-theme.sh
```

Opcional:

- Alterar a cor da selecao do Calc:

```bash
CALC_SELECTION_BG='#00b8ff' ./scripts/install-calc-theme-variant.sh
```

## FileZilla (modo seguro)

Se o FileZilla apresentar bug visual (drop target preto / renomear deformado), rode com launcher isolado:

```bash
./scripts/run-filezilla-safe.sh
```

Opcional (testar com seu tema atual):

```bash
FILEZILLA_GTK_THEME='CleanFrame-Light' ./scripts/run-filezilla-safe.sh
```
