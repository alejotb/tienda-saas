import 'dart:math' as math;

import 'package:baul_pandora/backend/schema/structs/index.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';

double? priceSummary(List<double>? prices) {
  // summarize a list of prices from the product list
  if (prices == null || prices.isEmpty) {
    return null;
  }
  return prices.reduce((value, element) => value + element);
}

List<String>? obtenerNombresCategorias(List<CategoriasRow>? filasCategorias) {
  /// Esta función recorre cada fila de la tabla y extrae el campo 'nombre'
  // Si la lista está vacía, devolvemos una lista vacía para evitar errores
  if (filasCategorias == null || filasCategorias.isEmpty) {
    return [];
  }
  // Retornamos solo los nombres mapeando la lista
  return filasCategorias.map((fila) => fila.nombre ?? '').toList();
}

String? obtenerIdPorNombre(
  List<CategoriasRow>? filasCategorias,
  String? nombreSeleccionado,
) {
  /// Esta función busca el nombre seleccionado dentro de la lista de filas
  /// y devuelve el ID (UUID) correspondiente.

  if (filasCategorias == null || nombreSeleccionado == null) {
    return null;
  }

  // Buscamos la fila donde el nombre coincida exactamente
  try {
    final filaEncontrada = filasCategorias.firstWhere(
      (fila) => fila.nombre == nombreSeleccionado,
    );
    return filaEncontrada.id; // Retorna el UUID de esa fila
  } catch (e) {
    return null; // Si no encuentra coincidencia, devuelve nulo
  }
}

String? obtenerIdProductoPorNombre(
  List<ProductosRow>? filasProducto,
  String? nombreSeleccionado,
) {
  /// Esta función busca el nombre seleccionado dentro de la lista de filas
  /// y devuelve el ID (UUID) correspondiente.

  if (filasProducto == null || nombreSeleccionado == null) {
    return null;
  }

  // Buscamos la fila donde el nombre coincida exactamente
  try {
    final filaEncontrada = filasProducto.firstWhere(
      (fila) => fila.nombre == nombreSeleccionado,
    );
    return filaEncontrada.id; // Retorna el UUID de esa fila
  } catch (e) {
    return null; // Si no encuentra coincidencia, devuelve nulo
  }
}

String? obtenerListaCategoria(
  List<CategoriasRow>? filasCategorias,
  List<String>? nombresSeleccionado,
) {
  if (filasCategorias == null || nombresSeleccionado == null) {
    return null;
  }

  var aux;

  for (var nombre in nombresSeleccionado) {
    aux.add(obtenerIdPorNombre(filasCategorias, nombre));
  }

  return aux;
}

dynamic addressToJSON(AddressStruct addressStruct) {
  // Convertimos la estructura de datos a Mapa (JSON) para Supabase
  final addressMap = {
    'defaultAddress': addressStruct.defaultAddress,
    'addressName': addressStruct.addressName,
    'address': addressStruct.address,
    'address_2': addressStruct.address2,
    'city': addressStruct.city,
    'state': addressStruct.state,
    'postalCode': addressStruct.postalCode,
    'tipoDireccion': addressStruct.tipoDireccion,
    'agencia': addressStruct.agencia,
  };

  return addressMap;
}

List<dynamic> addressesToJSONList(List<AddressStruct> addressList) {
  return addressList.map((address) => addressToJSON(address)).toList();
}

List<AddressStruct> jsonToAddressList(List<dynamic> jsonList) {
  if (jsonList.isEmpty) {
    return [];
  }

  final List<AddressStruct> result = [];
  for (var item in jsonList) {
    if (item is! Map) continue;
    final map = Map<String, dynamic>.from(item);
    
    // Normalizar agencia / código
    final String codigoAgencia = (map['agencia'] ?? map['codigoAgencia'] ?? map['codigo_agencia'] ?? '').toString();
    final String tipo = (map['tipoDireccion'] ?? 'casa').toString();
    final String name = (map['addressName'] ?? '').toString().trim();
    final String addr = (map['address'] ?? '').toString().trim();

    final addressObj = AddressStruct.fromMap({
      'defaultAddress': map['defaultAddress'] ?? false,
      'addressName': name,
      'address': addr,
      'address_2': map['address_2'] ?? map['address2'] ?? '',
      'city': map['city'] ?? '',
      'state': map['state'] ?? '',
      'postalCode': map['postalCode'] is num ? (map['postalCode'] as num).toInt() : (int.tryParse(map['postalCode']?.toString() ?? '0') ?? 0),
      'tipoDireccion': tipo,
      'agencia': codigoAgencia,
    });

    // Auto-deduplicación al cargar de la base de datos
    bool isDuplicate = false;
    if (tipo == 'agencia') {
      isDuplicate = result.any((existing) =>
          existing.tipoDireccion == 'agencia' &&
          ((codigoAgencia.isNotEmpty && existing.agencia == codigoAgencia) ||
           (name.isNotEmpty && existing.addressName.toLowerCase() == name.toLowerCase())));
    } else {
      isDuplicate = result.any((existing) =>
          existing.tipoDireccion != 'agencia' &&
          existing.address.toLowerCase() == addr.toLowerCase() &&
          existing.city.toLowerCase() == (map['city'] ?? '').toString().toLowerCase());
    }

    if (!isDuplicate) {
      result.add(addressObj);
    }
  }

  return result;
}

List<String> obtenerIdsPadres(List<CategoriasRow> filasCategorias) {
  /// Filtramos la lista para obtener solo las filas donde parent_id es nulo
  /// y mapeamos para retornar solo el campo ID.
  return filasCategorias
      .where((fila) => (fila.parentId == null || fila.parentId == ''))
      .map((fila) => fila.id)
      .toList();
}

