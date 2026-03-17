## 🛠️ Passo a Passo (Terminal)

### 1. Desativar o SIP ALG (O Vilão do Áudio Mudo)
O MikroTik possui um "ajudante" nativo para SIP que, na prática, corrompe os cabeçalhos em conexões NAT com servidores em nuvem. **Desative-o.**
```routeros
/ip firewall service-port disable sip
```

### 2. Isolar o IP do Servidor (Address List)
Trabalhar com Address Lists mantém o firewall organizado e facilita manutenções futuras.
(Exemplo apontando para o servidor 200.15.15.15)

```routeros
/ip firewall address-list
add address=200.15.15.15 list=PABX_EXTERNO
```
### 3. Liberar as Portas (Firewall Filter)
A telefonia exige portas para Sinalização (fazer a chamada tocar) e RTP (o tráfego do áudio).

- Sinalização: 5060 (TCP e UDP)
- Voz (RTP): 10000 a 40000 (UDP)

```routeros
/ip firewall filter
add chain=forward action=accept protocol=udp dst-port=5060 dst-address-list=PABX_EXTERNO comment="PABX - Sinalizacao UDP"
add chain=forward action=accept protocol=tcp dst-port=5060 dst-address-list=PABX_EXTERNO comment="PABX - Sinalizacao TCP"
add chain=forward action=accept protocol=udp dst-port=10000-40000 dst-address-list=PABX_EXTERNO comment="PABX - Voz RTP"
```

Observação: Em alguns cenários, as portas de VOZ (RTP), podem mudar, sempre validar com o provedor da solução VoIP PABX.

### 4. Proteger contra Quedas no Balanceamento (Mangle Bypass)
Se você utiliza PCC (Múltiplos Links), a voz não pode sofrer balanceamento. Se a rota mudar no meio da ligação, ela cai. Esta regra força o PABX a usar sempre a tabela de roteamento principal.

```routeros
/ip firewall mangle
add chain=prerouting action=accept dst-address-list=PABX_EXTERNO comment="Bypass PABX - Forcar tabela Main" place-before=0
```

✅ Resultado Esperado: Comunicação bilateral limpa, sem atrasos (jitter) causados por inspeção profunda de pacotes e estabilidade total em chamadas longas.
