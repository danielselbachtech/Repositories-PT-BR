# Windows – Auditoria de Segurança Read-Only

Script PowerShell para auditoria **somente leitura** de servidores Windows, focado em segurança, conformidade e visibilidade operacional.

O script foi projetado para **ambientes de produção**, sem realizar alterações no sistema operacional.

---

## 🎯 Objetivo

Fornecer uma visão técnica confiável do estado de segurança e configuração de servidores Windows, permitindo:
- Auditorias internas
- Compliance
- Baseline de segurança
- Due diligence
- Inventário técnico

---

## 🛡️ Princípios de segurança

- Modo **READ-ONLY (SAFE MODE)**
- Nenhuma modificação em:
  - Registro
  - Serviços
  - Políticas
  - Configurações de sistema
- Sem uso de `Invoke-Expression`
- Tratamento de erros e timeouts
- Evidências preservadas com metadados

---

## 🔍 Escopo da auditoria

- Informações do sistema operacional
- Último boot
- Hotfixes / Patches
- Windows Update
- Microsoft Defender
- Firewall (Domain / Private / Public)
- SMB (incluindo SMBv1)
- RDP e NLA
- TLS / Schannel
- Políticas de auditoria (`auditpol`)
- Contas locais
- Hash SHA256 dos artefatos

---

## ▶️ Execução

```powershell
# Entre no diretório, onde está o script e execute o comando abaixo
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "Invoke-WindowsServerAuditoriaReadOnly.ps1"
```

> A policy não é alterada no sistema.

📂 Saída
Os relatórios são gerados em:
```makefile
C:\Compliance\Audit\<RunId>\
```

Arquivos principais:
- audit_full.json
- summary.html
- transcript.txt
- arquivos .sha256

🌐 Relatório HTML
- Interface moderna e responsiva
- Charset UTF-8
- Indicadores visuais de status
- Compatível com navegadores modernos

⚠️ Observações
- Recomenda-se execução como Administrador
- Testar previamente em ambiente de homologação
- Ambientes com AppLocker/WDAC podem restringir comandos externos

📜 Licença
- Uso corporativo / interno.
- Adapte conforme a política da organização.
