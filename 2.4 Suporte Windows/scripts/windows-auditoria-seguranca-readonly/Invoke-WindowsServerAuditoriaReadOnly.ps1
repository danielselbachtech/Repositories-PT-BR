[CmdletBinding()]
param(
  [string]$ReportRoot = "C:\Compliance\Audit",
  [int]$EventDays = 7,
  [switch]$IncludeEvents,
  [switch]$IncludeFeatures,
  [switch]$IncludeListeners
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

try { chcp 65001 | Out-Null } catch { }

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$utf8Bom   = New-Object System.Text.UTF8Encoding($true)

try { [Console]::InputEncoding  = $utf8NoBom } catch { }
try { [Console]::OutputEncoding = $utf8NoBom } catch { }
$OutputEncoding = $utf8NoBom

function New-DirSafe {
  param([Parameter(Mandatory)] [string]$Path)
  if (-not (Test-Path $Path)) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }
}

function Assert-Admin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $p  = New-Object Security.Principal.WindowsPrincipal($id)
  if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Run this script as Administrator."
  }
}

function Write-Log {
  param(
    [Parameter(Mandatory)] [string]$Message,
    [ValidateSet("INFO","WARN","ERROR")] [string]$Level = "INFO"
  )
  $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  $line = "[$ts][$Level] $Message"
  Write-Host $line
  try { Add-Content -Path $script:LogFile -Value $line -Encoding UTF8 } catch { }
}


function Invoke-ExeCapture {
  <#
    Runs an external executable with timeout and captures StdOut/StdErr.

    Design goals (production):
      - Avoid StdOut/StdErr pipe deadlocks: capture via temp files (cmd redirection)
      - Hard timeout with kill
      - Return Meta as [hashtable] (never PSCustomObject) to keep parameter binding stable
      - Evidence rule requested:
          * ExitCode == 0 => Status=OK
          * ExitCode != 0 but StdOut has content => Status=OK (evidence still valid)
          * ExitCode != 0 and StdOut empty => Status=Error
        (ExitCode + NonZeroExit always preserved in Meta)

    Notes:
      - Uses cmd.exe /c with explicit redirection to temp files.
      - ExitCode is from cmd.exe (typically the child exit code for normal executables).
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)] [string]$FilePath,
    [Parameter()] [string]$Arguments = "",
    [Parameter()] [int]$TimeoutSec = 45,
    [Parameter()] [switch]$AllowNonZeroExit
  )

  $stdoutPath = [System.IO.Path]::GetTempFileName()
  $stderrPath = [System.IO.Path]::GetTempFileName()
  $p = $null

  # Build a safe cmd line that redirects output to files.
  # Using /d disables AutoRun, /s handles quoting rules, /c executes and exits.
  $quotedExe = '"' + ($FilePath.Replace('"','""')) + '"'
  $cmd = "$quotedExe $Arguments 1>""$stdoutPath"" 2>""$stderrPath"""

  try {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName       = "cmd.exe"
    $psi.Arguments      = "/d /s /c ""$cmd"""
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow  = $true
    $psi.WindowStyle     = [System.Diagnostics.ProcessWindowStyle]::Hidden

    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $psi

    if (-not $p.Start()) {
      throw "Failed to start process."
    }

    $finished = $p.WaitForExit($TimeoutSec * 1000)
    if (-not $finished) {
      try { $p.Kill() } catch { }

      $meta = @{
        FilePath    = $FilePath
        Arguments   = $Arguments
        TimeoutSec  = $TimeoutSec
        ExitCode    = $null
        NonZeroExit = $null
        TimedOut    = $true
      }

      $out = ""
      $err = ""
      try { $out = Get-Content -LiteralPath $stdoutPath -Raw -ErrorAction SilentlyContinue } catch { }
      try { $err = Get-Content -LiteralPath $stderrPath -Raw -ErrorAction SilentlyContinue } catch { }

      return [pscustomobject]@{
        Status   = "Error"
        Evidence = $null
        StdOut   = $out.TrimEnd()
        StdErr   = $err.TrimEnd()
        Error    = "Timeout after ${TimeoutSec}s"
        Meta     = $meta
      }
    }

    $exit = $p.ExitCode

    $out = ""
    $err = ""
    try { $out = Get-Content -LiteralPath $stdoutPath -Raw -ErrorAction SilentlyContinue } catch { }
    try { $err = Get-Content -LiteralPath $stderrPath -Raw -ErrorAction SilentlyContinue } catch { }

    $out = ($(if ($null -ne $out) { $out } else { "" })).TrimEnd()
    $err = ($(if ($null -ne $err) { $err } else { "" })).TrimEnd()

    $hasEvidence = -not [string]::IsNullOrWhiteSpace($out)
    $ok = ($exit -eq 0) -or $AllowNonZeroExit.IsPresent -or $hasEvidence

    $meta = @{
      FilePath    = $FilePath
      Arguments   = $Arguments
      TimeoutSec  = $TimeoutSec
      ExitCode    = $exit
      NonZeroExit = ($exit -ne 0)
      TimedOut    = $false
    }

    if ($ok) {
      return [pscustomobject]@{
        Status   = "OK"
        Evidence = $out
        StdOut   = $out
        StdErr   = $err
        Meta     = $meta
      }
    }

    return [pscustomobject]@{
      Status   = "Error"
      Evidence = $out
      StdOut   = $out
      StdErr   = $err
      Error    = "ExitCode=$exit"
      Meta     = $meta
    }

  } catch {
    $meta = @{
      FilePath    = $FilePath
      Arguments   = $Arguments
      TimeoutSec  = $TimeoutSec
      ExitCode    = $null
      NonZeroExit = $null
      TimedOut    = $false
    }
    return [pscustomobject]@{
      Status   = "Error"
      Evidence = $null
      StdOut   = $null
      StdErr   = $null
      Error    = $_.Exception.Message
      Meta     = $meta
    }
  } finally {
    try { if ($p) { $p.Dispose() } } catch { }
    try { Remove-Item -LiteralPath $stdoutPath,$stderrPath -Force -ErrorAction SilentlyContinue } catch { }
  }
}

