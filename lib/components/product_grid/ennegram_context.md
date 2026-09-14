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
  - O bien:
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

Guest vs Usuario Autenticado:
- Ingreso como invitado:
  - No crea una sesión de Supabase autenticada.
  - El modo invitado se gestiona con `FFAppState().invitado = true` y se persiste en SharedPreferences bajo `ff_invitado`.
  - El carrito, favoritos y direcciones se mantienen en el estado local del app y no se sincronizan automáticamente con Supabase.
  - Las acciones de carrito en modo invitado solo actualizan el estado local; por ejemplo, `PedidoItemsTable().delete(...)` solo se ejecuta cuando no hay invitado.
  - La comprobación `FFAppState().invitado != null` era incorrecta: `invitado` es un `bool`. Se corrigió a la única condición válida sobre `shippingOption`.
  - El cambio principal fue mover la lógica de acceso de invitado hacia el uso de `loggedIn` para distinguir correctamente entre sesión autenticada y estado local de invitado.
  - En `lib/pages/full_cart_view/full_cart_view_widget.dart` se corrigió `loggedIn` importando `auth_util.dart`, lo que eliminó el error de consola por `loggedIn` no definido.
  - `authManager.signInAnonymously(context)` se agregó como punto de extensión para un flujo de invitado unificado.
  - Esta corrección evita confundir el flag local de invitado con la autenticación Supabase, y permite que las rutas y las operaciones de carrito dependan de `loggedIn` cuando corresponde.
  - Se agregó soporte en `FFAppState` para `itemsCarritoActual` y sus métodos auxiliares (`addToItemsCarritoActual`, `removeFromItemsCarritoActual`, etc.), lo que corrige los errores de compilación en las páginas y componentes del carrito.
  - Se importó `CartService` en `main_home_page_widget.dart` y `checkout_full_page_copy_widget.dart` para resolver el acceso a `CartService.instance`.
- Ingreso como usuario con cuenta:
  - Usa `authManager.signInWithEmail` o `createAccountWithEmail` y actualiza la app con `AppStateNotifier.instance.update(authUser)`.
  - El usuario queda autenticado en Supabase (`loggedIn == true`) y la navegación protegida depende de ese estado.
  - Tras el login se sincronizan favoritos con `FavoritesService.instance.syncFavorites()`.
  - Datos de dirección y pedidos de usuario autenticado se persisten en Supabase, mientras que el modo invitado se mantiene local.
  - Al hacer sign out, el modo invitado se limpia para evitar que el usuario quede inadvertidamente en modo invitado después de cerrar sesión.
