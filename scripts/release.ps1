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

# 1. Pull de los últimos cambios
Write-Host "`n[1/7] Obteniendo ultimos cambios..." -ForegroundColor Green
git stash 2>$null
git pull
git stash pop 2>$null

# 2. Obtener dependencias
Write-Host "`n[2/7] Obteniendo dependencias..." -ForegroundColor Green
flutter pub get

# 3. Compilar para Windows
Write-Host "`n[3/7] Compilando para Windows..." -ForegroundColor Green
flutter build windows --release

# 4. Copiar DLLs de VC++ Runtime
Write-Host "`n[4/7] Incluyendo VC++ Runtime DLLs..." -ForegroundColor Green
$ReleaseDir = "build\windows\x64\runner\Release"
Copy-Item "C:\Windows\System32\vcruntime140.dll" -Destination $ReleaseDir -Force
Copy-Item "C:\Windows\System32\vcruntime140_1.dll" -Destination $ReleaseDir -Force
Copy-Item "C:\Windows\System32\msvcp140.dll" -Destination $ReleaseDir -Force

# 5. Crear ZIP
Write-Host "`n[5/7] Creando archivo ZIP..." -ForegroundColor Green
$ZipName = "visor-windows-v$Version.zip"
$ZipPath = "build\windows\x64\runner\$ZipName"
if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
Compress-Archive -Path "$ReleaseDir\*" -DestinationPath $ZipPath -Force

# 6. Publicar en GitHub
Write-Host "`n[6/7] Publicando en GitHub..." -ForegroundColor Green

$ReleaseExists = gh release view "v$Version" 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "Release v$Version ya existe. Actualizando archivo..." -ForegroundColor Yellow
    gh release upload "v$Version" $ZipPath --clobber
} else {
    Write-Host "Creando nuevo release v$Version..." -ForegroundColor Yellow
    $ReleaseNotes = @"
## Visor v$Version

### Descargas
- **Windows**: visor-windows-v$Version.zip (incluye VC++ Runtime)

### Notas
- Release generado automaticamente
"@
    gh release create "v$Version" $ZipPath --title "Visor v$Version" --notes $ReleaseNotes
}

# 7. Limpiar
Write-Host "`n[7/7] Limpiando archivos temporales..." -ForegroundColor Green
Remove-Item $ZipPath -Force

Write-Host "`n=== Release v$Version publicado exitosamente ===" -ForegroundColor Green
Write-Host "URL: https://github.com/huntergps/visor/releases/tag/v$Version"
