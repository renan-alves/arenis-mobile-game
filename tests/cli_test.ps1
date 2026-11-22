param([Parameter(Mandatory)][string]$GodotPath)
$ErrorActionPreference = 'Stop'
$arenisRoot = Split-Path -Parent $PSScriptRoot
$arenisTemp = Join-Path ([IO.Path]::GetTempPath()) ('arenis-cli-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $arenisTemp | Out-Null
$arenisPackPath = Join-Path $arenisRoot 'data/prototype_levels.json'
$arenisPack = Get-Content -LiteralPath $arenisPackPath -Raw | ConvertFrom-Json
$arenisFixture = Join-Path $arenisTemp 'fixture.json'
$arenisReport = Join-Path $arenisTemp 'report.json'
$arenisChecks = 0
function Invoke-ArenisCli([int]$Expected, [string[]]$Options) {
    & $GodotPath --headless --path $arenisRoot --script tools/validate_levels.gd -- @Options
    if ($LASTEXITCODE -ne $Expected) { throw "CLI: esperado $Expected, recebido $LASTEXITCODE" }
    $script:arenisChecks += 1
}
Invoke-ArenisCli 0 @('--output',$arenisReport)
if (-not (Get-Content -LiteralPath $arenisReport -Raw | ConvertFrom-Json).accepted) { throw 'Relatório válido rejeitado.' }
$arenisPack.levels = @($arenisPack.levels[0])
$arenisPack.levels[0].minimum_moves = 99
$arenisPack | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $arenisFixture -Encoding utf8
Invoke-ArenisCli 1 @('--input',$arenisFixture,'--output',$arenisReport)
if ((Get-Content -LiteralPath $arenisReport -Raw | ConvertFrom-Json).accepted) { throw 'Mínimo errado aceito.' }
Invoke-ArenisCli 0 @('--input',$arenisFixture,'--solve','--output',$arenisReport)
Invoke-ArenisCli 1 @('--max-states','1','--output',$arenisReport)
$arenisLimit = Get-Content -LiteralPath $arenisReport -Raw | ConvertFrom-Json
if ($arenisLimit.results[0].minimum_moves -ne $null -or $arenisLimit.results[0].status -ne 'limit') { throw 'Limite gerou mínimo falso.' }
$arenisHash = (Get-FileHash -LiteralPath $arenisFixture).Hash
Invoke-ArenisCli 2 @('--input',$arenisFixture,'--output',$arenisFixture)
if ((Get-FileHash -LiteralPath $arenisFixture).Hash -ne $arenisHash) { throw 'Arquivo fonte sobrescrito.' }
Set-Content -LiteralPath $arenisFixture -Value '{ invalid' -Encoding utf8
Invoke-ArenisCli 2 @('--input',$arenisFixture,'--output',$arenisReport)
if ((Get-Content -LiteralPath $arenisReport -Raw | ConvertFrom-Json).accepted) { throw 'Relatório antigo aceito após erro de JSON.' }
Write-Output "CLI: $arenisChecks cenários, zero falhas."