function Invoke-Section {
  param(
    [Parameter(Mandatory)] [string]$Name,
    [Parameter(Mandatory)] [scriptblock]$Block
  )
  $sw = [Diagnostics.Stopwatch]::StartNew()
  Write-Log "Starting section: $Name"
  try {
    $r = & $Block
    $sw.Stop()
    $secs = $sw.Elapsed.TotalSeconds.ToString("0.0")
    Write-Log ("Finished section: {0} ({1}s)" -f $Name, $secs)
    return $r
  } catch {
    $sw.Stop()
    $secs = $sw.Elapsed.TotalSeconds.ToString("0.0")
    Write-Log ("Section failed: {0} ({1}s) - {2}" -f $Name, $secs, $_.Exception.Message) "WARN"
    return [pscustomobject]@{ Status="Error"; Error=$_.Exception.Message }
  }
}

function HtmlEncode([object]$v) {
  if ($null -eq $v) { return "" }
  $s = [string]$v
  $s = $s -replace '&','&amp;'
  $s = $s -replace '<','&lt;'
  $s = $s -replace '>','&gt;'
  $s = $s -replace '"','&quot;'
  $s = $s -replace "'","&#39;"
  return $s
}

function Get-OsInfo {
  $os = Get-CimInstance Win32_OperatingSystem
  $cs = Get-CimInstance Win32_ComputerSystem
  [pscustomobject]@{
    ComputerName   = $env:COMPUTERNAME
    Domain         = $cs.Domain
    Manufacturer   = $cs.Manufacturer
    Model          = $cs.Model
    OS             = $os.Caption
    Version        = $os.Version
    BuildNumber    = $os.BuildNumber
    InstallDate    = $os.InstallDate
    LastBootUpTime = $os.LastBootUpTime
    TimeZone       = (Get-TimeZone).Id
    ProductType    = $os.ProductType
  }
}

function Get-PatchInfo {
  $hotfix = Get-HotFix | Sort-Object InstalledOn -Descending
  $last = $hotfix | Select-Object -First 20
  [pscustomobject]@{
    LastHotfixInstalledOn = ($hotfix | Select-Object -First 1).InstalledOn
    HotfixCount           = ($hotfix | Measure-Object).Count
    Last20Hotfixes        = ($last | Select-Object HotFixID, Description, InstalledBy, InstalledOn)
  }
}

