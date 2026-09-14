Backend: Supabase.

E-commerce: Sincronización con WooCommerce vía API.

Estructura de Pago:
- El esquema de pago se define en `lib/backend/schema/structs/pago_struct.dart`.
- Campos actuales:
  - `nombre`
  - `email`
  - `tipo`
  - `referencia`
  - `numeroTelefono`
  - `bancoEnviado`
  - `bancoRecibido`
- El struct ofrece `toMap()`, `toSerializableMap()` y `fromMap()`/`fromSerializableMap()` para serializar/deserializar con FlutterFlow.

Conexión Supabase:
- La inicialización está en `lib/backend/supabase/supabase.dart`.
- Usa `supabase_flutter` y `Supabase.initialize(...)` con `authFlowType: AuthFlowType.implicit`.
- La URL es `https://kpmqmqeerzibjpkktvxt.supabase.co` y el anon key está embebido en el proyecto.
- El wrapper `SupaFlow` centraliza el cliente Supabase y expone `SupaFlow.client`, que es un alias para `Supabase.instance.client`.
- Ese archivo también exporta `lib/backend/supabase/database/database.dart` y `lib/backend/supabase/storage/storage.dart`.

Pedidos y datos de pago:
- El modelo de pedidos mapeado a Supabase está en `lib/backend/supabase/database/tables/pedidos.dart`.
- La tabla `pedidos` incluye un campo `datos_pago` de tipo dinámico (`dynamic?`) para almacenar la información de pago asociada.
- `datos_pago` no se enlaza automáticamente a `PagoStruct` en el row; requiere parseo/manual mapping desde/sobre el payload dinámico.
- También existe el campo `status`, `total_price`, `user_id`, `id_woo`, `shipping_address`, entre otros.

Esquemas de Datos:
- Además de `PagoStruct`, el proyecto usa tablas generadas de Supabase en `lib/backend/supabase/database/tables/`.
- La sincronización con WooCommerce usa DTOs y convierte los datos a mapas compatibles con Supabase antes de hacer upserts.

Reglas de Importación:
- Revisa los imports de Supabase: la mayoría de la lógica usa `package:baul_pandora/backend/supabase/supabase.dart` para mantener un punto central.
- Los servicios como `FavoritesService` usan `Supabase.instance.client.auth.currentUser` directamente para detectar el usuario autenticado.

Reglas de Compilación:
- Evitar conflictos de `Padding` entre Flutter y componentes:
  - El error típico es `Padding is imported from both 'package:baul_pandora/components/top_nav/top_nav_widget.dart' and 'package:flutter/src/widgets/basic.dart'.`
  - Para archivos que importan widgets de `components` y también Flutter material/widgets, use `hide Padding` en uno de los imports.
  - Ejemplo seguro:
    - `import 'package:flutter/material.dart' hide Padding;`
    - `import 'package:baul_pandora/components/top_nav/top_nav_widget.dart';`
    - `import 'package:baul_pandora/components/top_nav/top_nav_widget.dart' hide Padding;`
    - `import 'package:flutter/material.dart';`
- Validar `InvalidType` en compilación Web:
  - El error aparece como `Unsupported invalid type InvalidType(<invalid>)` y suele estar relacionado con `const` widgets que contienen callbacks/closures o funciones dinámicas no constantes.
  - En este proyecto ya se detectó en `lib/pages/product_edit/product_edit_widget.dart` durante compilación.
  - Reglas específicas:
    - No uses `const` en widgets que contienen `builder:`, `onPressed: () async {}`, `onTap`, o callbacks con runtime state.
    - Asegurate de que los tipos de funciones sean correctos para las propiedades `builder`, `onTap` y similares.
    - Si ves `Constant expression expected` o `Not a constant expression` en el log, retira el `const` y recompila.
- Siempre verifica la sintaxis de Dart y resuelve ambigüedades de imports antes de proponer cambios.

Decisiones de Arquitectura:
- Se eligió Supabase en lugar de Firebase para mantener la sincronización directa con la base de datos PostgreSQL y aprovechar los generadores de tablas/objetos en Dart.
- Supabase también permite usar `supabase_flutter` con auth integrado y storage helpers, lo cual encaja con el backend de WooCommerce sincronizado.

