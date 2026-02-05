#!/bin/bash
# Script para compilar y publicar release de Visor
# Uso: ./scripts/release.sh [version]
# Ejemplo: ./scripts/release.sh 1.0.1

set -e  # Salir si hay error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # Sin color

echo -e "${GREEN}=== Visor Release Script ===${NC}"

# Directorio del proyecto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

# Obtener versión del argumento o del pubspec.yaml
if [ -n "$1" ]; then
    VERSION="$1"
else
    VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //' | sed 's/+.*//')
fi

echo -e "${YELLOW}Versión: v${VERSION}${NC}"

# 1. Pull de los últimos cambios
echo -e "\n${GREEN}[1/7] Obteniendo últimos cambios...${NC}"
git stash --quiet 2>/dev/null || true
git pull
git stash pop --quiet 2>/dev/null || true

# 2. Obtener dependencias
echo -e "\n${GREEN}[2/7] Obteniendo dependencias...${NC}"
flutter pub get

# 3. Compilar para Windows
echo -e "\n${GREEN}[3/7] Compilando para Windows...${NC}"
flutter build windows --release

# 4. Copiar DLLs de VC++ Runtime
echo -e "\n${GREEN}[4/7] Incluyendo VC++ Runtime DLLs...${NC}"
RELEASE_DIR="build/windows/x64/runner/Release"
cp /c/Windows/System32/vcruntime140.dll "$RELEASE_DIR/"
cp /c/Windows/System32/vcruntime140_1.dll "$RELEASE_DIR/"
cp /c/Windows/System32/msvcp140.dll "$RELEASE_DIR/"

# 5. Crear ZIP
echo -e "\n${GREEN}[5/7] Creando archivo ZIP...${NC}"
ZIP_NAME="visor-windows-v${VERSION}.zip"
cd build/windows/x64/runner
powershell "Compress-Archive -Path 'Release\*' -DestinationPath '${ZIP_NAME}' -Force"
cd "$PROJECT_DIR"

# 6. Verificar si el release ya existe
echo -e "\n${GREEN}[6/7] Publicando en GitHub...${NC}"
ZIP_PATH="build/windows/x64/runner/${ZIP_NAME}"

if gh release view "v${VERSION}" &>/dev/null; then
    echo -e "${YELLOW}Release v${VERSION} ya existe. Actualizando archivo...${NC}"
    gh release upload "v${VERSION}" "$ZIP_PATH" --clobber
else
    echo -e "${YELLOW}Creando nuevo release v${VERSION}...${NC}"
    gh release create "v${VERSION}" "$ZIP_PATH" \
        --title "Visor v${VERSION}" \
        --notes "## Visor v${VERSION}

### Descargas
- **Windows**: visor-windows-v${VERSION}.zip (incluye VC++ Runtime)

### Notas
- Release generado automáticamente
"
fi

# 7. Limpiar
echo -e "\n${GREEN}[7/7] Limpiando archivos temporales...${NC}"
rm -f "$ZIP_PATH"

echo -e "\n${GREEN}=== Release v${VERSION} publicado exitosamente ===${NC}"
echo -e "URL: https://github.com/huntergps/visor/releases/tag/v${VERSION}"
