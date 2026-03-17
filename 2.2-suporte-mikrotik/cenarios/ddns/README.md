# 🔄 Automação DynDNS Resiliente - MikroTik RouterOS v7

**O Impacto no Negócio:**
Para pequenas e médias empresas (PMEs), perder o acesso remoto à matriz ou filiais paralisa a operação, trava o faturamento e gera custos emergenciais com TI. Este script garante que o acesso externo via **DynDNS** esteja sempre disponível, com **custo zero de manutenção**, mesmo quando a operadora de internet não entrega um IP público direto no roteador.

**O Problema Técnico:**
Em cenários com múltiplos links (Dual-WAN) ou modems roteados (IP 192.168.x.x na porta WAN do MikroTik), o atualizador padrão do DynDNS falha por enviar o IP privado interno ou sofre *timeout* ao ser bloqueado pelos servidores do serviço.

**A Solução (Eficiência e Precisão):**
O script ignora o IP da interface física e utiliza a nuvem gratuita da MikroTik (`/ip cloud`) para descobrir o verdadeiro IP Público de saída. Em seguida, injeta um cabeçalho HTTP disfarçado (`User-Agent: curl`) para forçar o DynDNS a aceitar a atualização instantaneamente.

---

## ⚙️ Pré-requisitos
* Conta ativa no serviço **DynDNS**.
* Roteador MikroTik rodando **RouterOS v7** com internet.
* Recurso de nuvem da MikroTik ativado (Verifique em: **IP** > **Cloud** > marcar **DDNS Enabled**).
