# 📞 Como Configurar PABX (VoIP/SIP) no MikroTik RouterOS v7 em Cenários Dual-WAN

**O Problema (Impacto no Negócio):**
Em PMEs, ligações que ficam mudas ou caem após 30 segundos geram atrito no atendimento e perda de vendas. Na parte técnica, isso geralmente ocorre por dois motivos: o roteador tenta dividir a chamada entre dois links de internet (Balanceamento/PCC) ou corrompe os pacotes de voz usando o recurso nativo SIP ALG.

**A Solução:**
Criar um caminho limpo para a sinalização, fixar a saída de voz por um único link e desativar as interceptações nativas do MikroTik.

---

## 🛠️ Passo a Passo (Terminal)

### 1. Desativar o SIP ALG (O Vilão do Áudio Mudo)
O MikroTik possui um "ajudante" nativo para SIP que, na prática, corrompe os cabeçalhos em conexões NAT com servidores em nuvem. **Desative-o.**
```routeros
/ip firewall service-port disable sip
```
