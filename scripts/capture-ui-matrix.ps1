param(
  [string]$GodotExe = ''
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

if ([string]::IsNullOrWhiteSpace($GodotExe)) {
  $candidates = @(
    'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe',
    (Get-Command godot4 -ErrorAction SilentlyContinue).Source,
    (Get-Command godot -ErrorAction SilentlyContinue).Source
  ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -Unique
  $GodotExe = $candidates | Select-Object -First 1
}
if ([string]::IsNullOrWhiteSpace($GodotExe) -or !(Test-Path -LiteralPath $GodotExe)) {
  throw 'A non-headless Godot executable is required for visual screenshots.'
}

$outputDirectory = Join-Path $root 'docs\visual-matrix'
$appData = Join-Path $root '.godot_visual_appdata'
$localAppData = Join-Path $root '.godot_visual_localappdata'
$stdoutPath = Join-Path $root '.godot-visual-matrix.out.log'
$stderrPath = Join-Path $root '.godot-visual-matrix.err.log'
New-Item -ItemType Directory -Force -Path $outputDirectory, $appData, $localAppData | Out-Null

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $GodotExe
$psi.Arguments = '--path "{0}" --script res://scripts/capture_visual_matrix.gd' -f $root
$psi.WorkingDirectory = $root
$psi.UseShellExecute = $false
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.CreateNoWindow = $true
$psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
$psi.EnvironmentVariables['APPDATA'] = $appData
$psi.EnvironmentVariables['LOCALAPPDATA'] = $localAppData

try {
  $process = [System.Diagnostics.Process]::Start($psi)
  $stdoutTask = $process.StandardOutput.ReadToEndAsync()
  $stderrTask = $process.StandardError.ReadToEndAsync()
  if (!$process.WaitForExit(180000)) {
    $process.Kill()
    throw 'Godot visual matrix capture timed out after 180 seconds.'
  }
  $stdout = $stdoutTask.GetAwaiter().GetResult()
  $stderr = $stderrTask.GetAwaiter().GetResult()
  $utf8 = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($stdoutPath, [string]$stdout, $utf8)
  [System.IO.File]::WriteAllText($stderrPath, [string]$stderr, $utf8)
  if ($process.ExitCode -ne 0) {
    Write-Host $stdout
    Write-Host $stderr
    throw "Godot visual matrix capture failed with exit code $($process.ExitCode)."
  }
  if (($stdout + $stderr) -notmatch 'UI_VISUAL_MATRIX_CAPTURE_OK:') {
    Write-Host $stdout
    Write-Host $stderr
    throw 'Godot visual matrix capture did not print its success marker.'
  }

  $requiredImages = @(
    'world_hud-1280x720.png',
    'world_hud-1600x720.png',
    'world_hud-1920x1080.png',
    'world_hud-1366x768.png',
    'world_hud-844x390.png',
    'main_menu-1280x720.png',
    'main_menu-1600x720.png',
    'main_menu-1920x1080.png',
    'main_menu-1366x768.png',
    'main_menu-844x390.png',
    'dex-1280x720.png',
    'dex-844x390.png',
    'home-1280x720.png',
    'home-844x390.png',
    'dialogue-1280x720.png',
    'dialogue-844x390.png'
  )
  foreach ($fileName in $requiredImages) {
    $imagePath = Join-Path $outputDirectory $fileName
    if (!(Test-Path -LiteralPath $imagePath) -or (Get-Item -LiteralPath $imagePath).Length -le 0) {
      throw "Missing visual matrix screenshot: $fileName"
    }
  }
  Write-Host "Visual matrix screenshots captured in $outputDirectory"
}
finally {
  foreach ($pathToClean in @($appData, $localAppData, $stdoutPath, $stderrPath)) {
    if (!(Test-Path -LiteralPath $pathToClean)) {
      continue
    }
    try {
      $item = Get-Item -LiteralPath $pathToClean
      if ($item.PSIsContainer) {
        [System.IO.Directory]::Delete($pathToClean, $true)
      } else {
        [System.IO.File]::Delete($pathToClean)
      }
    } catch {
      Write-Warning "Could not clean temporary visual capture path: $pathToClean"
    }
  }
}