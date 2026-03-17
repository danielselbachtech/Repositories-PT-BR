# 📞 Como Configurar PABX (VoIP/SIP) no MikroTik RouterOS v7 em Cenários Dual-WAN

**O Problema (Impacto no Negócio):**
Em PMEs, ligações que ficam mudas ou caem após 30 segundos geram atrito no atendimento e perda de vendas. Na parte técnica, isso geralmente ocorre por dois motivos: o roteador tenta dividir a chamada entre dois links de internet (Balanceamento/PCC) ou corrompe os pacotes de voz usando o recurso nativo SIP ALG.

**A Solução:**
Criar um caminho limpo para a sinalização, fixar a saída de voz por um único link e desativar as interceptações nativas do MikroTik.

> 📖 **Documentação Técnica:** [Clique aqui para ler o guia completo e resolver falhas de áudio no PABX](https://github.com/danielselbachoficial/Repositories-PT-BR/blob/main/2.2-suporte-mikrotik/cenarios/voip-pabx/configuracao.md)
