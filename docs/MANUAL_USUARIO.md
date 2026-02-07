# Manual de Usuario - TheosVisor

## Visor de Precios - Mega Primavera

TheosVisor es una aplicación de consulta de precios para los establecimientos Mega Primavera. Permite buscar productos por código de barras o texto, visualizar precios, descuentos y presentaciones, así como gestionar imágenes publicitarias.

---

## Tabla de Contenido

- [Instalación](#instalación)
  - [Android](#android)
  - [iOS (iPhone / iPad)](#ios-iphone--ipad)
  - [macOS](#macos)
  - [Windows](#windows)
- [Inicio de la Aplicación](#inicio-de-la-aplicación)
- [Pantalla Principal](#pantalla-principal)
- [Buscar un Producto](#buscar-un-producto)
  - [Por teclado](#por-teclado)
  - [Con escáner de código de barras](#con-escáner-de-código-de-barras)
- [Información del Producto](#información-del-producto)
- [Imágenes Publicitarias](#imágenes-publicitarias)
- [Iniciar Sesión](#iniciar-sesión)
- [Editor de Imágenes](#editor-de-imágenes)
- [Configuración](#configuración)
- [Acerca de](#acerca-de)
- [Solución de Problemas](#solución-de-problemas)

---

## Instalación

### Android

1. Descargar el archivo `app-release.apk` desde [GitHub Releases](https://github.com/huntergps/visor/releases/tag/v1.0.0-android)
2. En el dispositivo, ir a **Ajustes > Seguridad** y habilitar **"Instalar aplicaciones de fuentes desconocidas"**
3. Abrir el archivo `.apk` descargado
4. Pulsar **Instalar**
5. Si aparece una advertencia de Play Protect, pulsar **"Instalar de todos modos"**
6. Abrir **TheosVisor** desde el cajón de aplicaciones

### iOS (iPhone / iPad)

La app se distribuye a través de **TestFlight**:

1. Instalar [TestFlight](https://apps.apple.com/app/testflight/id899247664) desde la App Store
2. Solicitar una invitación al administrador (se envía por email)
3. Abrir el enlace de invitación desde el dispositivo
4. Pulsar **Instalar** en TestFlight

### macOS

1. Descargar `TheosVisor-1.0.0-macos.dmg` desde [GitHub Releases](https://github.com/huntergps/visor/releases/tag/v1.0.0-macos)
2. Abrir el archivo `.dmg`
3. Arrastrar **Visor** a la carpeta **Applications**
4. Abrir desde **Aplicaciones** o **Launchpad**

> La app está firmada y notarizada por Apple. No debería mostrar advertencias.

### Windows

1. Descargar `visor-windows-v1.0.0.zip` desde [GitHub Releases](https://github.com/huntergps/visor/releases/tag/v1.0.0)
2. Extraer el contenido del ZIP
3. Ejecutar `visor.exe`

> Incluye las DLLs necesarias (VC++ Runtime). No requiere instalación adicional.

---

## Inicio de la Aplicación

Al abrir TheosVisor, se muestra una **pantalla de carga** mientras se descargan las imágenes publicitarias del servidor. Se muestra una barra de progreso indicando el grupo que se está descargando (1/4 a 4/4).

Una vez completada la carga, aparece la pantalla principal lista para consultar productos.

---

## Pantalla Principal

<p align="center">
  <img src="iphone1_noalpha.png" width="250" alt="Pantalla principal"/>
</p>

La pantalla principal se compone de:

- **Encabezado**: Logo de Mega Primavera y título "MEGA | PRIMAVERA"
- **Barra de búsqueda**: Campo para digitar el código del producto
- **Imagen del producto**: Fotografía del producto consultado
- **Información del producto**: Nombre, código, familia, precio y descuentos
- **Pie de página**: Barra inferior con accesos rápidos

---

## Buscar un Producto

### Por teclado

1. Tocar la **barra de búsqueda** (campo "Digitar código del producto...")
2. Escribir el **código de barras** o **código interno** del producto
3. Presionar **Enter** o el botón de flecha para buscar

**En escritorio (Windows/macOS):** El campo de búsqueda se enfoca automáticamente. Puede usar un **lector de código de barras USB** que envía el código seguido de Enter.

**En móvil:** Tocar el campo para mostrar el teclado. Use el botón de teclado para mostrar/ocultar.

### Con escáner de código de barras

*Solo disponible en dispositivos con cámara (Android, iOS, macOS)*

1. Pulsar el botón de **escáner** (icono de código QR)
2. Apuntar la cámara al **código de barras** del producto
3. El escáner detecta automáticamente el código y emite un sonido de confirmación
4. La búsqueda se realiza automáticamente

<p align="center">
  <img src="iphone2_noalpha.png" width="250" alt="Escáner de código de barras"/>
</p>

**Funciones del escáner:**
- **Flash**: Encender/apagar la linterna para iluminar el código
- **Cambiar cámara**: Alternar entre cámara trasera y delantera
- **Cancelar**: Cerrar el escáner sin buscar

**Formatos soportados:** EAN-13, EAN-8, UPC-A, UPC-E, Code 128, Code 39, Code 93, Codabar, ITF

> Nota: El escáner NO lee códigos QR, solo códigos de barras lineales.

---

## Información del Producto

Al encontrar un producto, se muestra:

| Campo | Descripción |
|-------|-------------|
| **Nombre** | Nombre completo del producto |
| **Código** | Código de barras o código interno |
| **Familia** | Categoría o familia del producto |
| **Precio regular** | Precio sin descuento (tachado si hay descuento) |
| **Precio final** | Precio actual con descuento aplicado |
| **Descuento** | Porcentaje de descuento (si aplica) |
| **Unidad** | Unidad de medida (kg, lb, unidad, etc.) |
| **Presentaciones** | Otras presentaciones disponibles del mismo producto |

<p align="center">
  <img src="iphone3_noalpha.png" width="250" alt="Información del producto"/>
</p>

### Limpiar búsqueda

Pulsar el botón **X** en la barra de búsqueda para limpiar el campo y la información del producto actual.

---

## Imágenes Publicitarias

Cuando no se está consultando un producto, la aplicación muestra un **carrusel de imágenes publicitarias** que rotan automáticamente. Estas imágenes se descargan del servidor al iniciar la app.

El tiempo entre imágenes es configurable desde la pantalla de configuración.

---

## Iniciar Sesión

Para acceder a funciones de edición, es necesario iniciar sesión:

1. Pulsar el **icono de persona** en la esquina superior derecha (móvil) o en la barra de título (escritorio)
2. Ingresar **Usuario** y **PIN**
3. Pulsar **Ingresar**

Una vez autenticado, el icono de persona cambia a un icono sólido. Al pulsarlo muestra:
- Nombre del usuario
- Si tiene permisos de editor
- Botón para **Cerrar Sesión**

---

## Editor de Imágenes

*Requiere iniciar sesión con permisos de editor*

Cuando está autenticado como editor, puede modificar la imagen del producto:

1. Buscar un producto
2. Pulsar el botón de **cámara** sobre la imagen del producto
3. Elegir entre:
   - **Tomar foto**: Usar la cámara del dispositivo
   - **Seleccionar de galería**: Elegir una imagen existente
4. **Recortar** la imagen al tamaño adecuado
5. La imagen se sube automáticamente al servidor

---

## Configuración

Para acceder a la configuración:

**En escritorio:** Pulsar el icono de **engranaje** en la barra de título

**En móvil:** Pulsar el icono de **engranaje** en el pie de página

### Opciones disponibles

| Opción | Descripción |
|--------|-------------|
| **URL del Servidor** | Dirección del servidor ERP |
| **API Key** | Clave de autenticación para la API |
| **Tiempo de espera** | Segundos de inactividad antes de mostrar publicidad |
| **Tiempo entre Ads** | Segundos entre cada imagen publicitaria |
| **Estilo del escáner** | En línea (dentro de la barra) o flotante (botón) |
| **Carpeta de caché** | Ubicación del caché de imágenes (solo escritorio) |
| **Actualizar desde Servidor** | Forzar re-descarga de imágenes publicitarias |

---

## Acerca de

Para ver información de la aplicación:

**En móvil:** Tocar el título **"MEGA | PRIMAVERA"** en el encabezado

**En escritorio:** Pulsar el botón de **información** en la barra de título

Muestra la versión de la app y datos de contacto de GalapagosTech.

---

## Solución de Problemas

### La app no conecta al servidor
- Verificar que el dispositivo esté en la **misma red** que el servidor ERP
- Revisar la **URL del servidor** en Configuración
- Verificar que el **API Key** sea correcto

### El escáner no lee el código
- Asegurar buena **iluminación** (use el botón de flash)
- Mantener el código de barras **centrado** en la pantalla
- Verificar que el código no esté **dañado o borroso**
- Acercar o alejar la cámara para mejor enfoque

### No aparecen imágenes publicitarias
- Verificar la conexión al servidor
- Ir a **Configuración > Actualizar desde Servidor**
- Esperar a que se complete la descarga de los 4 grupos

### El teclado no aparece (móvil)
- Pulsar el botón de **teclado** en la barra de búsqueda
- Si persiste, tocar directamente el campo de texto

### La app muestra "producto no encontrado"
- Verificar que el código sea correcto
- Intentar con el **código interno** en lugar del código de barras
- Confirmar que el producto existe en el sistema ERP

---

## Contacto y Soporte

- **Desarrollador:** GalapagosTech
- **Web:** [galapagos.tech](https://galapagos.tech)
- **Email:** info@galapagos.tech
- **Reportar problemas:** [GitHub Issues](https://github.com/huntergps/visor/issues)
- **Política de Privacidad:** [galapagos.tech/theosvisor-privacidad](https://galapagos.tech/theosvisor-privacidad)