function Get-RegistryPolicyFlat {
  param([string]$Path)
  if (-not (Test-Path $Path)) { return $null }
  $p = Get-ItemProperty $Path
  $ht = [ordered]@{}
  foreach ($prop in $p.PSObject.Properties) {
    if ($prop.Name -like "PS*") { continue }
    $v = $prop.Value
    if ($v -is [Array]) { $ht[$prop.Name] = ($v -join ",") }
    else { $ht[$prop.Name] = $v }
  }
  [pscustomobject]$ht
}

function Get-WindowsUpdateConfig {
  $wu = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
  $au = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
  [pscustomobject]@{
    WUPolicyPresent = [bool](Test-Path $wu)
    AUPolicyPresent = [bool](Test-Path $au)
    WUPolicy        = (Get-RegistryPolicyFlat -Path $wu)
    AUPolicy        = (Get-RegistryPolicyFlat -Path $au)
    WUService       = (Get-Service wuauserv -ErrorAction SilentlyContinue | Select-Object Name, Status, StartType)
    BITSService     = (Get-Service bits -ErrorAction SilentlyContinue | Select-Object Name, Status, StartType)
  }
}

function Get-DefenderStatus {
  try {
    $mp = Get-MpComputerStatus
    [pscustomobject]@{
      ProductType                = "Microsoft Defender"
      AntivirusEnabled           = [bool]$mp.AntivirusEnabled
      RealTimeProtectionEnabled  = [bool]$mp.RealTimeProtectionEnabled
      AMServiceEnabled           = [bool]$mp.AMServiceEnabled
      NISEnabled                 = [bool]$mp.NISEnabled
      BehaviorMonitorEnabled     = [bool]$mp.BehaviorMonitorEnabled
      DefenderSignaturesAgeDays  = [int]$mp.AntivirusSignatureAge
      EngineVersion              = [string]$mp.AMEngineVersion
      SignatureVersion           = [string]$mp.AntivirusSignatureVersion
      FullScanAgeDays            = [int]$mp.FullScanAge
      QuickScanAgeDays           = [int]$mp.QuickScanAge
    }
  } catch {
    [pscustomobject]@{
      ProductType = "Unknown/3rd party or not available"
      Error       = $_.Exception.Message
    }
  }
}

function Get-FirewallStatus {
  Get-NetFirewallProfile |
    Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction, LogAllowed, LogBlocked |
    ForEach-Object {
      [pscustomobject]@{
        Name = [string]$_.Name
        Enabled = [bool]$_.Enabled
        DefaultInboundAction = [string]$_.DefaultInboundAction
        DefaultOutboundAction = [string]$_.DefaultOutboundAction
        LogAllowed = [bool]$_.LogAllowed
        LogBlocked = [bool]$_.LogBlocked
      }
    }
}

function Get-SMBState {
  $smb1 = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -ErrorAction SilentlyContinue
  $shares = Get-SmbShare -ErrorAction SilentlyContinue | Select-Object Name, Path, Description
  $sharesSimple = @()
  foreach ($s in $shares) {
    $sharesSimple += [pscustomobject]@{
      Name = [string]$s.Name
      Path = [string]$s.Path
      Description = [string]$s.Description
    }
  }
  [pscustomobject]@{
    SMB1FeatureState = if ($smb1) { [string]$smb1.State } else { "Unknown" }
    SharesBasic      = $sharesSimple
  }
}

function Get-RDPConfig {
  $rdpKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
  $tsKey  = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server"
  $rdp = if (Test-Path $rdpKey) { Get-ItemProperty $rdpKey } else { $null }
  $ts  = if (Test-Path $tsKey)  { Get-ItemProperty $tsKey  } else { $null }
  [pscustomobject]@{
    RDPEnabled = if ($ts) { [bool]($ts.fDenyTSConnections -eq 0) } else { $null }
    NLAEnabled = if ($rdp) { [bool]($rdp.UserAuthentication -eq 1) } else { $null }
    SecurityLayer = if ($rdp) { [string]$rdp.SecurityLayer } else { $null }
    MinEncryptionLevel = if ($rdp) { [string]$rdp.MinEncryptionLevel } else { $null }
  }
}

