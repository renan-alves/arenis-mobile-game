param([string]$GodotPath = 'godot')
$ErrorActionPreference = 'Stop'
$arenisRoot = Split-Path -Parent $PSScriptRoot
if (-not (Get-Command $GodotPath -ErrorAction SilentlyContinue)) {
    throw 'Godot não encontrado. Informe -GodotPath com o caminho do executável Godot 4.7.2.'
}
& $GodotPath --headless --path $arenisRoot --editor --import --quit --quiet | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Falha ao importar recursos do Godot.' }
& $GodotPath --path $arenisRoot
if ($LASTEXITCODE -ne 0) { throw "Godot encerrou com código $LASTEXITCODE" }
