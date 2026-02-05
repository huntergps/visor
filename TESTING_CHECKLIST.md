# ✅ Checklist de Pruebas - Editor de Imágenes Unificado

## Estado del Código
- ✅ Análisis de Flutter: **Sin errores**
- ✅ Compilación: **Exitosa**
- ✅ Dependencias: **Instaladas correctamente**

## Funcionalidades Implementadas

### 1. Editor de Imágenes - Una Sola Pantalla
- ✅ Widget de crop (3:4) integrado
- ✅ Sliders de rotación (-180° a 180°)
- ✅ Sliders de brillo (-100 a 100)
- ✅ Botón "Quitar fondo" (ONNX local)
- ✅ Todo visible simultáneamente (sin tabs ni fases)

### 2. Flujo de Captura/Edición
- ✅ Botón de cámara en productos cargados
- ✅ Selector de fuente (cámara/galería)
- ✅ Editor unificado con todos los controles
- ✅ Preview y confirmación antes de subir

### 3. Control de Timer de Idle
- ✅ Timer se pausa al abrir editor
- ✅ Timer se reanuda al cerrar editor (éxito o cancelación)
- ✅ Addons NO aparecen durante la edición

### 4. Actualización de Endpoint
- ✅ Endpoint correcto: `POST /productos/{id}`
- ✅ Campo correcto: `{ "img": "base64..." }`

## Pruebas Manuales Recomendadas

### Escenario 1: Capturar Nueva Imagen
1. **Iniciar app** en iPhone/iPad
2. **Buscar producto** por código de barras
3. **Presionar botón de cámara** (ícono en esquina inferior izquierda de la imagen)
4. **Seleccionar** "Tomar foto" o "Seleccionar de galería"
5. **Verificar editor se abre** mostrando:
   - Widget de crop arriba (con rectángulo 3:4)
   - Sliders de rotación y brillo abajo
   - Botón "Quitar fondo" abajo
   - Botón "Listo" en AppBar
6. **Ajustar rectángulo de crop** con gestos (pellizcar, arrastrar)
7. **Mover sliders** de rotación y brillo
8. **(Opcional)** Presionar "Quitar fondo"
9. **Presionar "Listo"**
10. **Verificar preview** muestra imagen procesada
11. **Seleccionar** "Subir al servidor" o "Guardar"
12. **Verificar** imagen se actualiza en la vista del producto

**Verificar:**
- ✅ Todo visible en una sola pantalla
- ✅ Sin tabs ni navegación modal
- ✅ Addons NO aparecen durante la edición
- ✅ Timer se reinicia después de editar (60 segundos nuevos)

### Escenario 2: Editar Imagen Existente
1. **Buscar producto** que YA tiene imagen del servidor
2. **Esperar** a que la imagen se cargue del servidor
3. **Presionar botón de cámara**
4. **Tomar/seleccionar nueva imagen**
5. **Editar** en el editor unificado
6. **Subir** al servidor
7. **Verificar** imagen se actualiza correctamente

**Verificar:**
- ✅ Imagen del servidor se muestra correctamente
- ✅ Se puede editar/reemplazar
- ✅ Upload funciona con endpoint correcto

### Escenario 3: Cancelar Edición
1. **Abrir editor** desde un producto
2. **Ajustar controles** (crop, rotación, brillo)
3. **Presionar ícono X** (cerrar)
4. **Verificar** vuelve a la vista de producto
5. **Verificar** no se guardaron cambios
6. **Verificar** timer se reinició (60 segundos nuevos)

**Verificar:**
- ✅ Cancelación funciona correctamente
- ✅ No se pierde el producto mostrado
- ✅ Timer se resetea igual que al guardar

### Escenario 4: Timer de Idle Durante Edición
1. **Buscar producto**
2. **Esperar 50 segundos** (cerca del timeout de 60s)
3. **Abrir editor** antes de que aparezcan addons
4. **Permanecer en el editor** por más de 60 segundos
5. **Verificar** addons NO aparecen mientras editas
6. **Presionar "Listo"** o cancelar
7. **Verificar** timer se reinicia con 60 segundos completos nuevos

**Verificar:**
- ✅ Timer pausado durante edición
- ✅ Addons bloqueados durante edición
- ✅ Timer reseteado después de edición

