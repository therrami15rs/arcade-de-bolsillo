# ============================================================
#  Compila "Arcade de bolsillo" en tu PC con Windows.
#  Uso (en PowerShell, dentro de esta carpeta):
#     .\compilar.ps1            -> APK de Android y programa de Windows
#     .\compilar.ps1 android    -> solo el APK
#     .\compilar.ps1 windows    -> solo Windows
#     .\compilar.ps1 instalar   -> APK y lo instala en el celular conectado por USB
#  Se puede ejecutar varias veces: no duplica cambios.
# ============================================================
param([ValidateSet('todo','android','windows','instalar')][string]$Que = 'todo')
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

function Paso($t) { Write-Host "`n==> $t" -ForegroundColor Cyan }
function Ejecutar($cmd) {
  Write-Host "   $cmd" -ForegroundColor DarkGray
  & cmd /c $cmd
  if ($LASTEXITCODE -ne 0) { throw "Falló: $cmd" }
}
function Reemplazar($ruta, $viejo, $nuevo) {
  if (-not (Test-Path $ruta)) { return $false }
  $t = [IO.File]::ReadAllText($ruta)
  if ($t.Contains($viejo)) {
    [IO.File]::WriteAllText($ruta, $t.Replace($viejo, $nuevo), (New-Object Text.UTF8Encoding $false))
    Write-Host "   parchado: $ruta"
    return $true
  }
  return $false
}

$quiereAndroid = $Que -in 'todo','android','instalar'
$quiereWindows = $Que -in 'todo','windows'

Paso "Revisando Flutter"
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw "No encuentro Flutter. Instálalo (guía en COMPILAR-EN-MI-PC.md) y abre una nueva ventana de PowerShell."
}
Ejecutar "flutter --version"

# 1) Generar las carpetas android/ y windows/ (no vienen en el proyecto)
$plataformas = @()
if ($quiereAndroid -and -not (Test-Path 'android')) { $plataformas += 'android' }
if ($quiereWindows -and -not (Test-Path 'windows')) { $plataformas += 'windows' }
if ($plataformas.Count -gt 0) {
  Paso "Generando carpetas: $($plataformas -join ', ')"
  Ejecutar "flutter create --platforms=$($plataformas -join ',') --project-name arcade_de_bolsillo --org com.ramiro ."
  if (Test-Path 'test\widget_test.dart') { Remove-Item 'test\widget_test.dart' }  # prueba de ejemplo que no aplica
}

# 2) Ajustes de nombre, permisos y ventana (lo mismo que tool/parchar_plataformas.py)
if ($quiereAndroid) {
  Paso "Ajustando Android (nombre, vibración, minSdk 24)"
  $man = 'android\app\src\main\AndroidManifest.xml'
  $m = [IO.File]::ReadAllText($man)
  $m = [regex]::Replace($m, 'android:label="[^"]*"', 'android:label="Arcade de bolsillo"', 1)
  if ($m -notmatch 'android.permission.VIBRATE') {
    $m = ([regex]'<application').Replace($m, "<uses-permission android:name=`"android.permission.VIBRATE`"/>`n    <application", 1)
  }
  [IO.File]::WriteAllText($man, $m, (New-Object Text.UTF8Encoding $false))
  foreach ($g in 'android\app\build.gradle.kts', 'android\app\build.gradle') {
    $null = Reemplazar $g 'minSdk = flutter.minSdkVersion' 'minSdk = 24'
    $null = Reemplazar $g 'minSdkVersion flutter.minSdkVersion' 'minSdkVersion 24'
  }
}
if ($quiereWindows) {
  Paso "Ajustando Windows (título y ventana maximizada)"
  $null = Reemplazar 'windows\runner\main.cpp' 'L"arcade_de_bolsillo"' 'L"Arcade de bolsillo"'
  $null = Reemplazar 'windows\runner\win32_window.cpp' 'SW_SHOWNORMAL' 'SW_SHOWMAXIMIZED'
}

# 3) Descargar paquetes
Paso "Descargando paquetes (flutter pub get)"
Ejecutar "flutter pub get"

# 4) Compatibilidad: flutter_inappwebview 6.1.5 usa una regla de ProGuard
#    que el Android Gradle Plugin nuevo ya no acepta.
if ($quiereAndroid) {
  Paso "Compatibilidad de flutter_inappwebview con Android nuevo"
  $cache = if ($env:PUB_CACHE) { $env:PUB_CACHE } else { Join-Path $env:LOCALAPPDATA 'Pub\Cache' }
  Get-ChildItem (Join-Path $cache 'hosted\pub.dev') -Directory -Filter 'flutter_inappwebview_android-*' -ErrorAction SilentlyContinue |
    ForEach-Object { $null = Reemplazar (Join-Path $_.FullName 'android\build.gradle') "proguard-android.txt'" "proguard-android-optimize.txt'" }
}

# 5) Iconos, análisis y pruebas
Paso "Generando iconos"
if ($quiereAndroid) { Ejecutar "dart run flutter_launcher_icons" }
else { Ejecutar "dart run flutter_launcher_icons -f tool/iconos_windows.yaml" }
Paso "Revisando el código y corriendo las pruebas"
Ejecutar "flutter analyze --no-fatal-infos"
Ejecutar "flutter test"

# 6) Compilar
New-Item -ItemType Directory -Force 'salida' | Out-Null
if ($quiereAndroid) {
  Paso "Compilando el APK (la primera vez tarda varios minutos)"
  Ejecutar "flutter build apk --release"
  Copy-Item 'build\app\outputs\flutter-apk\app-release.apk' 'salida\ArcadeDeBolsillo.apk' -Force
  Write-Host "   Listo: salida\ArcadeDeBolsillo.apk" -ForegroundColor Green
  if ($Que -eq 'instalar') {
    Paso "Instalando en el celular conectado por USB"
    Ejecutar "flutter install --release"
  }
}
if ($quiereWindows) {
  Paso "Compilando para Windows"
  # Visual Studio nuevo marca como error las corrutinas "experimentales" del plugin.
  $env:CL = '/D_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS'
  Ejecutar "flutter build windows --release"
  Remove-Item 'salida\ArcadeDeBolsillo-Windows' -Recurse -Force -ErrorAction SilentlyContinue
  Copy-Item 'build\windows\x64\runner\Release' 'salida\ArcadeDeBolsillo-Windows' -Recurse
  Write-Host "   Listo: salida\ArcadeDeBolsillo-Windows\arcade_de_bolsillo.exe" -ForegroundColor Green
}
Paso "¡Terminado! Revisa la carpeta 'salida'."
