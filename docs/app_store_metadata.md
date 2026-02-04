# TheosVisor - App Store Connect Metadata

## Información General

| Campo | Valor |
|-------|-------|
| **App Name** | TheosVisor |
| **Subtitle** | Visor de precios y productos |
| **Bundle ID** | tech.galapagos.theosvisor |
| **SKU** | theosvisor-001 |
| **Primary Category** | Business |
| **Secondary Category** | Utilities |
| **Content Rating** | 4+ |
| **Copyright** | 2026 Galapagos Tech |
| **Version** | 1.0.0 |
| **Build** | 1 |

---

## Descripción (App Store - Español)

```
TheosVisor es un visor de precios y productos diseñado para establecimientos comerciales. Consulta información de productos de forma rápida escaneando códigos de barras o buscando por nombre.

Características principales:

- Escaneo de códigos de barras con la cámara del dispositivo
- Búsqueda de productos por código o nombre
- Visualización de precios, stock, descuentos y presentaciones
- Captura y edición de imágenes de productos (recorte, rotación, brillo, eliminación de fondo)
- Subida de imágenes al servidor del sistema ERP
- Caché local de imágenes para consulta rápida sin conexión
- Modo publicidad con rotación de promociones
- Compatible con iPhone, iPad y Mac

TheosVisor se conecta al servidor de su sistema ERP para obtener datos actualizados de productos. Requiere configuración inicial del servidor.
```

---

## Descripción (App Store - English)

```
TheosVisor is a price and product viewer designed for retail stores. Quickly check product information by scanning barcodes or searching by name.

Key features:

- Barcode scanning with device camera
- Product search by code or name
- View prices, stock, discounts and presentations
- Capture and edit product images (crop, rotate, brightness, background removal)
- Upload images to your ERP server
- Local image cache for quick offline viewing
- Advertisement mode with promotional rotation
- Compatible with iPhone, iPad and Mac

TheosVisor connects to your ERP system server for up-to-date product data. Initial server configuration required.
```

---

## Promotional Text (170 chars max)

**Español:**
```
Consulta precios y productos al instante. Escanea códigos de barras, edita fotos y sincroniza con tu sistema ERP.
```

**English:**
```
Check prices and products instantly. Scan barcodes, edit photos and sync with your ERP system.
```

---

## Keywords (100 chars max)

**Español:**
```
visor,precios,productos,barcode,escáner,ERP,inventario,stock,retail,comercio
```

**English:**
```
price,checker,barcode,scanner,products,ERP,inventory,stock,retail,viewer
```

---

## URLs

| Campo | URL |
|-------|-----|
| **Support URL** | https://galapagos.tech/soporte |
| **Marketing URL** | https://galapagos.tech/theosvisor |
| **Privacy Policy URL** | https://galapagos.tech/theosvisor/privacidad |

> **NOTA**: Estas URLs deben estar activas antes de enviar a revisión. La política de privacidad está incluida en `docs/privacy_policy.html` para subir al hosting.

---

## Screenshots Requeridos

### iPhone (Obligatorio: 6.9")
- **Dimensiones**: 1320 x 2868 px (portrait)
- **Cantidad**: Mínimo 1, máximo 10
- **Sugeridas**:
  1. Pantalla principal con producto escaneado (precio, imagen, stock)
  2. Escáner de código de barras activo
  3. Editor de imágenes (crop/edición)
  4. Vista previa de imagen antes de subir
  5. Modo publicidad/promociones

### iPad (Obligatorio: 13")
- **Dimensiones**: 2064 x 2752 px (portrait)
- **Cantidad**: Mínimo 1, máximo 10
- **Sugeridas**: Mismas pantallas que iPhone adaptadas a iPad

### Mac (si se publica en Mac App Store)
- **Dimensiones**: 2880 x 1800 px o 2560 x 1600 px
- **Cantidad**: Mínimo 1, máximo 10
- **Sugeridas**: Mismas funcionalidades en ventana de escritorio

### Formato
- PNG o JPEG (sin transparencia)
- RGB, 72 DPI
- Máximo 10 MB por screenshot

---

## Age Rating Questionnaire

| Pregunta | Respuesta |
|----------|-----------|
| Cartoon or Fantasy Violence | None |
| Realistic Violence | None |
| Prolonged Graphic or Sadistic Violence | None |
| Profanity or Crude Humor | None |
| Mature/Suggestive Themes | None |
| Horror/Fear Themes | None |
| Medical/Treatment Information | None |
| Alcohol, Tobacco, or Drug Use | None |
| Simulated Gambling | None |
| Sexual Content or Nudity | None |
| Unrestricted Web Access | No |
| Gambling with Real Currency | No |

**Resultado**: 4+

---

## Privacy Nutrition Labels (App Store Connect)

### Data Not Collected
TheosVisor no recopila datos del usuario. Seleccionar:
- **"Data Not Collected"** en App Store Connect

### Detalles
- No analytics
- No advertising
- No tracking
- No third-party data sharing
- No user accounts / login

---

## Export Compliance

| Campo | Valor |
|-------|-------|
| Uses encryption? | No (solo HTTPS estándar del sistema) |
| `ITSAppUsesNonExemptEncryption` | `false` |
| ECCN | N/A |

---

## Review Notes (para el equipo de Apple Review)

```
TheosVisor es una aplicación empresarial que se conecta a un servidor ERP privado para consultar información de productos.

Para probar la aplicación:
1. Abra la app y toque dos veces en la palabra "confianza" (parte inferior de la pantalla) para acceder a la configuración
2. Configure el servidor: [proporcionar datos de demo si es posible]
3. Escanee un código de barras o escriba un código de producto en el campo de búsqueda
4. La app mostrará precio, stock e imagen del producto

Nota: La app requiere conexión a un servidor ERP configurado. Sin servidor, mostrará "Servidor no configurado".
```

---

## Checklist Pre-Envío

- [ ] App compilada con Xcode más reciente
- [ ] IPA generado y subido via Transporter o xcrun altool
- [ ] Screenshots para iPhone 6.9" (1320x2868)
- [ ] Screenshots para iPad 13" (2064x2752)
- [ ] Screenshots para Mac (2880x1800) si aplica
- [ ] Política de privacidad publicada en URL activa
- [ ] Support URL activa
- [ ] Descripción en español e inglés
- [ ] Keywords configurados
- [ ] Age rating completado
- [ ] Privacy nutrition labels completados
- [ ] Export compliance marcado como NO
- [ ] Review notes escritas
- [ ] App icon visible en todos los tamaños
- [ ] Launch screen personalizado (no placeholder)