function Get-TLSSchannelSnapshot {
  $base = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols"
  if (-not (Test-Path $base)) {
    return [pscustomobject]@{ Present = $false; Note = "No explicit keys; system defaults may apply." }
  }

  $out = @()
  foreach ($p in (Get-ChildItem $base -ErrorAction SilentlyContinue)) {
    $proto = $p.PSChildName
    $clientPath = Join-Path $p.PSPath "Client"
    $serverPath = Join-Path $p.PSPath "Server"
    $client = if (Test-Path $clientPath) { Get-ItemProperty $clientPath -ErrorAction SilentlyContinue } else { $null }
    $server = if (Test-Path $serverPath) { Get-ItemProperty $serverPath -ErrorAction SilentlyContinue } else { $null }

    $out += [pscustomobject]@{
      Protocol = [string]$proto
      ClientEnabled  = if ($client -and ($client.PSObject.Properties.Name -contains "Enabled")) { $client.Enabled } else { $null }
      ClientDisabledByDefault = if ($client -and ($client.PSObject.Properties.Name -contains "DisabledByDefault")) { $client.DisabledByDefault } else { $null }
      ServerEnabled  = if ($server -and ($server.PSObject.Properties.Name -contains "Enabled")) { $server.Enabled } else { $null }
      ServerDisabledByDefault = if ($server -and ($server.PSObject.Properties.Name -contains "DisabledByDefault")) { $server.DisabledByDefault } else { $null }
    }
  }

  [pscustomobject]@{ Present = $true; Protocols = $out }
}

function Get-AuditPolicyRaw {
  $r = Invoke-ExeCapture -FilePath "auditpol.exe" -Arguments "/get /category:*" -TimeoutSec 45
  if ($r.Status -ne "OK") {
    return [pscustomobject]@{
      Status = "Error"
      Note   = "auditpol failed"
      Meta   = $r.Meta
      StdErr = $r.StdErr
    }
  }
  [pscustomobject]@{
    Status   = "OK"
    Evidence = $r.Evidence
    Meta     = $r.Meta
  }
}

function Get-LocalAccountsEvidence {
  $os = Get-CimInstance Win32_OperatingSystem
  if ($os.ProductType -eq 2) {
    return [pscustomobject]@{
      Applicable = $false
      Status     = "NotApplicable"
      Note       = "Domain Controller has no local SAM users/groups like a member server."
    }
  }

  $users  = & net.exe user 2>$null
  $admins = & net.exe localgroup administrators 2>$null

  [pscustomobject]@{
    Applicable = $true
    Status     = "OK"
    NetUserEvidence = $users
    LocalAdminsEvidence = $admins
  }
}

function Get-FeaturesEvidenceDISM {
  $out = & dism.exe /online /Get-Features /Format:Table 2>$null
  if ($LASTEXITCODE -ne 0 -or -not $out) {
    return [pscustomobject]@{ Status="Error"; Note="dism get-features failed" }
  }
  [pscustomobject]@{ Status="OK"; Evidence=$out }
}

function Get-EventsEvidenceWevtutil {
  param([int]$Days)
  $ms = [int64]($Days * 24 * 60 * 60 * 1000)
  $sec = & wevtutil.exe qe Security /q:"*[System[TimeCreated[timediff(@SystemTime)<=$ms]]]" /c:50 /rd:true /f:text 2>$null
  $sys = & wevtutil.exe qe System   /q:"*[System[TimeCreated[timediff(@SystemTime)<=$ms]]]" /c:50 /rd:true /f:text 2>$null
  [pscustomobject]@{
    Status="OK"
    Days=$Days
    SecuritySampleText=$sec
    SystemSampleText=$sys
  }
}

function Get-ListenersEvidence {
  $out = & netstat.exe -ano 2>$null
  [pscustomobject]@{ Status="OK"; Evidence=$out }
}

function Export-JsonSafe {
  param(
    [Parameter(Mandatory)] $Object,
    [Parameter(Mandatory)] [string]$Path,
    [int]$Depth = 6
  )

  try {
    $json = $Object | ConvertTo-Json -Depth $Depth
    [System.IO.File]::WriteAllText($Path, $json, $utf8NoBom)
    return $true
  } catch {
    $fallback = [pscustomobject]@{
      Status = "ExportError"
      Error  = $_.Exception.Message
      Path   = $Path
    } | ConvertTo-Json -Depth 3
    [System.IO.File]::WriteAllText($Path, $fallback, $utf8NoBom)
    return $false
  }
}

