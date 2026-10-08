# Windows side of ./nomad (through nomad.cmd), the counterpart of network/*.sh: private network
# on the Ethernet cable between this PC (running the model) and the mini PC (running NOMAD).
# Asks for Administrator rights by itself.
#
#   ./nomad start            installs and starts Ollama, downloads the models once, address 10.77.0.1
#                            with DHCP and internet for the mini PC, bridge to Ollama
#   ./nomad stop             undo the network and the bridge
#   ./nomad status           network, mini PC address, bridge
#   ./nomad test [address]   check a running NOMAD (needs bash: Git for Windows or WSL)
#   ./nomad report [address] benchmarks into content/notes (needs bash too)
#   single steps: up, down, bridge-start, bridge-stop
#
# Uses Internet Connection Sharing (needs a working internet adapter, e.g. Wi-Fi).
# The bridge forwards the whole Ollama API (no endpoint filtering, unlike llm-bridge.sh).
[CmdletBinding(PositionalBinding = $false)]
param(
  [Parameter(Position = 0)]
  [ValidateSet('start', 'stop', 'status', 'test', 'report', 'up', 'down', 'bridge-start', 'bridge-stop')]
  [string]$Action = 'start',
  [Parameter(Position = 1)]
  [string]$Address = 'nomad.local',
  [string]$Adapter = $env:NOMAD_LINK_IF
)
$ErrorActionPreference = 'Stop'

$LinkIp = '10.77.0.1'
$Port = 11434
$IcsParams = 'HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters'
# Without this Windows may drop Internet Connection Sharing after a restart
$IcsPersist = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\SharedAccess'
$FirewallRule = 'NOMAD LLM bridge'
# The model NOMAD indexes the knowledge base with; it must be the same everywhere
$EmbedModel = 'nomic-embed-text:v1.5'

# Settings for this computer (network/local.env, KEY=value lines), e.g. CHAT_MODEL
$LocalEnv = @{}
$LocalEnvFile = Join-Path $PSScriptRoot 'local.env'
if (Test-Path $LocalEnvFile) {
  foreach ($line in Get-Content $LocalEnvFile) {
    if ($line -match '^\s*([A-Z_]+)=(.*)$') { $LocalEnv[$Matches[1]] = $Matches[2].Trim('"') }
  }
}
$ChatModel = if ($LocalEnv.CHAT_MODEL) { $LocalEnv.CHAT_MODEL } else { 'qwen3:8b' }

function Say($Text) { Write-Host "[link] $Text" -ForegroundColor Green }
function Die($Text) { Write-Host "[link] $Text" -ForegroundColor Red; exit 1 }

