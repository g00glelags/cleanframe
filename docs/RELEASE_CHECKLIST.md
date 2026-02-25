# Release Checklist (Comunidade)

Checklist para release do CleanFrame com foco em coerencia visual e previsibilidade.

## 1. Escopo e Posicionamento

- [ ] README descreve claramente que o tema e `light-only`
- [ ] README destaca objetivo: coerencia visual e legibilidade
- [ ] README explica limites de Qt/Flatpak/Electron (sem prometer magia)

## 2. Licenca e Creditos

- [ ] `COPYING` presente e consistente
- [ ] Creditos ao upstream (Orchis / historico base) documentados
- [ ] Notas de adaptacao local documentadas
- [ ] Nenhum credito/remocao indevida de autoria upstream

## 3. Build / Instalacao

- [ ] `./install.sh` funciona em ambiente limpo
- [ ] `./install.sh --flatpak` aplica overrides sem erro fatal
- [ ] `./install.sh --sandbox` documentado/testado
- [ ] Scripts principais executam sem erro de sintaxe (`bash -n`)

## 4. Integracoes Comunitarias

- [ ] `scripts/apply-community-integrations.sh` documentado
- [ ] Qt/GTK coherence validado
- [ ] Electron CSS gerado com selecao correta (`#A6E4FF`)
- [ ] Ajuste de `teams-for-linux` validado (quando arquivo existir)
- [ ] Slack `ssb-interop.js` validado (quando versao suportar)

## 5. Regressao Visual

- [ ] Matriz minima de `docs/TEST_MATRIX.md` executada
- [ ] Nenhum caso critico de legibilidade
- [ ] Menus/popups/dialogs/tooltips conferidos
- [ ] Terminal selecao conferida

## 6. Documentacao de Release

- [ ] `CHANGELOG.md` atualizado (versao + data + mudancas)
- [ ] Breaking changes/behavior changes listados
- [ ] Workarounds conhecidos listados
- [ ] "Known limitations" atualizadas

## 7. Publicacao

- [ ] Tag Git criada (`vX.Y.Z`)
- [ ] Release notes publicadas
- [ ] Screenshots anexados (uso real, nao apenas marketing)
- [ ] Checksum de pacote (opcional, recomendado)

## 8. Pos-release

- [ ] Issue template/coleta de ambiente definida
- [ ] Feedback de distros/DEs coletado
- [ ] Prioridades para patch release registradas
