# Registro de Decisiones y Cambios Arquitectónicos (Conversación)

Este archivo sirve como guía para cualquier IA o desarrollador que trabaje en el proyecto `baul_pandora`. Las modificaciones realizadas no son caprichos estéticos, sino decisiones arquitectónicas basadas en UX y escalabilidad.

## 1. Flujo de Pagos: De Validación a Asistente de Datos
**Cambio**: Se eliminó la lógica de "comparación" de datos de pago (Semáforo) y se implementó una lógica de "llenado automático".
**Razón**: 
- **Fricción del Usuario**: Obligar al usuario a subir una imagen Y llenar un formulario es redundante y molesto.
- **Flujo**: Ahora, la IA (`AIValidationService`) extrae los datos de la imagen y los escribe directamente en las columnas de la tabla `pagos` (`monto`, `referencia`, `banco_emisor`). 
- **Valor para el Admin**: El administrador ahora ve los datos ya procesados. Si el usuario no subió imagen, el admin ve lo que el usuario escribió. Si subió imagen, ve lo que la IA extrajo.

## 2. Payment Hardening (Sincronización de Saldo)
**Cambio**: El cálculo del saldo pendiente se movió de la UI/Tiempo de ejecución a una columna persistente `saldo_pendiente` en la tabla `pedidos`.
**Razón**:
- **Consistencia**: Evita discrepancias entre lo que ve el usuario y el administrador.
- **Rendimiento**: Consultar un valor numérico es órdenes de magnitud más rápido que sumar items y restar pagos en cada carga de página.
- **Automatización**: Permite que el sistema marque un pedido como `pagado` automáticamente en el momento exacto en que el saldo llega a 0.

## 3. Smart Inventory (Auto-llenado de Productos)
**Cambio**: Implementación de `AIProductService` integrado en la carga de imágenes de productos.
**Razón**:
- **Carga de Inventario**: Crear productos uno a uno es tedioso. Ahora, al subir la foto del producto, la IA analiza la imagen y sugiere:
    - Nombre del producto.
    - Descripción optimizada para venta.
    - Precio estimado.
- **UX**: El administrador solo tiene que revisar y ajustar los datos sugeridos en lugar de escribirlos desde cero.

## 4. UX de Checkout y Apartados
**Cambio**: Inclusión de carga de imágenes obligatoria/opcional en el flujo de pago.
**Razón**:
- Permite al usuario elegir el método más cómodo (foto vs formulario), asegurando que el negocio siempre reciba la prueba de pago necesaria para procesar el pedido.

---
**ADVERTENCIA PARA OTRAS IAs**:
No elimines las llamadas a `syncPendingBalance` ni la integración de `AIProductService` en los `onTap` de carga de imágenes. Estas funciones son el núcleo de la automatización del negocio. Cualquier refactorización debe mantener la escritura de datos extraídos por la IA en las columnas correspondientes de la base de datos.


## 5. Estabilización de Syntax y Modelos
**Cambio**: Se corrigieron cierres de etiquetas (Stack, Align) en product_edit_widget.dart y llamadas faltantes en partado_payment_widget.dart.
**Razón**:
- **Sintaxis Rota**: Al inyectar el código de IA con el Stack y el CircularProgressIndicator en la carga de imágenes, quedaron paréntesis y corchetes sin cerrar, chocando con paréntesis antiguos. Se reparó la estructura del árbol de widgets sin eliminar la funcionalidad de AIProductService.
- **Compilación**: Se actualizaron firmas de constructores (AddPagoWidget), parámetros (ormatType) y tipos genéricos en partado_payment para asegurar que el proyecto completo compile sin errores.
