# DynDNS para RouterOS v7 (Link VIVO / IP Dinâmico)

**O problema real nas PMEs:**
Você utiliza o serviço do **DynDNS** para garantir o acesso remoto confiável à infraestrutura (Winbox, VPN, Servidores). O problema é que o link da operadora (como o PPPoE da VIVO) entrega um **IP Público Dinâmico**.

O resultado prático? A operadora muda o seu IP periodicamente. Quando isso acontece, o apontamento no DynDNS fica desatualizado, a conexão externa cai e a operação trava. Contratar um link de internet com **IP Público Fixo** apenas para resolver essa troca de IPs gera um custo mensal maior para a empresa.

**A solução (Custo x Benefício):**
O serviço do **DynDNS** é pago, porém **uma única conta pode ser usada para gerenciar múltiplos clientes ou filiais**, diluindo o investimento drasticamente para quem presta suporte de TI.

Este script atua como um atualizador: usa a nuvem do próprio MikroTik apenas para checar qual é o seu IP público real no momento. Assim que detecta a mudança de IP pela operadora, ele força a atualização imediata no servidor do DynDNS via requisição HTTP, mascarando a origem (`User-Agent: curl`) para evitar bloqueios. O acesso remoto volta em segundos, sem intervenção humana.

**Tabela de Preços DynDNS (Referência: 17/03/2026):**
* 1 ano: **$55.00**
* 2 anos: **$99.00**
* 5 anos: **$220.00**
> *Visão de Negócio:* Dividindo um plano de $55 anuais entre vários clientes, o custo por PME se torna menor, substituindo a necessidade de valores adicionais nas faturas de links com IP Público Fixo.

---

## ⚙️ Pré-requisitos
* Conta ativa no **DynDNS** (Hostname, Usuário e Senha).
* Roteador MikroTik com **RouterOS v7**.
* Nuvem habilitada no roteador (Acesse **IP** > **Cloud** e marque **DDNS Enabled**).
