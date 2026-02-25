# Support (Suporte)

## Escopo de suporte do projeto

O CleanFrame prioriza suporte para:

- tema base e regressao de legibilidade (GTK/core)
- coerencia visual em ambientes GTK-first (GNOME, Cinnamon, XFCE)
- integracoes documentadas (Qt/Flatpak/Electron) em modo "best effort"

## O que e considerado bug de alta prioridade

- texto ilegivel (ex.: branco em branco)
- popup/menu/dialog com contraste quebrado
- selecao invisivel
- tooltip ilegivel
- foco invisivel em inputs/controles principais

## O que pode variar por versao/app

- Slack/Teams/wrappers Electron (custom CSS / preload / interop)
- apps proprietarios com widgets internos nao padronizados
- Qt em desktops/sessoes diferentes sem variaveis de ambiente carregadas
- Flatpak sem overrides/permissoes de leitura do tema

## Antes de pedir suporte

1. Atualize o tema e rode `./install.sh`
2. Se usar Qt, teste apos logout/login
3. Se usar Flatpak, aplique overrides/documentacao
4. Se usar Electron, confirme suporte da sua versao a custom CSS/injecao
5. Reproduza e colete screenshots

## Como pedir suporte / reportar problema

- Use os templates de issue em `.github/ISSUE_TEMPLATE/`
- Inclua ambiente completo (distro/DE/app/versao/packaging)
- Anexe screenshots do problema (popup/menu/dialog/selecao)
- Informe workaround, se encontrou

## Limite de suporte

Problemas em apps Electron/proprietarios podem exigir workarounds especificos por versao.
Nesses casos, o projeto pode documentar mitigacoes sem garantir solucao universal.
