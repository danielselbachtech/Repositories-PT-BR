# Suporte Windows

Este repositório concentra materiais técnicos relacionados a **suporte, administração, auditoria e troubleshooting de ambientes Windows**, com foco em **Windows Server** em produção.

O conteúdo aqui é direcionado a:
- Administração de sistemas
- Infraestrutura
- Segurança da informação
- Auditoria técnica
- Ambientes corporativos e críticos

## Princípios

Todo o conteúdo deste repositório segue os princípios abaixo:

- Foco em ambientes de produção
- Abordagem técnica e objetiva
- Prioridade para estabilidade e segurança
- Evita alterações destrutivas ou irreversíveis
- Scripts claramente identificados como *read-only* ou *change*
- Compatibilidade com versões suportadas do Windows Server

## Estrutura do Repositório
```bash
2.4.suporte-windows/
├── registro/
├── scripts/
├── tutoriais/
└── virtualizadores/
```

### registro
Conteúdo relacionado a **Windows Registry**, políticas, chaves relevantes para hardening, troubleshooting e auditoria.

### scripts
Scripts PowerShell e utilitários voltados a:
- Auditoria
- Diagnóstico
- Coleta de evidências
- Suporte operacional

### tutoriais
Guias técnicos e procedimentos operacionais documentados, com foco em:
- Boas práticas
- Passo a passo validado
- Cenários reais de suporte

### virtualizadores
Conteúdo específico para Windows executando sobre plataformas de virtualização, incluindo:
- VMware
- Hyper-V
- Outros hypervisors suportados

## Observações Importantes

- Sempre valide scripts e procedimentos em ambiente de homologação.
- Leia os comentários e o README específico de cada subdiretório antes de executar qualquer script.
- Alguns scripts exigem privilégios administrativos.