function New-HTMLSummarySafe {
  param([Parameter(Mandatory)] $Audit, [Parameter(Mandatory)] [string]$Path)

  try {
    $os = $Audit.OSInfo

    $fwTable     = ($Audit.Firewall | ConvertTo-Html -Fragment)
    $hotfixTable = ($Audit.PatchInfo.Last20Hotfixes | ConvertTo-Html -Fragment)

    # DO NOT use $host (collides with automatic read-only $Host)
    $hostName = HtmlEncode $os.ComputerName
    $domain   = HtmlEncode $os.Domain
    $osName   = HtmlEncode $os.OS
    $osVer    = HtmlEncode $os.Version
    $osBuild  = HtmlEncode $os.BuildNumber
    $lastBoot = HtmlEncode $os.LastBootUpTime
    $ts       = HtmlEncode $Audit.Meta.Timestamp
    $lastPatch= HtmlEncode $Audit.PatchInfo.LastHotfixInstalledOn

    # Portuguese labels as HTML entities to avoid dependency on .ps1 encoding
    $lblTitle       = "Windows Server Audit (Read-only)"
    $lblIdent       = "Identifica&#231;&#227;o"
    $lblDomain      = "Dom&#237;nio"
    $lblLastBoot    = "&#218;ltimo boot"
    $lblGenerated   = "Gerado em"
    $lblPatches     = "Patches (&#218;ltimos 20 hotfixes)"
    $lblLastInstall = "&#218;ltima instala&#231;&#227;o"
    $lblRdpSmb      = "RDP / SMB"
    $lblRdpEnabled  = "RDP habilitado"
    $lblNlaEnabled  = "NLA habilitado"

    $html = @"
<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$lblTitle - $hostName</title>
<style>
:root{
  --bg:#0b1220;
  --panel:#0f1a2e;
  --muted:#9fb0c4;
  --text:#e9eef6;
  --border:rgba(255,255,255,.08);
  --shadow: 0 10px 30px rgba(0,0,0,.35);
  --ok:#2dd4bf;
  --warn:#fbbf24;
  --bad:#fb7185;
  --chip:#142443;
}
@media (prefers-color-scheme: light){
  :root{
    --bg:#f6f8fb;
    --panel:#ffffff;
    --muted:#52677d;
    --text:#0f172a;
    --border:rgba(15,23,42,.10);
    --shadow: 0 10px 30px rgba(2,6,23,.08);
    --chip:#eef2ff;
  }
}
*{box-sizing:border-box}
body{
  margin:0;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Arial, sans-serif;
  background:var(--bg);
  color:var(--text);
}
a{color:inherit}
.header{
  position:sticky; top:0; z-index:10;
  backdrop-filter: blur(10px);
  background: color-mix(in srgb, var(--bg) 85%, transparent);
  border-bottom:1px solid var(--border);
}
.header-inner{
  max-width:1100px; margin:0 auto; padding:14px 18px;
  display:flex; gap:14px; align-items:center; justify-content:space-between;
}
.title{
  display:flex; flex-direction:column; gap:3px;
}
.title h1{margin:0; font-size:18px; letter-spacing:.2px}
.title .sub{color:var(--muted); font-size:12px}
.chips{display:flex; gap:8px; flex-wrap:wrap; justify-content:flex-end}
.chip{
  background:var(--chip);
  border:1px solid var(--border);
  padding:6px 10px;
  border-radius:999px;
  font-size:12px;
  color:var(--muted);
}
.container{max-width:1100px; margin:0 auto; padding:18px}
.grid{
  display:grid;
  grid-template-columns: 1.2fr .8fr;
  gap:14px;
}
@media (max-width: 980px){
  .grid{grid-template-columns:1fr}
}
.card{
  background:var(--panel);
  border:1px solid var(--border);
  border-radius:16px;
  box-shadow:var(--shadow);
  padding:14px 14px 10px 14px;
}
.card h2{
  margin:0 0 10px 0;
  font-size:14px;
  letter-spacing:.2px;
  color:color-mix(in srgb, var(--text) 92%, var(--muted));
}
.kv{display:grid; grid-template-columns: 170px 1fr; gap:8px 12px; font-size:13px}
.kv .k{color:var(--muted)}
.badge{
  display:inline-flex; align-items:center; gap:6px;
  padding:4px 10px; border-radius:999px; font-size:12px;
  border:1px solid var(--border);
  background: color-mix(in srgb, var(--panel) 85%, transparent);
}
.badge.ok{color:var(--ok)}
.badge.warn{color:var(--warn)}
.badge.bad{color:var(--bad)}
.table-wrap{overflow:auto; border-radius:12px; border:1px solid var(--border)}
table{border-collapse:collapse; width:100%; min-width:720px; font-size:12px}
th,td{padding:10px 10px; border-bottom:1px solid var(--border); vertical-align:top}
th{
  text-align:left;
  position:sticky; top:0;
  background: color-mix(in srgb, var(--panel) 92%, transparent);
  color:color-mix(in srgb, var(--text) 90%, var(--muted));
}
tr:hover td{background: color-mix(in srgb, var(--panel) 92%, transparent)}
.footer{
  margin-top:14px;
  color:var(--muted);
  font-size:12px;
}
.small{font-size:12px; color:var(--muted)}
.section{margin-top:14px}
</style>
</head>
<body>
<div class="header">
  <div class="header-inner">
    <div class="title">
      <h1>$lblTitle</h1>
      <div class="sub">$hostName&nbsp;&bull;&nbsp;$domain&nbsp;&bull;&nbsp;$osName ($osVer build $osBuild)</div>
    </div>
    <div class="chips">
      <div class="chip">${lblGenerated}: $ts</div>
      <div class="chip">${lblLastBoot}: $lastBoot</div>
      <div class="chip">${lblLastInstall}: $lastPatch</div>
    </div>
  </div>
</div>

<div class="container">

  <div class="grid">
    <div class="card">
      <h2>$lblIdent</h2>
      <div class="kv">
        <div class="k">Host</div><div>$hostName</div>
        <div class="k">${lblDomain}</div><div>$domain</div>
        <div class="k">OS</div><div>$osName ($osVer build $osBuild)</div>
        <div class="k">${lblLastBoot}</div><div>$lastBoot</div>
      </div>
      <div class="footer">RunId: $(HtmlEncode $Audit.Meta.RunId)</div>
    </div>

    <div class="card">
      <h2>$lblRdpSmb</h2>
      <div class="kv">
        <div class="k">${lblRdpEnabled}</div><div>$(if ($Audit.RDP.RDPEnabled -eq $true) { '<span class="badge ok">Enabled</span>' } else { '<span class="badge bad">Disabled</span>' })</div>
        <div class="k">${lblNlaEnabled}</div><div>$(if ($Audit.RDP.NLAEnabled -eq $true) { '<span class="badge ok">Enabled</span>' } else { '<span class="badge warn">Off</span>' })</div>
        <div class="k">SMB1 Feature</div><div>$(HtmlEncode $Audit.SMB.SMB1FeatureState)</div>
      </div>
      <div class="footer small">SAFE MODE: read-only audit</div>
    </div>
  </div>

  <div class="section card">
    <h2>Firewall</h2>
    <div class="table-wrap">
      $fwTable
    </div>
  </div>

  <div class="section card">
    <h2>$lblPatches</h2>
    <div class="small"><b>${lblLastInstall}:</b> $lastPatch</div>
    <div class="table-wrap" style="margin-top:10px">
      $hotfixTable
    </div>
  </div>

</div>
</body>
</html>
"@

    [System.IO.File]::WriteAllText($Path, $html, $utf8Bom)
    return $true
  } catch {
    $fail = "HTML generation failed: $($_.Exception.Message)"
    [System.IO.File]::WriteAllText($Path, $fail, $utf8Bom)
    return $false
  }
}

