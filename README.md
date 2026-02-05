# Visor

Aplicación multiplataforma para visualización de productos con búsqueda, escaneo de códigos de barras y gestión de imágenes.

## Descargas

[![GitHub Release](https://img.shields.io/github/v/release/huntergps/visor)](https://github.com/huntergps/visor/releases/latest)

| Plataforma | Descarga |
|------------|----------|
| Windows | [Descargar](https://github.com/huntergps/visor/releases/latest/download/visor-windows-v1.0.0.zip) |
| macOS | [Descargar](https://github.com/huntergps/visor/releases/latest) |
| Linux | [Descargar](https://github.com/huntergps/visor/releases/latest) |
| Android | [Descargar](https://github.com/huntergps/visor/releases/latest) |
| iOS | Disponible en App Store (próximamente) |

[Ver todas las versiones](https://github.com/huntergps/visor/releases)

## Características

- **Búsqueda de productos** - Búsqueda rápida por nombre o código
- **Escaneo de códigos de barras** - Soporte para cámara en dispositivos móviles y desktop
- **Visualización de precios** - Muestra precios, descuentos y presentaciones
- **Editor de imágenes** - Captura, recorta y edita imágenes de productos
- **Caché inteligente** - Almacenamiento local de imágenes para mejor rendimiento
- **Multiplataforma** - Disponible para Windows, macOS, Linux, Android, iOS y Web
- **Configuración flexible** - API personalizable según necesidades

## Capturas de pantalla

<p align="center">
  <img src="docs/iphone1_noalpha.png" width="200" alt="iPhone Screenshot 1"/>
  <img src="docs/iphone2_noalpha.png" width="200" alt="iPhone Screenshot 2"/>
  <img src="docs/iphone3_noalpha.png" width="200" alt="iPhone Screenshot 3"/>
</p>

<p align="center">
  <img src="docs/mac1_noalpha.png" width="600" alt="Mac Screenshot"/>
</p>

## Requisitos

### Para usuarios
- **Windows**: Windows 10 o superior (x64) - Incluye VC++ Runtime, no requiere instalación adicional
- **macOS**: macOS 10.14 o superior
- **Linux**: Ubuntu 18.04 o superior
- **Android**: Android 5.0 (API 21) o superior
- **iOS**: iOS 12.0 o superior

### Para desarrolladores
- Flutter SDK 3.10.3 o superior
- Dart SDK 3.0 o superior

## Instalación para desarrollo

1. Clona el repositorio:
```bash
git clone https://github.com/huntergps/visor.git
cd visor
```

2. Instala las dependencias:
```bash
flutter pub get
```

3. Configura el archivo `.env` con las credenciales de la API:
```env
API_URL=tu_url_api
API_KEY=tu_api_key
```

4. Ejecuta la aplicación:
```bash
flutter run
```

## Compilación

### Windows
```bash
flutter build windows --release
```

### macOS
```bash
flutter build macos --release
```

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## Licencia

Este proyecto es software propietario. Todos los derechos reservados.

## Soporte

Para reportar problemas o solicitar funcionalidades, crea un [issue](https://github.com/huntergps/visor/issues).