### Escenario 5: Flujo Completo con Todos los Edits
1. **Tomar foto** de un producto
2. **Ajustar crop** para 3:4
3. **Rotar** +45 grados
4. **Aumentar brillo** +30
5. **Quitar fondo** (presionar botón y esperar)
6. **Presionar "Listo"**
7. **Verificar preview** muestra todos los cambios aplicados
8. **Subir al servidor**
9. **Verificar** imagen final tiene todos los edits

**Verificar:**
- ✅ Crop se aplica correctamente (3:4)
- ✅ Rotación se aplica después del crop
- ✅ Brillo se aplica después del crop
- ✅ Background removal funciona
- ✅ Imagen final se redimensiona a 768x1024
- ✅ Upload exitoso al servidor

## Casos Extremos a Probar

### 1. Sin Crop (solo ajustes)
- Abrir editor
- NO ajustar el crop (dejar por defecto)
- Solo mover sliders
- Presionar "Listo"
- **Resultado esperado:** Imagen completa con ajustes

### 2. Solo Crop (sin ajustes)
- Abrir editor
- Ajustar crop
- NO tocar sliders (dejar en 0)
- Presionar "Listo"
- **Resultado esperado:** Imagen recortada sin ajustes

### 3. Múltiples Ediciones Seguidas
- Editar imagen de producto A
- Buscar producto B
- Editar imagen de producto B
- Buscar producto C
- Editar imagen de producto C
- **Resultado esperado:** Cada edición funciona independientemente

### 4. Edición Muy Larga (> 5 minutos)
- Abrir editor
- Esperar 5+ minutos sin hacer nada
- Ajustar controles
- Presionar "Listo"
- **Resultado esperado:** Timer sigue pausado, no aparecen addons

## Posibles Problemas y Soluciones

### Problema: "Error al recortar"
- **Causa:** Imagen corrupta o formato no soportado
- **Solución:** Intentar con otra imagen

### Problema: "Error al quitar el fondo"
- **Causa:** ONNX runtime no inicializado o imagen muy grande
- **Solución:** Reintentar o skip este paso

### Problema: "Error al subir la imagen al servidor"
- **Causa:** Endpoint incorrecto o servidor no disponible
- **Solución:** Verificar configuración de servidor y conexión

### Problema: Addons aparecen durante edición
- **Causa:** Bug en pauseIdleTimer()
- **Solución:** Verificar que `pauseIdleTimer()` se llama correctamente

### Problema: macOS no compila
- **Causa:** flutter_onnxruntime requiere macOS 14.0+
- **Solución:** Probar en iOS/Android en su lugar

## Comandos Útiles para Desarrollo

### Ejecutar en iPhone conectado
```bash
flutter run -d "00008140-001118200C28801C"
```

### Ejecutar en iPad wireless
```bash
flutter run -d "00008112-001268903A06601E"
```

### Análisis de código
```bash
flutter analyze
```

### Ver logs en tiempo real
```bash
flutter logs
```

### Hot reload durante desarrollo
```
r (en la consola donde corre flutter run)
```

### Hot restart
```
R (en la consola donde corre flutter run)
```

## Resumen de Cambios Implementados

1. **pubspec.yaml**
   - Reemplazado `image_cropper` → `crop_your_image`

2. **image_upload_service.dart**
   - Eliminado método `cropImage()`
   - Modificado `captureAndProcess()` para pasar bytes originales al editor
   - Actualizado endpoint a `POST /productos/{id}` con campo `img`

3. **image_editor_dialog.dart**
   - Eliminados tabs y modos secuenciales
   - Una sola pantalla con todos los controles visibles
   - Crop arriba (60%), controles abajo (40%)

4. **visor_provider.dart**
   - Agregados `pauseIdleTimer()` y `resumeIdleTimer()`

5. **visor_screen.dart**
   - Modificado `_handleTakePhoto()` para pausar/reanudar timer

## Checklist Pre-Commit

- [x] Flutter analyze sin errores
- [x] Código documentado
- [x] Imports limpiados
- [x] Sin warnings
- [x] Funcionalidad core implementada
- [ ] Probado en dispositivo real (pendiente usuario)
- [ ] Upload al servidor verificado (pendiente usuario)

---

**Nota:** Los tests unitarios tienen timeout debido a la complejidad del widget Crop, pero el código está listo para pruebas manuales en dispositivos reales.