function Assert-Admin {
  $id = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
  if ($id.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { return }
  # Run again as Administrator in a window that stays open to show the result
  $relaunch = @('-NoProfile', '-NoExit', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"", $Action)
  if ($Adapter) { $relaunch += @('-Adapter', "`"$Adapter`"") }
  Start-Process powershell -Verb RunAs -ArgumentList $relaunch
  exit
}

# Adapter used for the internet
function Get-WanAdapter {
  $route = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue | Sort-Object RouteMetric | Select-Object -First 1
  if ($route) { Get-NetAdapter -InterfaceIndex $route.InterfaceIndex }
}

# Wired adapter with a cable in it that is not used for the internet
function Get-LinkAdapter {
  if ($Adapter) { return Get-NetAdapter -Name $Adapter }
  $wan = Get-WanAdapter
  $link = Get-NetAdapter -Physical | Where-Object {
    $_.Status -eq 'Up' -and $_.NdisPhysicalMedium -eq 14 -and (-not $wan -or $_.ifIndex -ne $wan.ifIndex)
  } | Select-Object -First 1
  if (-not $link) { Die 'No wired adapter with a cable found. Plug in the cable or set NOMAD_LINK_IF="Ethernet 2"' }
  $link
}

function Get-Sharing {
  $share = New-Object -ComObject HNetCfg.HNetShare
  foreach ($c in $share.EnumEveryConnection) {
    [pscustomobject]@{
      Name   = $share.NetConnectionProps.Invoke($c).Name
      Config = $share.INetSharingConfigurationForINetConnection.Invoke($c)
    }
  }
}

function Disable-Sharing {
  foreach ($s in Get-Sharing) { if ($s.Config.SharingEnabled) { $s.Config.DisableSharing() } }
}

function Up {
  Assert-Admin
  $link = Get-LinkAdapter
  $wan = Get-WanAdapter
  if (-not $wan) { Die 'No internet adapter. Connect to Wi-Fi first (Windows shares an existing connection)' }
  Say "Cable adapter $($link.Name): $LinkIp, internet through $($wan.Name)"
  Set-ItemProperty $IcsParams -Name ScopeAddress -Value $LinkIp
  Set-ItemProperty $IcsParams -Name ScopeAddressBackup -Value $LinkIp
  New-ItemProperty $IcsPersist -Name EnableRebootPersistConnection -Value 1 -PropertyType DWord -Force | Out-Null
  Disable-Sharing
  Restart-Service SharedAccess
  foreach ($s in Get-Sharing) {
    if ($s.Name -eq $wan.Name) { $s.Config.EnableSharing(0) }
    if ($s.Name -eq $link.Name) { $s.Config.EnableSharing(1) }
  }
  Say 'Done. The mini PC gets an address 10.77.0.x (check: ./nomad status)'
}

function Down {
  Assert-Admin
  Disable-Sharing
  Remove-ItemProperty $IcsParams -Name ScopeAddress, ScopeAddressBackup -ErrorAction SilentlyContinue
  Remove-ItemProperty $IcsPersist -Name EnableRebootPersistConnection -ErrorAction SilentlyContinue
  $link = Get-LinkAdapter
  Remove-NetIPAddress -InterfaceIndex $link.ifIndex -IPAddress $LinkIp -Confirm:$false -ErrorAction SilentlyContinue
  Set-NetIPInterface -InterfaceIndex $link.ifIndex -Dhcp Enabled
  Say 'Removed: fixed address, DHCP and internet sharing'
}

function Start-Bridge {
  Assert-Admin
  if (-not (Get-NetIPAddress -IPAddress $LinkIp -ErrorAction SilentlyContinue)) { Die "No $LinkIp here. First: ./nomad start" }
  if (-not (Test-Ollama)) { Die "Ollama does not answer at 127.0.0.1:$Port. Start Ollama first" }
  Set-Service iphlpsvc -StartupType Automatic
  Start-Service iphlpsvc
  netsh interface portproxy delete v4tov4 listenaddress=$LinkIp listenport=$Port 2>$null | Out-Null
  netsh interface portproxy add v4tov4 listenaddress=$LinkIp listenport=$Port connectaddress=127.0.0.1 connectport=$Port | Out-Null
  Remove-NetFirewallRule -DisplayName $FirewallRule -ErrorAction SilentlyContinue
  New-NetFirewallRule -DisplayName $FirewallRule -Direction Inbound -Protocol TCP -LocalAddress $LinkIp -LocalPort $Port `
    -RemoteAddress 10.77.0.0/24 -Action Allow | Out-Null
  Say "Model available to the mini PC: http://${LinkIp}:$Port"
}

function Stop-Bridge {
  Assert-Admin
  netsh interface portproxy delete v4tov4 listenaddress=$LinkIp listenport=$Port 2>$null | Out-Null
  Remove-NetFirewallRule -DisplayName $FirewallRule -ErrorAction SilentlyContinue
  Say 'Bridge stopped'
}

function Test-Ollama {
  try { Invoke-RestMethod "http://127.0.0.1:$Port/api/version" -TimeoutSec 3 | Out-Null; $true } catch { $false }
}

# Installs (winget) and starts the Ollama app when it is not running
function Start-Ollama {
  if (Test-Ollama) { return }
  $app = Join-Path $env:LOCALAPPDATA 'Programs\Ollama\ollama app.exe'
  if (-not (Test-Path $app) -and -not (Get-Command ollama -ErrorAction SilentlyContinue)) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { Die 'Install Ollama from https://ollama.com and run this again' }
    Say 'Installing Ollama'
    winget install --id Ollama.Ollama --exact --silent --accept-source-agreements --accept-package-agreements | Out-Null
  }
  Say 'Starting Ollama'
  if (Test-Path $app) { Start-Process $app } else { Start-Process ollama -ArgumentList serve -WindowStyle Hidden }
  foreach ($i in 1..60) { if (Test-Ollama) { return }; Start-Sleep 1 }
  Die "Ollama did not start at 127.0.0.1:$Port"
}

# Downloaded by this computer's Ollama, once; NOMAD itself never downloads models
function Get-Models {
  $have = (Invoke-RestMethod "http://127.0.0.1:$Port/api/tags").models.name
  foreach ($model in $ChatModel, $EmbedModel) {
    if ($have -contains $model -or $have -contains "${model}:latest") { continue }
    Say "Downloading the model $model (once, a few GB)"
    Invoke-RestMethod "http://127.0.0.1:$Port/api/pull" -Method Post -TimeoutSec 7200 `
      -Body (@{ model = $model; stream = $false } | ConvertTo-Json) | Out-Null
  }
}

function Start-All {
  Start-Ollama
  Get-Models
  Up
  Start-Bridge
  Status
  Say "Chat model: $ChatModel. NOMAD: http://nomad.local:8080"
}

function Stop-All {
  Stop-Bridge
  Down
}

# The same test scripts as on macOS and Linux, through bash from Git for Windows or WSL
function Invoke-Test($Script) {
  if (-not (Get-Command bash -ErrorAction SilentlyContinue)) {
    Die "This needs bash: install Git for Windows (git-scm.com) or WSL, or run $Script on the mini PC"
  }
  Push-Location (Split-Path $PSScriptRoot)
  try { bash $Script $Address } finally { Pop-Location }
  exit $LASTEXITCODE
}

function Status {
  $link = Get-LinkAdapter
  $ip = (Get-NetIPAddress -InterfaceIndex $link.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress -join ', '
  $shared = Get-Sharing | Where-Object { $_.Config.SharingEnabled } | ForEach-Object { $_.Name }
  "Cable adapter:  $($link.Name)"
  "Address:        $ip"
  "Internet share: $(if ($shared) { $shared -join ' -> ' } else { 'off' })"
  "LLM bridge:     $(if (netsh interface portproxy show v4tov4 | Select-String $LinkIp) { "http://${LinkIp}:$Port" } else { 'off' })"
  'Mini PC:'
  $peers = Get-NetNeighbor -InterfaceIndex $link.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object { $_.IPAddress -like '10.77.0.*' -and $_.IPAddress -ne $LinkIp -and $_.State -ne 'Unreachable' }
  if ($peers) { $peers | ForEach-Object { "  $($_.IPAddress)  ($($_.LinkLayerAddress))" } }
  else { '  not seen yet (is the mini PC on and set to DHCP?)' }
}

switch ($Action) {
  'start' { Start-All }
  'stop' { Stop-All }
  'test' { Invoke-Test tests/smoke.sh }
  'report' { Invoke-Test tests/benchmark.sh }
  'up' { Up }
  'down' { Down }
  'status' { Status }
  'bridge-start' { Start-Bridge }
  'bridge-stop' { Stop-Bridge }
}
