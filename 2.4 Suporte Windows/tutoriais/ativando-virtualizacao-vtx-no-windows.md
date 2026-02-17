# 🛠️ Ativando Virtualização VT-x no Windows (Intel VT-x Desativado)

> Sistema Operacional Base: **Microsoft Windows**
> 
>  **Autor:** **Alberto Gemelli**


Se o **LeoMoon CPU-V** exibe a mensagem:

> **"Hardware Virtualization is supported, but is DISABLED"**

isso significa que o processador suporta VT-x, mas a virtualização por hardware está desabilitada no sistema. Siga este guia completo para resolver o problema.

---

## ✅ Passo 1: Verificar Recursos do Windows

Acesse:

> Painel de Controle → Programas e Recursos → **Ativar ou desativar recursos do Windows**

**Desative (desmarque) os seguintes itens:**
- `Hyper-V`
- `Plataforma do Hypervisor do Windows`
- `Virtual Machine Platform`

Esses recursos entram em conflito com hipervisores como VMware, VirtualBox e algumas versões do WSL.

---

## ✅ Passo 2: Desativar o Hypervisor via Linha de Comando

### Prompt de Comando (Executar como Administrador):

```cmd
bcdedit /set hypervisorlaunchtype off
```

### PowerShell (Executar como Administrador):

```powershell
Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Hypervisor
```

Esses comandos desativam o carregamento automático do Hyper-V, que consome a virtualização de hardware.

---

## ✅ Passo 3: Editar o Registro do Windows

⚠️ **Atenção**: Faça backup do Registro antes de modificar qualquer chave.

### Edite os seguintes caminhos usando `regedit`:

```reg
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\DeviceGuard]
"EnableVirtualizationBasedSecurity"=dword:00000000
"HyperVVirtualizationBasedSecurityOptOut"=dword:00000000
"WasEnabledBy"=dword:00000000
```

```reg
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity]
"Enabled"=dword:00000000
"EnabledBootId"=dword:00000000
```

Essas alterações desabilitam políticas de segurança baseadas em virtualização (VBS), que também podem interferir com o uso da VT-x.

---

## ✅ Passo 4: Ativar VT-x na BIOS/UEFI

1. Reinicie o computador e entre na BIOS/UEFI (geralmente pressionando `DEL`, `F2`, `F10`, `ESC` no boot).
2. Navegue até a aba **Advanced** ou **CPU Configuration**.
3. Habilite a opção:
   - **Intel Virtualization Technology** (pode aparecer como "VT-x" ou "Intel VT").
4. Salve e saia (**Save & Exit**).

---

## 🔁 Passo Final

Após concluir todos os passos:

1. **Reinicie o computador**
2. Abra novamente o **LeoMoon CPU-V**
3. Verifique se o campo **VT-x Enabled** está agora com o ✅ verde

---

## 📌 Considerações

- Se você utiliza o **WSL2**, o recurso “Virtual Machine Platform” pode ser necessário. Avalie o uso conforme o ambiente.
- Políticas de segurança de empresas (GPO) podem reabilitar o Hyper-V automaticamente. Consulte o administrador do domínio se aplicável.
