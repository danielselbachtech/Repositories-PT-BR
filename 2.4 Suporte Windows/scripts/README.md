# Scripts Windows

Este diretório contém scripts utilizados para **auditoria, diagnóstico e suporte operacional** em ambientes Windows.

## Tipos de scripts

- Scripts **read-only** (auditoria e coleta de evidências)
- Scripts de diagnóstico
- Scripts auxiliares para troubleshooting

Cada script deve indicar claramente no cabeçalho:
- Objetivo
- Se realiza ou não alterações no sistema
- Requisitos de execução
- Compatibilidade de versão

## Destaque

- `Invoke-WindowsServerReadOnlyAudit.ps1`
  - Auditoria completa de Windows Server
  - Execução segura em produção
  - Coleta de evidências em JSON e HTML
  - Compatível com Member Server e Domain Controller

## Boas práticas

- Executar sempre como administrador quando indicado
- Revisar o código antes da execução
- Não executar diretamente em produção sem validação prévia