Assert-Admin
New-DirSafe $ReportRoot

$runId  = (Get-Date).ToString("yyyyMMdd-HHmmss")
$runDir = Join-Path $ReportRoot $runId
New-DirSafe $runDir

$script:LogFile = Join-Path $runDir "run.log"

try {
  Start-Transcript -Path (Join-Path $runDir "transcript.txt") -Force | Out-Null
} catch {
  Write-Log "Transcript unavailable: $($_.Exception.Message)" "WARN"
}

Write-Log "RunId: $runId"
Write-Log "SAFE MODE: read-only audit. Heavy sections only with switches."

$audit = [ordered]@{
  Meta = [pscustomobject]@{
    RunId     = $runId
    Timestamp = (Get-Date).ToString("s")
    EventDays = $EventDays
    IncludeEvents    = [bool]$IncludeEvents
    IncludeFeatures  = [bool]$IncludeFeatures
    IncludeListeners = [bool]$IncludeListeners
  }
  OSInfo        = Invoke-Section -Name "OSInfo" { Get-OsInfo }
  PatchInfo     = Invoke-Section -Name "PatchInfo" { Get-PatchInfo }
  WindowsUpdate = Invoke-Section -Name "WindowsUpdateConfig" { Get-WindowsUpdateConfig }
  Defender      = Invoke-Section -Name "DefenderStatus" { Get-DefenderStatus }
  Firewall      = Invoke-Section -Name "FirewallStatus" { Get-FirewallStatus }
  SMB           = Invoke-Section -Name "SMBState" { Get-SMBState }
  RDP           = Invoke-Section -Name "RDPConfig" { Get-RDPConfig }
  TLS_Schannel  = Invoke-Section -Name "TLS_Schannel" { Get-TLSSchannelSnapshot }
  AuditPolicy   = Invoke-Section -Name "AuditPolicyRaw" { Get-AuditPolicyRaw }
  LocalAccounts = Invoke-Section -Name "LocalAccountsEvidence" { Get-LocalAccountsEvidence }
  Features      = if ($IncludeFeatures)  { Invoke-Section -Name "Features_DISM" { Get-FeaturesEvidenceDISM } } else { [pscustomobject]@{ Status="Skipped" } }
  Events        = if ($IncludeEvents)    { Invoke-Section -Name "Events_wevtutil" { Get-EventsEvidenceWevtutil -Days $EventDays } } else { [pscustomobject]@{ Status="Skipped" } }
  Listeners     = if ($IncludeListeners) { Invoke-Section -Name "Listeners_netstat" { Get-ListenersEvidence } } else { [pscustomobject]@{ Status="Skipped" } }
}

