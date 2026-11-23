param(
    [string]$GodotPath = 'godot',
    [string]$AndroidSdkPath = $env:ANDROID_HOME,
    [string]$JavaSdkPath = $env:JAVA_HOME,
    [string]$TemplateDirectory = (Join-Path $env:APPDATA 'Godot/export_templates/4.7.2.stable'),
    [string]$OutputPath = '',
    [switch]$Release,
    [switch]$ProductionAds
)
$ErrorActionPreference = 'Stop'
$arenisRoot = Split-Path -Parent $PSScriptRoot
if (-not (Get-Command $GodotPath -ErrorAction SilentlyContinue)) { throw 'Informe -GodotPath para o Godot 4.7.2.' }
if (-not (Test-Path -LiteralPath (Join-Path $AndroidSdkPath 'platform-tools/adb.exe'))) { throw 'Informe -AndroidSdkPath com platform-tools, platform 36 e build-tools 36.1.0 instalados.' }
if (-not (Test-Path -LiteralPath (Join-Path $JavaSdkPath 'bin/java.exe'))) { throw 'Informe -JavaSdkPath com o JDK 17.' }
$arenisJavaVersion = (& (Join-Path $JavaSdkPath 'bin/java.exe') -version 2>&1 | Out-String)
if ($arenisJavaVersion -notmatch 'version "17\.') { throw 'Este build foi validado com JDK 17. Informe -JavaSdkPath para essa versão, sem alterar o Java global.' }
foreach ($arenisRequiredSdkFile in @('platforms/android-36/android.jar', 'platforms/android-36/source.properties', 'platforms/android-36/core-for-system-modules.jar', 'build-tools/36.1.0/aapt2.exe', 'build-tools/36.1.0/d8.bat')) {
    if (-not (Test-Path -LiteralPath (Join-Path $AndroidSdkPath $arenisRequiredSdkFile))) { throw "SDK Android incompleto: falta $arenisRequiredSdkFile. Reinstale o pacote correspondente pelo SDK Manager." }
}
foreach ($arenisRequiredJavaFile in @('bin/jlink.exe', 'lib/jrt-fs.jar')) {
    if (-not (Test-Path -LiteralPath (Join-Path $JavaSdkPath $arenisRequiredJavaFile))) { throw "JDK 17 incompleto: falta $arenisRequiredJavaFile. Reinstale o JDK antes de compilar." }
}
$arenisBuild = Join-Path $arenisRoot 'android/build'
if (-not (Test-Path -LiteralPath (Join-Path $arenisBuild 'gradlew.bat'))) {
    $arenisTemplate = Join-Path $TemplateDirectory 'android_source.zip'
    if (-not (Test-Path -LiteralPath $arenisTemplate)) { throw 'Instale os templates Godot 4.7.2 ou informe -TemplateDirectory.' }
    New-Item -ItemType Directory -Path $arenisBuild -Force | Out-Null
    Expand-Archive -LiteralPath $arenisTemplate -DestinationPath $arenisBuild -Force
    Set-Content -LiteralPath (Join-Path $arenisRoot 'android/.build_version') -Value '4.7.2.stable' -Encoding utf8
}
if ($Release -and [string]::IsNullOrWhiteSpace($env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH)) { throw 'Defina as variáveis GODOT_ANDROID_KEYSTORE_RELEASE_*; nenhuma chave de publicação é criada automaticamente.' }
if ($Release -and [IO.Path]::GetExtension($OutputPath) -ne '.aab') { throw 'Para release, informe -OutputPath com extensão .aab.' }
if ($ProductionAds -and -not $Release) { throw 'Anúncios de produção são permitidos apenas no build -Release. APKs de desenvolvimento sempre usam IDs de teste.' }
$env:JAVA_HOME = $JavaSdkPath
$env:ANDROID_HOME = $AndroidSdkPath
# The Windows Godot console wrapper can wait on pipes inherited by Gradle daemons.
$arenisGradleProperties = Join-Path $arenisBuild 'gradle.properties'
$arenisGradleText = [IO.File]::ReadAllText($arenisGradleProperties)
if ($arenisGradleText -notmatch '(?m)^org.gradle.daemon=') { Add-Content -LiteralPath $arenisGradleProperties -Value "`norg.gradle.daemon=false" }
$arenisAdsMode = if ($ProductionAds) { 'true' } else { 'false' }
& (Join-Path $arenisBuild 'gradlew.bat') -p (Join-Path $arenisRoot 'platform/android') assembleRelease "-ParenisProductionAds=$arenisAdsMode" --console=plain --no-daemon
if ($LASTEXITCODE -ne 0) { throw 'Falha ao compilar o plugin nativo.' }
$arenisBin = Join-Path $arenisRoot 'addons/arenis_android/bin'
New-Item -ItemType Directory -Path $arenisBin -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $arenisRoot 'platform/android/build/outputs/aar/arenis-android-release.aar') -Destination (Join-Path $arenisBin 'arenis-android.aar') -Force
$arenisSettingsPath = Join-Path $env:APPDATA 'Godot/editor_settings-4.7.tres'
$arenisSettings = if (Test-Path -LiteralPath $arenisSettingsPath) { [IO.File]::ReadAllText($arenisSettingsPath) } else { "[gd_resource type=`"EditorSettings`" format=3]`n`n[resource]`n" }
if (Test-Path -LiteralPath $arenisSettingsPath) { Copy-Item -LiteralPath $arenisSettingsPath -Destination ($arenisSettingsPath + '.before-arenis-android.bak') -Force }
foreach ($arenisEntry in @{ 'export/android/java_sdk_path'=$JavaSdkPath; 'export/android/android_sdk_path'=$AndroidSdkPath }.GetEnumerator()) {
    $arenisPattern = '(?m)^' + [Regex]::Escape($arenisEntry.Key) + '\s*=.*\r?\n?'
    $arenisSettings = [Regex]::Replace($arenisSettings, $arenisPattern, '')
    $arenisSettings += "`n" + $arenisEntry.Key + '="' + $arenisEntry.Value.Replace('\', '/') + '"' + "`n"
}
New-Item -ItemType Directory -Path (Split-Path -Parent $arenisSettingsPath) -Force | Out-Null
[IO.File]::WriteAllText($arenisSettingsPath + '.android.tmp', $arenisSettings)
[IO.File]::Move($arenisSettingsPath + '.android.tmp', $arenisSettingsPath, $true)
if ([string]::IsNullOrWhiteSpace($OutputPath)) { $OutputPath = Join-Path $arenisRoot 'build/android/arenis-debug.apk' }
$OutputPath = [IO.Path]::GetFullPath($OutputPath)
New-Item -ItemType Directory -Path (Split-Path -Parent $OutputPath) -Force | Out-Null
& $GodotPath --headless --path $arenisRoot --editor --import --quit
if ($LASTEXITCODE -ne 0) { throw 'Falha ao importar o projeto.' }
$arenisMode = if ($Release) { '--export-release' } else { '--export-debug' }
$arenisPreset = if ($Release) { 'Android AAB' } else { 'Android' }
& $GodotPath --headless --path $arenisRoot $arenisMode $arenisPreset $OutputPath
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $OutputPath)) { throw 'Falha ao exportar Android.' }
Write-Output "Android build: $OutputPath"
