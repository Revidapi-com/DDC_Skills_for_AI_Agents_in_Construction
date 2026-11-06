# Install the DDC construction skills into Claude Code, Codex and Hermes Agent (Windows).
#   powershell -ExecutionPolicy Bypass -File revidapi\install.ps1
#   powershell -ExecutionPolicy Bypass -File revidapi\install.ps1 claude codex
# Only folders with SKILL.md are copied (never the repo's .claude folder);
# a skill you already have that this script did not install is never overwritten.
$ErrorActionPreference = 'Stop'
$Goc = Split-Path -Parent $PSScriptRoot
$Dau = '# installed by DDC x RevidAPI'
$Apps = if ($args.Count) { $args } else { @('claude', 'codex', 'hermes') }
$CodexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME '.codex' }
$Dich = @{
  claude = @{ Dir = (Join-Path $HOME '.claude\skills'); Home = (Join-Path $HOME '.claude') }
  codex  = @{ Dir = (Join-Path $CodexHome 'skills');    Home = $CodexHome }
  hermes = @{ Dir = (Join-Path $HOME '.hermes\skills\construction'); Home = (Join-Path $HOME '.hermes') }
}
$Ds = Get-ChildItem -Path $Goc -Recurse -Filter SKILL.md -File |
  Where-Object { $_.FullName -notmatch '[\\/](\.git|\.claude)[\\/]' } |
  Sort-Object { $_.FullName.Substring($Goc.Length) }

foreach ($app in $Apps) {
  if (-not $Dich.ContainsKey($app)) { Write-Host "skip ${app}: unknown app"; continue }
  $c = $Dich[$app]
  if (-not (Test-Path $c.Home) -and -not (Get-Command $app -ErrorAction SilentlyContinue)) { Write-Host "skip ${app}: not installed"; continue }
  New-Item -ItemType Directory -Force -Path $c.Dir | Out-Null
  $moi = 0; $giu = 0; $trung = 0; $daCo = @{}
  foreach ($f in $Ds) {
    $src = $f.Directory.FullName; $ten = $f.Directory.Name; $dst = Join-Path $c.Dir $ten
    if ($daCo.ContainsKey($ten)) { $trung++; continue }
    $daCo[$ten] = 1
    $dau = Join-Path $dst '.ddc-revidapi'
    if ((Test-Path $dst) -and -not ((Test-Path $dau) -and (Get-Content $dau -Raw) -match [regex]::Escape($Dau))) { $giu++; continue }
    if (Test-Path $dst) { Remove-Item -Recurse -Force $dst }
    Copy-Item -Recurse $src $dst
    Set-Content -Path $dau -Value $Dau
    $moi++
  }
  Write-Host "${app}: $moi skills -> $($c.Dir)  (kept $giu existing, skipped $trung duplicate names)"
}
Write-Host ""
Write-Host "Next: give the Python examples your RevidAPI key (OpenAI SDK):"
Write-Host '  setx OPENAI_BASE_URL https://revidapi.com/v1'
Write-Host '  setx OPENAI_API_KEY  <your RevidAPI key>'
Write-Host "Get a key at https://revidapi.com/dashboard . Restart the app so it sees the new skills."
