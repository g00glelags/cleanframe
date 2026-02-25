# Licenca e Creditos (CleanFrame)

## Resumo

O CleanFrame e um trabalho derivado/adaptado sobre uma base de tema existente
(Orchis), com customizacoes focadas em:

- tema claro (light-only)
- coerencia visual
- legibilidade e comportamento previsivel
- integracoes praticas para apps que nao seguem GTK automaticamente

## Upstream / Base Original

Base observada neste repositorio:

- `original/Orchis-theme-master/`

Referencias locais:

- `original/Orchis-theme-master/README.md`
- `original/Orchis-theme-master/COPYING`

No README upstream, Orchis tambem menciona origem historica relacionada
(`materia-theme`). Essa cadeia deve ser preservada nas notas de credito quando
for relevante para distribuicao publica.

## Licenca

Este repositorio inclui `COPYING` com GNU GPL v3 (GPL-3.0).

Antes de uma release publica comunitaria:

- confirme se todos os arquivos derivados continuam compativeis com GPL-3.0
- mantenha avisos de copyright/licenca exigidos pelo upstream
- registre claramente que houve modificacoes locais e a data/escopo das mudancas

## Notas de Adaptacao (CleanFrame)

Sugestao de politica para release:

- manter creditos ao projeto upstream (Orchis) de forma visivel no README
- descrever que CleanFrame e uma variante/adaptacao com objetivo funcional
- listar customizacoes principais (coerencia visual, selecao, scripts de integracao)
- nao remover referencias historicas quando ainda houver heranca de codigo/assets

## Itens para Revisao antes de publicar

- `README.md`: secao de creditos/licenca
- `CHANGELOG.md`: deixar claro o que foi modificado no fork/adaptacao
- scripts novos: manter cabecalhos e autoria local quando necessario
- assets herdados: verificar se algum exige atribuicao adicional

## Observacao de Suporte

Integracoes de Slack/Teams/Electron podem depender de recursos nao-oficiais
(custom CSS / preload interop) e variam por versao. Isso deve aparecer como
"best effort" na documentacao para evitar promessas incorretas.