Historial de Errores Críticos:
- Ya hay un cambio documentado para la Web: `fix-supabase-auth-fetch-error` eliminó el header `X-Client-Info` de la inicialización de Supabase porque causaba CORS/`ClientException` en auth.
- Ese bug está resuelto en `lib/backend/supabase/supabase.dart` y en el manejo de auth en `lib/auth/supabase_auth/supabase_auth_manager.dart`.

Manejo del Carrito:
- Implementación centralizada en `CartService` (`lib/services/cart_service.dart`) para evitar lógica dispersa en widgets.
- Fuente de Verdad para Auth: Se utiliza `SupaFlow.client.auth.currentUser` en lugar de flags locales (`invitado`) para decidir si las operaciones deben persistirse en Supabase o solo localmente. Esto evita inconsistencias de estado durante el login/logout.
- Sincronización Bidireccional:
  - Upstream: `syncGuestCartToRemote()` fusiona los items del carrito local (invitado) en un pedido de Supabase inmediatamente después del login exitoso.
  - Downstream: `fetchRemoteCart()` recupera el estado del carrito desde Supabase y actualiza `FFAppState` al iniciar la app o tras el login. Esto asegura que el usuario recupere sus productos en cualquier dispositivo.
- Estado unificado en `FFAppState`: Se eliminó `itemsCarritoActual` (List<String>) en favor de `itemsCarrito` (List<CarritoStruct>) para evitar redundancia y errores de tipo.
- Flujo de Datos: Widget -> CartService -> (FFAppState + Supabase).
- Fix "Pantalla Roja" en `FullCartViewWidget`: Se eliminaron todas las fuerzas de no-nulo (`!`) en las llamadas a `priceSummary` y en el acceso a precios de productos. Ahora se utilizan operadores de coalescencia nula (`?? 0.0`), evitando el crash "Unexpected null value" cuando el carrito se vacía.

Guest vs Usuario Autenticado:
- Ingreso como invitado:
  - No crea una sesión de Supabase autenticada.
  - El modo invitado se gestiona con `FFAppState().invitado = true` y se persiste en SharedPreferences bajo `ff_invitado`.
  - El carrito, favoritos y direcciones se mantienen en el estado local del app y no se sincronizan automáticamente con Supabase.
  - Las acciones de carrito en modo invitado solo actualizan el estado local; por ejemplo, `PedidoItemsTable().delete(...)` solo se ejecuta cuando no hay invitado.
  - La comprobación `FFAppState().invitado != null` era incorrecta: `invitado` es un `bool`. Se corrigió a la única condición válida sobre `shippingOption`.
  - `authManager.signInAnonymously(context)` se agregó como punto de extensión para un flujo de invitado unificado.
- Ingreso como usuario con cuenta:
  - Usa `authManager.signInWithEmail` o `createAccountWithEmail` y actualiza la app con `AppStateNotifier.instance.update(authUser)`.
  - El usuario queda autenticado en Supabase (`loggedIn == true`) y la navegación protegida depende de ese estado.
  - Tras el login se sincronizan favoritos con `FavoritesService.instance.syncFavorites()` y el carrito con `CartService.instance.syncGuestCartToRemote()`.
  - Datos de dirección y pedidos de usuario autenticado se persisten en Supabase, mientras que el modo invitado se mantiene local.
  - Al hacer sign out, el modo invitado se limpia para evitar que el usuario quede inadvertidamente en modo invitado después de cerrar sesión.

---
## Checkout Page Improvements (Addresses) - [2026-04-25]