Write-Log "Starting JSON export (per section)"
$ok = $true
$ok = (Export-JsonSafe -Object $audit.Meta -Path (Join-Path $runDir "meta.json") -Depth 4) -and $ok
$ok = (Export-JsonSafe -Object $audit.OSInfo -Path (Join-Path $runDir "os.json") -Depth 4) -and $ok
$ok = (Export-JsonSafe -Object $audit.PatchInfo -Path (Join-Path $runDir "patch.json") -Depth 5) -and $ok
$ok = (Export-JsonSafe -Object $audit.WindowsUpdate -Path (Join-Path $runDir "windows_update.json") -Depth 5) -and $ok
$ok = (Export-JsonSafe -Object $audit.Defender -Path (Join-Path $runDir "defender.json") -Depth 4) -and $ok
$ok = (Export-JsonSafe -Object $audit.Firewall -Path (Join-Path $runDir "firewall.json") -Depth 4) -and $ok
$ok = (Export-JsonSafe -Object $audit.SMB -Path (Join-Path $runDir "smb.json") -Depth 5) -and $ok
$ok = (Export-JsonSafe -Object $audit.RDP -Path (Join-Path $runDir "rdp.json") -Depth 4) -and $ok
$ok = (Export-JsonSafe -Object $audit.TLS_Schannel -Path (Join-Path $runDir "tls_schannel.json") -Depth 6) -and $ok
$ok = (Export-JsonSafe -Object $audit.AuditPolicy -Path (Join-Path $runDir "audit_policy.json") -Depth 4) -and $ok
$ok = (Export-JsonSafe -Object $audit.LocalAccounts -Path (Join-Path $runDir "local_accounts.json") -Depth 4) -and $ok
$ok = (Export-JsonSafe -Object $audit.Features -Path (Join-Path $runDir "features.json") -Depth 4) -and $ok
$ok = (Export-JsonSafe -Object $audit.Events -Path (Join-Path $runDir "events.json") -Depth 4) -and $ok
$ok = (Export-JsonSafe -Object $audit.Listeners -Path (Join-Path $runDir "listeners.json") -Depth 4) -and $ok

Write-Log "Exporting audit_full.json (limited depth)"
Export-JsonSafe -Object $audit -Path (Join-Path $runDir "audit_full.json") -Depth 6 | Out-Null

Write-Log "Generating summary.html"
New-HTMLSummarySafe -Audit $audit -Path (Join-Path $runDir "summary.html") | Out-Null

if (-not $ok) {
  Write-Log "Export finished with warnings (some JSON used fallback)." "WARN"
} else {
  Write-Log "Export finished successfully."
}

Write-Log "Done. Report path: $runDir"

try { Stop-Transcript | Out-Null } catch { }
