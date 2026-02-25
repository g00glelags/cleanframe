# Changelog

Todas as mudancas relevantes deste projeto devem ser registradas aqui.

Este arquivo segue a ideia de "Keep a Changelog" e versionamento semantico
quando aplicavel.

## [Unreleased]

### Added

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
