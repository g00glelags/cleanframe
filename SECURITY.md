# Security Policy

## Escopo

Este projeto e um tema visual + scripts de integracao local.
Nao e um servidor e nao processa dados remotos por design.

Mesmo assim, levamos seguranca em serio para evitar:

- scripts destrutivos por engano
- sobrescrita inesperada de arquivos de usuario
- instrucoes inseguras de shell/documentacao

## Como reportar problema de seguranca

Se voce identificar um problema de seguranca (script perigoso, instrucoes arriscadas,
sobrescrita indevida, uso inseguro de caminhos/arquivos), abra uma issue com o prefixo:

- `[security]`

Se preferir nao publicar detalhes imediatamente, descreva impacto e contexto minimo
sem PoC destrutiva, e proponha uma forma de contato segura no texto da issue.

## O que reportar aqui

- script que pode sobrescrever arquivos sem backup/consentimento
- comando/documentacao que incentive pratica perigosa
- uso inseguro de paths temporarios/permissoes
- regressao que exponha dados locais por configuracao incorreta

## Fora de escopo (geralmente)

- bugs visuais/contraste (use template de bug visual)
- incompatibilidade com apps de terceiros sem impacto de seguranca
- alteracoes de UI sem efeito de seguranca

## Diretrizes de manutencao (projeto)

- preferir `--dry-run` em scripts que alteram configuracoes locais
- criar backup quando sobrescrever arquivos de usuario
- evitar comandos destrutivos por padrao
- documentar claramente limitacoes e efeitos colaterais
