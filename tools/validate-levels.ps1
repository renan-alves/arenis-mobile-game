param(
    [string]$GodotPath = 'godot',
    [string]$InputPath = 'data/prototype_levels.json',
    [string]$OutputPath = '',
    [ValidateRange(1,2147483647)][int]$MaxStates = 100000,
    [ValidateRange(1,2147483647)][int]$MaxMs = 10000,
    [switch]$Solve
)
$ErrorActionPreference = 'Stop'
$arenisRoot = Split-Path -Parent $PSScriptRoot
if (-not (Get-Command $GodotPath -ErrorAction SilentlyContinue)) { throw 'Informe -GodotPath com o executável do Godot.' }
function Resolve-ArenisPath([string]$Value) {
    if ($Value.StartsWith('res://') -or $Value.StartsWith('user://') -or [IO.Path]::IsPathRooted($Value)) { return $Value }
    return Join-Path $arenisRoot $Value
}
$arenisArgs = @('--headless','--path',$arenisRoot,'--script','tools/validate_levels.gd','--','--input',(Resolve-ArenisPath $InputPath),'--max-states',"$MaxStates",'--max-ms',"$MaxMs")
if ($OutputPath) { $arenisArgs += @('--output',(Resolve-ArenisPath $OutputPath)) }
if ($Solve) { $arenisArgs += '--solve' }
& $GodotPath @arenisArgs
if ($LASTEXITCODE -ne 0) { throw "Validação não aprovada (código $LASTEXITCODE). Consulte a saída e o relatório." }
