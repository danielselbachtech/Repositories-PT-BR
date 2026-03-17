## Como Implementar

### 1. Salvar o Script

Abra o Winbox e acesse System > Scripts.

Clique em (+) e defina o Name como Update_DynDNS.

Garanta que as opções read, write, policy e test estejam marcadas.

Cole o código e salve.

### 2. Criar a Automação (Scheduler)
Para garantir que a verificação ocorra sozinha de forma contínua:

Acesse System > Scheduler e clique em (+).

Name: Auto_DynDNS.

Interval: 00:05:00 (Verificação a cada 5 minutos).

On Event: Update_DynDNS (Tem que ser o nome exato do script).

Salve.

## Validação e Logs
Abra o painel Log no MikroTik. O script entrega mensagens claras para facilitar o diagnóstico:

Sucesso total! ➜ O DynDNS recebeu o novo IP. Acesso remoto liberado.

IP inalterado. ➜ O IP segue o mesmo. O script valida a rede, mas não gera tráfego desnecessário.

O servidor DynDNS nao respondeu ➜ O IP foi encontrado, mas o tráfego HTTP do roteador está sendo bloqueado (Verifique suas regras de Mangle, Filter ou o modem da operadora).

# Script
Copie o script abaixo. Altere **apenas** as variáveis de usuário, senha e hostname nas três primeiras linhas.

```routeros
:local username "seu-usuario"
:local password "sua-senha"
:local hostname "seu-hostname"
:global previousIP

# 1. Pega o IP Publico real via MikroTik Cloud (Funciona com IP Privado na WAN)
/ip cloud force-update
:delay 3s
:local currentIP [/ip cloud get public-address]

:if ([:len $currentIP] > 0) do={
    :if ($currentIP != $previousIP) do={
        :log info "UpdateDynDNS: Novo IP detectado: $currentIP. Enviando..."
        
        :do {
            # 2. Envia para o DynDNS com Timeout e User-Agent para evitar bloqueios
            /tool fetch url="[http://members.dyndns.org/nic/update?system=dyndns&hostname=$hostname&myip=$currentIP](http://members.dyndns.org/nic/update?system=dyndns&hostname=$hostname&myip=$currentIP)" \
                user=$username password=$password http-header-field="User-Agent: curl/7.81.0" as-value output=user
            
            :set previousIP $currentIP
            :log info "UpdateDynDNS: Sucesso total!"
        } on-error={ 
            :log error "UpdateDynDNS: O servidor DynDNS nao respondeu. Verifique rotas HTTP." 
        }
    } else={
        :log info "UpdateDynDNS: IP inalterado."
    }
} else={
    :log error "UpdateDynDNS: Nao foi possivel detectar IP Publico via Cloud."
}
```
