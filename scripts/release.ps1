# Script para compilar y publicar release de Visor
# Uso: .\scripts\release.ps1 [-Version "1.0.1"]
# Ejemplo: .\scripts\release.ps1 -Version "1.0.1"

param(
    [string]$Version
)

$ErrorActionPreference = "Stop"

Write-Host "=== Visor Release Script ===" -ForegroundColor Green

# Directorio del proyecto
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir
Set-Location $ProjectDir

# Obtener versión del parámetro o del pubspec.yaml
if (-not $Version) {
    $PubspecContent = Get-Content "pubspec.yaml" -Raw
    if ($PubspecContent -match 'version:\s*(\d+\.\d+\.\d+)') {
        $Version = $Matches[1]
    } else {
        Write-Host "Error: No se pudo obtener la versión" -ForegroundColor Red
        exit 1
    }
}

Write-Host "Version: v$Version" -ForegroundColor Yellow

# Crear directorio de instaladores si no existe
$InstaladorDir = "$ProjectDir\instalador"
if (-not (Test-Path $InstaladorDir)) {
    New-Item -ItemType Directory -Path $InstaladorDir | Out-Null
    Write-Host "Directorio 'instalador' creado" -ForegroundColor Yellow
}

# 1. Pull de los últimos cambios
Write-Host "`n[1/6] Obteniendo ultimos cambios..." -ForegroundColor Green
$ErrorActionPreference = "Continue"
git stash 2>$null
git pull
git stash pop 2>$null
$ErrorActionPreference = "Stop"

# 2. Obtener dependencias
Write-Host "`n[2/6] Obteniendo dependencias..." -ForegroundColor Green
flutter pub get

# 3. Compilar para Windows
Write-Host "`n[3/6] Compilando para Windows..." -ForegroundColor Green
flutter build windows --release

# 4. Copiar DLLs de VC++ Runtime
Write-Host "`n[4/6] Incluyendo VC++ Runtime DLLs..." -ForegroundColor Green
$ReleaseDir = "build\windows\x64\runner\Release"
Copy-Item "C:\Windows\System32\vcruntime140.dll" -Destination $ReleaseDir -Force
Copy-Item "C:\Windows\System32\vcruntime140_1.dll" -Destination $ReleaseDir -Force
Copy-Item "C:\Windows\System32\msvcp140.dll" -Destination $ReleaseDir -Force

# 5. Crear instalador con Inno Setup
Write-Host "`n[5/6] Creando instalador con Inno Setup..." -ForegroundColor Green
$InnoSetup = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
$IssFile = "$ProjectDir\scripts\installer.iss"
$InstallerName = "visor-windows-v$Version-setup.exe"
$InstallerPath = "instalador\$InstallerName"
& $InnoSetup /DMyAppVersion=$Version /DMyProjectDir=$ProjectDir $IssFile
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Fallo al crear el instalador" -ForegroundColor Red
    exit 1
}

# 6. Publicar en GitHub
Write-Host "`n[6/6] Publicando en GitHub..." -ForegroundColor Green

$ErrorActionPreference = "Continue"
$ReleaseExists = gh release view "v$Version" 2>$null
$ErrorActionPreference = "Stop"
if ($LASTEXITCODE -eq 0) {
    Write-Host "Release v$Version ya existe. Actualizando archivo..." -ForegroundColor Yellow
    gh release upload "v$Version" $InstallerPath --clobber
} else {
    Write-Host "Creando nuevo release v$Version..." -ForegroundColor Yellow
    $ReleaseNotes = @"
## Visor v$Version

### Descargas
- **Windows**: $InstallerName (instalador, incluye VC++ Runtime)

### Notas
- Release generado automaticamente
"@
    gh release create "v$Version" $InstallerPath --title "Visor v$Version" --notes $ReleaseNotes
}

Write-Host "`n=== Release v$Version publicado exitosamente ===" -ForegroundColor Green
Write-Host "Instalador guardado en: $InstallerPath"
Write-Host "URL: https://github.com/huntergps/visor/releases/tag/v$Version"