String generateTempID() {
// Generamos un ID basado en el tiempo actual (milisegundos)
  // más un número aleatorio para evitar colisiones si se crean dos al mismo tiempo.
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final randomNum = math.Random().nextInt(10000);

  return 'temp_$timestamp$randomNum';
}

String? generateRealUUID() {
  final random = math.Random();
  const hex = '0123456789abcdef';

  String generateRandomHex(int length) {
    return List.generate(length, (i) => hex[random.nextInt(16)]).join();
  }

  // Formato: 8-4-4-4-12
  return '${generateRandomHex(8)}-${generateRandomHex(4)}-${generateRandomHex(4)}-${generateRandomHex(4)}-${generateRandomHex(12)}';
}

String getProxyUrl(String? originalUrl) {
  const placeholder =
      'https://images.weserv.nl/?url=https://upload.wikimedia.org/wikipedia/commons/1/14/No_Image_Available.jpg&w=300';
  
  // Si la URL es nula o vacía, devolvemos el placeholder para evitar errores de renderizado
  if (originalUrl == null || originalUrl.isEmpty) {
    return placeholder;
  }

  // Devolvemos el enlace directo a la imagen sin intermediarios ni proxies.
  // Esto elimina el riesgo de que un proxy devuelva contenido no decodificable (como HTML de error).
  return originalUrl;
}

List<CarritoStruct>? transformRowsToCarrito(
    List<PedidoItemsRow>? pedidoItemsRows) {
  // 1. Verificación de seguridad
  if (pedidoItemsRows == null || pedidoItemsRows.isEmpty) {
    return [];
  }

  // 2. Creamos la lista donde guardaremos los resultados
  List<CarritoStruct> carritoLocal = [];

  // 3. Iteramos sobre cada 'row'.
  // IMPORTANTE: Aquí 'row' es de tipo PedidoItemsRow, no un Map.
  for (var row in pedidoItemsRows) {
    try {
      // 4. Acceso directo a las propiedades (sin corchetes)
      // Usamos el nombre exacto de la columna en Supabase.
      // Si en la tabla es 'product_id', en el Row de FF será 'productId'.
      final String idProductoRaw = row.productId?.toString() ?? '0';

      // Accedemos a 'cantidad' (o 'quantity' según tu tabla)
      final int cantidadRaw = row.quantity ?? 1;

      // 5. Creamos la instancia del Data Type 'carrito'
      CarritoStruct itemCarrito = CarritoStruct(
        idProducto: idProductoRaw,
        cantidad: cantidadRaw,
      );

      // 6. Añadimos a la lista
      carritoLocal.add(itemCarrito);
    } catch (e) {
      print("Error transformando ítem: $e");
    }
  }

  return carritoLocal;
}

List<CarritoStruct> eliminarProductoDelCarrito(
  List<CarritoStruct> carritoActual,
  String idParaEliminar,
) {
  // 1. Verificamos si la lista tiene datos para evitar errores
  if (carritoActual.isEmpty) {
    return [];
  }

  // 2. Creamos una copia de la lista para no modificar la original directamente
  // (Buena práctica en Flutter para asegurar que la UI se refresque)
  List<CarritoStruct> nuevaLista = List.from(carritoActual);

  // 3. Eliminamos el elemento cuyo idProducto coincida con el que recibimos
  nuevaLista.removeWhere((item) => item.idProducto == idParaEliminar);

  // 4. Devolvemos la lista limpia
  return nuevaLista;
}

PagoStruct transformarJsonAPagoMovil(dynamic datosJson) {
// 1. Verificación de seguridad
  if (datosJson == null || datosJson is! Map) {
    return PagoStruct(
      nombre: '',
      email: '',
      tipo: 'Pago Móvil',
      referencia: '',
      numeroTelefono: '',
      bancoEnviado: '',
      bancoRecibido: '',
    );
  }

  // 2. Mapeo de campos según tu imagen de Data Schema
  return PagoStruct(
    nombre: datosJson['nombre']?.toString() ?? '',
    email: datosJson['email']?.toString() ?? '',
    tipo: datosJson['tipo']?.toString() ?? 'Pago Móvil',
    referencia: datosJson['referencia']?.toString() ?? '',
    numeroTelefono: datosJson['numeroTelefono']?.toString() ?? '',
    bancoEnviado: datosJson['bancoEnviado']?.toString() ?? '',
    bancoRecibido: datosJson['bancoRecibido']?.toString() ?? '',
  );
}

double calculateTotalFromCart(List<CarritoStruct> items, Map<String, double> preciosProductos) {
  return items.fold(0.0, (sum, item) {
    final precio = preciosProductos[item.idProducto] ?? 0.0;
    final cantidad = (item.cantidad as num?)?.toDouble() ?? 0.0;
    return sum + (precio * cantidad);
  });
}

dynamic prepararJsonPago(PagoStruct? datosPago) {
// 1. Verificación de seguridad por si el struct es nulo
  if (datosPago == null) {
    return {}; // Devuelve un JSON vacío
  }

  // 2. Construimos el mapa con las llaves exactas para Supabase.
  return {
    'nombre': datosPago.nombre,
    'email': datosPago.email,
    'tipo': datosPago.tipo,
    'referencia': datosPago.referencia,
    'comprobante_url': datosPago.comprobanteUrl,
    'numeroTelefono': datosPago.numeroTelefono,
    'bancoEnviado': datosPago.bancoEnviado,
    'bancoRecibido': datosPago.bancoRecibido,
    'fecha_registro': DateTime.now().toIso8601String(),
  };
}

