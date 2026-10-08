# Windows version of link.sh + llm-bridge.sh: private network on the Ethernet cable between
# this PC (running the model) and the mini PC (running NOMAD). Start it through link.cmd,
# it asks for Administrator rights by itself:
#
#   network\start.cmd               # everything at once (after a restart too): Ollama, network, bridge
#   network\link.cmd up             # address 10.77.0.1, DHCP and internet for the mini PC
#   network\link.cmd bridge-start   # Ollama (127.0.0.1:11434) reachable on the cable only
#   network\link.cmd status
#   network\link.cmd bridge-stop
#   network\link.cmd down
#
# Uses Internet Connection Sharing (needs a working internet adapter, e.g. Wi-Fi).
# The bridge forwards the whole Ollama API (no endpoint filtering, unlike llm-bridge.sh).
param(
  [ValidateSet('start', 'up', 'down', 'status', 'bridge-start', 'bridge-stop')]
  [string]$Action = 'status',
  [string]$Adapter = $env:NOMAD_LINK_IF
)
$ErrorActionPreference = 'Stop'

$LinkIp = '10.77.0.1'
$Port = 11434
$IcsParams = 'HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters'
$FirewallRule = 'NOMAD LLM bridge'

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
  Disable-Sharing
  Restart-Service SharedAccess
  foreach ($s in Get-Sharing) {
    if ($s.Name -eq $wan.Name) { $s.Config.EnableSharing(0) }
    if ($s.Name -eq $link.Name) { $s.Config.EnableSharing(1) }
  }
  Say 'Done. The mini PC gets an address 10.77.0.x (check: link.cmd status)'
  Say "Next: link.cmd bridge-start, then on the mini PC NOMAD_LLM_URL=http://${LinkIp}:$Port"
}

function Down {
  Assert-Admin
  Disable-Sharing
  Remove-ItemProperty $IcsParams -Name ScopeAddress, ScopeAddressBackup -ErrorAction SilentlyContinue
  $link = Get-LinkAdapter
  Remove-NetIPAddress -InterfaceIndex $link.ifIndex -IPAddress $LinkIp -Confirm:$false -ErrorAction SilentlyContinue
  Set-NetIPInterface -InterfaceIndex $link.ifIndex -Dhcp Enabled
  Say 'Removed: fixed address, DHCP and internet sharing'
}

function Start-Bridge {
  Assert-Admin
  if (-not (Get-NetIPAddress -IPAddress $LinkIp -ErrorAction SilentlyContinue)) { Die "No $LinkIp here. First: link.cmd up" }
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

# Starts the Ollama app (installed from ollama.com) when it is not running
function Start-Ollama {
  if (Test-Ollama) { return }
  $app = Join-Path $env:LOCALAPPDATA 'Programs\Ollama\ollama app.exe'
  if (Test-Path $app) {
    Say 'Starting Ollama'
    Start-Process $app
  } elseif (Get-Command ollama -ErrorAction SilentlyContinue) {
    Say 'Starting ollama serve'
    Start-Process ollama -ArgumentList serve -WindowStyle Hidden
  } else {
    Die 'Ollama is not installed. Install it from https://ollama.com and run this again'
  }
  foreach ($i in 1..30) { if (Test-Ollama) { return }; Start-Sleep 1 }
  Die "Ollama did not start at 127.0.0.1:$Port"
}

function Start-All {
  Start-Ollama
  Up
  Start-Bridge
  Status
  Say 'NOMAD: http://nomad.local:8080'
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
  'up' { Up }
  'down' { Down }
  'status' { Status }
  'bridge-start' { Start-Bridge }
  'bridge-stop' { Stop-Bridge }
}
