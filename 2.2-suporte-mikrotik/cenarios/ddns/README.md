# Script: DynDNS para RouterOS v7 (IP Público Dinâmico / Ex: VIVO PPPoE)

**O problema real nas PMEs:**
Você precisa de acesso remoto confiável (Winbox, VPN, Servidores), mas a operadora entrega um **IP Público Dinâmico** (cenário clássico de links empresariais básicos ou residenciais via PPPoE, como a VIVO). 

O resultado prático? A operadora muda o seu IP periodicamente. Quando isso acontece, o endereço desatualiza, a conexão externa cai e a operação trava até que alguém descubra o novo IP. Contratar um link dedicado com **IP Fixo** só para resolver isso gera um custo mensal pesado e quase sempre inviável para pequenas e médias empresas.

**A solução:**
Automação com custo zero. Este script usa a nuvem da própria MikroTik para monitorar e descobrir o seu **IP Público atualizado**. Assim que a operadora muda o IP, o script detecta a alteração e força a atualização imediata no DynDNS via HTTP. O uso da tag (`User-Agent: curl`) mascara a origem e evita que o servidor do DynDNS bloqueie a requisição do roteador. 

---

## Pré-requisitos
* Conta ativa no **DynDNS**.
* Roteador MikroTik com **RouterOS v7**.
* Nuvem habilitada (Acesse **IP** > **Cloud** e marque **DDNS Enabled**).