### 1. Numeración de Direcciones
- **Problema**: Se utilizaba `stepNumber` para controlar tanto el flujo de la página como la numeración de las direcciones, causando saltos en el flujo y numeración incorrecta (empezaba en #2).
- **Solución**: Se implementó `addressCounter` en `CheckoutFullPageModel`. 
- **Resultado**: Las direcciones se numeran independientemente del paso de la página, comenzando correctamente desde "Dirección #1".

### 2. Gestión de Dirección Predeterminada (Default Address)
- **Lógica de Creación**: Se agregó validación para que, al crear la primera dirección (`_model.direccionesGuardadas.isEmpty`), se asigne automáticamente `defaultAddress = true`.
- **UI Indicator**: Se eliminó el estado de selección temporal. Ahora el contenedor verde y el icono de check dependen exclusivamente de la propiedad `defaultAddress` del `AddressStruct`.
- **Exclusividad Mutua**: Se implementó lógica en el `onTap` de la lista de direcciones para que, al seleccionar una nueva, todas las demás se marquen como `defaultAddress = false` y solo la seleccionada sea `true`.

### 3. Corrección del Modal de Agregar Dirección
- **Flujo de Datos**: Se corrigió un bug crítico donde el modal intentaba leer controladores de texto de la página principal en lugar de usar los suyos propios. Ahora el modal construye el `AddressStruct` y lo pasa al callback `guardar`.
- **Persistencia**: Se corrigió la actualización en Supabase. Anteriormente se guardaba un único objeto; ahora se envía la lista completa de direcciones (`_model.direccionesGuardadas`) convertida a JSON mediante `functions.addressToJSON`.
- **UX**: Se aseguró el cierre del diálogo mediante `Navigator.pop(context)` inmediatamente después de procesar la acción de guardado.

### Archivos Afectados:
- `lib/pages/checkout_full_page/checkout_full_page_model.dart`
- `lib/pages/checkout_full_page/checkout_full_page_widget.dart`
- `lib/dropdowns/modal_add_address/modal_add_address_widget.dart`

---
## Plan de Reconstrucción Checkout 2.0 (Multi-Step Wizard) - [2026-05-06]

Objetivo: Transformar el checkout de una sola página en un flujo guiado para mejorar la UX y la conversión.

Pasos del Plan:
1. **CheckoutProgressBar**: Crear indicador visual de progreso (Completado).
2. **Conditional Rendering**: Implementar `_buildStepContent()` para renderizar secciones basadas en `stepNumber` (Completado).
3. **Navegación**: Agregar botones "Siguiente" y "Atrás" en cada paso (Completado).
4. **Validation Guards**: Integrar validaciones (`isValid...`) para bloquear la navegación si los datos están incompletos (Completado).
4.5 **Organización Visual y Refactor de Navegación**:
   - 4.5.1: Eliminar `Expandable` de `CheckoutAddressSection` y dejar solo el contenido directo (Pendiente).
   - 4.5.2: Quitar todos los cambios manuales a la variable `stepNumber` en los componentes para centralizar navegación (Pendiente).
   - 4.5.3: Eliminar `Expandable` de `CheckoutPaymentSection` y dejar solo el contenido directo (Pendiente).
   - 4.5.4: Optimizar la disposición de elementos para eliminar ruido visual en cada paso (Pendiente).
5. **CheckoutFooterAction**: Mover el botón de compra final únicamente al último paso (Completado).
6. **Responsividad**: Auditoría final de layout para Mobile/Desktop usando `Row`/`Wrap` (Pendiente).

Regla de Oro: No realizar cambios manuales a la variable `stepNumber` dentro de los componentes; la navegación debe ser manejada centralmente por el widget padre.

---
## Plan de Sistema de Carga de Inventario - [2026-05-11]

Objetivo: Crear un flujo optimizado para actualizar el stock de productos, permitiendo la carga masiva y la auditoría de movimientos.

### 1. Flujo de Usuario (UX)
- **Selector de Búsqueda**: Modal inicial con opciones de búsqueda por Nombre/Código, Foto (IA) y Escáner de Código de Barras.
- **Carga de Cantidad**: Una vez seleccionado el producto, ingresar la cantidad a agregar/restar.
- **Lista de Cola (Batch List)**: Los productos se añaden a una lista temporal dentro del modal para revisión antes del guardado final.
- **Confirmación**: Guardado masivo de todos los cambios acumulados en la lista.

### 2. Mejoras Técnicas
- **Auditoría (`inventory_logs`)**: Implementación de una tabla de logs en Supabase para registrar cada movimiento (producto, cantidad, tipo de operación, usuario y fecha).
- **Suma Atómica**: Uso de incrementos directos en la base de datos para evitar conflictos de concurrencia.
- **Soporte de Salidas**: Permitir el registro de bajas de stock (roturas, pérdidas) en el mismo flujo.

### 3. Fases de Implementación
- **Fase 1**: Creación de la tabla `inventory_logs` y modelos en Dart.
- **Fase 2**: Desarrollo del `StockUpdateModal` y sistema de búsqueda.
- **Fase 3**: Implementación de la lógica de Batching (lista temporal).
- **Fase 4**: Ejecución del guardado masivo y registro de auditoría.
