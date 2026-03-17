# DynDNS para RouterOS v7 (Bypass de IP Privado)

**O problema real nas PMEs:**
Você precisa de acesso remoto (Winbox via acesso local, VPN), mas o link da operadora entrega um modem roteado ou a conexão está atrás de um NAT (IP 192.168.x.x na sua porta WAN). 

O resultado prático? O atualizador nativo do DynDNS envia o IP interno da sua rede. O acesso externo cai, e a operação trava. Contratar um link com IP Público fixo só para resolver isso tem um custo para pequenas e médias empresas.

**A solução (Custo Zero):**
Este script usa a nuvem da própria MikroTik para descobrir qual é o seu **IP Público real** de saída. Em seguida, ele força a atualização no DynDNS via HTTP, mascarando a origem (`User-Agent: curl`) para evitar que o servidor do DynDNS bloqueie a requisição do roteador.

---

## Pré-requisitos
* Conta ativa no **DynDNS**.
* Roteador MikroTik com **RouterOS v7**.
* Nuvem habilitada (Acesse **IP** > **Cloud** e marque **DDNS Enabled**).
