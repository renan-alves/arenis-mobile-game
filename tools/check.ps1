param([string]$GodotPath = 'godot')
$ErrorActionPreference = 'Stop'
$arenisRoot = Split-Path -Parent $PSScriptRoot
if (-not (Get-Command $GodotPath -ErrorAction SilentlyContinue)) {
    throw 'Godot não encontrado. Informe -GodotPath com o caminho do executável Godot 4.7.2.'
}
& $GodotPath --headless --path $arenisRoot --editor --import --quit --quiet | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Falha ao importar recursos do Godot.' }
& (Join-Path $arenisRoot 'tests/cli_test.ps1') -GodotPath $GodotPath
foreach ($arenisSuite in @('tests/journey_test.gd', 'tests/screen_audit_test.gd', 'tests/rules_test.gd', 'tests/ui_test.gd', 'tests/solver_test.gd', 'tests/identity_test.gd', 'tests/layout_test.gd', 'tests/campaign_test.gd', 'tests/polish_test.gd', 'tests/refinement_test.gd', 'tests/progress_theme_test.gd', 'tests/sand_ending_test.gd', 'tests/palette_test.gd', 'tests/mechanic_intro_test.gd', 'tests/session_test.gd', 'tests/localization_test.gd', 'tests/basic_tutorial_test.gd', 'tests/android_services_test.gd', 'tests/android_flow_test.gd')) {
    & $GodotPath --headless --path $arenisRoot --script $arenisSuite
    if ($LASTEXITCODE -ne 0) { throw "Falha em $arenisSuite" }
}
