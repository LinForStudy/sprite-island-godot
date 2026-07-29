$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$godotCandidates = @(
  'C:\Program Files\Godot\Godot_v4.7-stable_win64_console.exe',
  (Get-Command godot4 -ErrorAction SilentlyContinue).Source,
  (Get-Command godot -ErrorAction SilentlyContinue).Source,
  'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe'
) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique
$godotExe = $godotCandidates | Select-Object -First 1
if (-not $godotExe) {
  throw 'Godot 4 executable was not found; cannot run the regression suite.'
}

$appData = Join-Path $root '.godot_regression_appdata'
$localAppData = Join-Path $root '.godot_regression_localappdata'
New-Item -ItemType Directory -Force -Path $appData, $localAppData | Out-Null
$previousAppData = $env:APPDATA
$previousLocalAppData = $env:LOCALAPPDATA
$env:APPDATA = $appData
$env:LOCALAPPDATA = $localAppData

function Invoke-RegressionStep {
  param(
    [string]$Name,
    [string[]]$Arguments,
    [string]$SuccessMarker
  )
  Write-Host "[regression] $Name"
  $previousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  $output = & $godotExe @Arguments 2>&1
  $exitCode = $LASTEXITCODE
  $ErrorActionPreference = $previousErrorActionPreference
  $text = $output -join [Environment]::NewLine
  if ($text) { Write-Host $text }
  if ($exitCode -ne 0) {
    throw "$Name failed with exit code $exitCode."
  }
  if ($text -notmatch [regex]::Escape($SuccessMarker)) {
    throw "$Name did not emit success marker: $SuccessMarker"
  }
}

try {
  Invoke-RegressionStep -Name 'world scene smoke' -Arguments @('--headless', '--path', $root, '--script', 'res://scripts/headless_scene_smoke.gd') -SuccessMarker 'HEADLESS_SCENE_SMOKE_OK'
  Invoke-RegressionStep -Name 'dialogue input smoke' -Arguments @('--headless', '--path', $root, '--script', 'res://scripts/verify_dialogue_input.gd') -SuccessMarker 'DIALOGUE_INPUT_SMOKE_OK'
  Invoke-RegressionStep -Name 'save v2 smoke' -Arguments @('--headless', '--path', $root, '--script', 'res://scripts/verify_save_v2.gd') -SuccessMarker 'save v2 runtime check passed.'
  Invoke-RegressionStep -Name 'gameplay balance smoke' -Arguments @('--headless', '--path', $root, '--script', 'res://scripts/verify_gameplay_balance.gd') -SuccessMarker 'GAMEPLAY_BALANCE_SMOKE_OK'
  Invoke-RegressionStep -Name 'UI matrix smoke' -Arguments @('--headless', '--path', $root, '--script', 'res://scripts/verify_ui_matrix.gd') -SuccessMarker 'UI_MATRIX_STRUCTURAL_SMOKE_OK'
  Invoke-RegressionStep -Name 'settings and audio smoke' -Arguments @('--headless', '--path', $root, 'res://scenes/testing/settings_audio_smoke.tscn') -SuccessMarker 'SETTINGS_AUDIO_SMOKE_OK'
  Invoke-RegressionStep -Name 'battle contract smoke' -Arguments @('--headless', '--path', $root, 'res://scenes/battle/battle_contract_smoke.tscn') -SuccessMarker 'BATTLE_CONTRACT_SMOKE_OK'
  Write-Host 'REGRESSION_SUITE_OK'
}
finally {
  $env:APPDATA = $previousAppData
  $env:LOCALAPPDATA = $previousLocalAppData
}
