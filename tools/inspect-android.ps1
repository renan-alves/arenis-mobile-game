param(
    [string]$ApkPath = '',
    [string]$AndroidSdkPath = $env:ANDROID_HOME,
    [string]$JavaSdkPath = $env:JAVA_HOME
)
$ErrorActionPreference = 'Stop'
$arenisRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ApkPath)) { $ApkPath = Join-Path $arenisRoot 'build/android/arenis-debug.apk' }
$ApkPath = [IO.Path]::GetFullPath($ApkPath)
$arenisTools = Join-Path $AndroidSdkPath 'build-tools/36.1.0'
if (-not (Test-Path -LiteralPath $ApkPath)) { throw 'APK não encontrado.' }
$env:JAVA_HOME = $JavaSdkPath
& (Join-Path $arenisTools 'apksigner.bat') verify --verbose $ApkPath
if ($LASTEXITCODE -ne 0) { throw 'Assinatura APK inválida.' }
$arenisBadging = & (Join-Path $arenisTools 'aapt.exe') dump badging $ApkPath
if ($LASTEXITCODE -ne 0) { throw 'Não foi possível inspecionar o pacote Android.' }
$arenisBadging | Select-Object -First 5
Add-Type -AssemblyName System.IO.Compression.FileSystem
$arenisZip = [IO.Compression.ZipFile]::OpenRead($ApkPath)
try {
    foreach ($arenisName in @('assets/data/campaign.json','assets/locales/pt_BR.json','assets/locales/en.json','assets/locales/es_419.json','lib/arm64-v8a/libgodot_android.so')) {
        if ($null -eq $arenisZip.GetEntry($arenisName)) { throw "Arquivo obrigatório ausente: $arenisName" }
    }
    $arenisReader = [IO.StreamReader]::new($arenisZip.GetEntry('assets/data/campaign.json').Open())
    try { $arenisCampaign = $arenisReader.ReadToEnd() | ConvertFrom-Json } finally { $arenisReader.Dispose() }
    if ($arenisCampaign.levels.Count -ne 150) { throw 'O APK não contém as 150 fases da campanha.' }
    if ($arenisZip.Entries.FullName | Where-Object { $_ -match '^assets/(docs|tests|tools|platform|design)/' }) { throw 'Arquivos de desenvolvimento indevidos no APK.' }
    Write-Output 'APK: assinatura válida, 150 fases, três idiomas e arquitetura ARM64 presentes.'
} finally { $arenisZip.Dispose() }
Get-FileHash -LiteralPath $ApkPath -Algorithm SHA256 | Select-Object Hash,Path
