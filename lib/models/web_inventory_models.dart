import 'i_product.dart';

// Definimos interfaces básicas para los modelos
// Estos nombres deben coincidir con los modelos de Isar para que los repositorios los reconozcan
class LocalProduct implements IProduct {
  final String id;
  final String nombre;
  final int stock;
  final double? precio;
  final List<String>? imagePath;
  
  // Estos son necesarios para que coincidan con la clase de Isar
  String? supabaseId;
  String? name;
  int stockActual;
  double? price;
  DateTime? lastSynced;

  LocalProduct({
    this.id = '',
    this.nombre = '',
    this.stock = 0,
    this.precio,
    this.imagePath,
    this.supabaseId,
    this.name,
    this.stockActual = 0,
    this.price,
    this.lastSynced,
  });
}

class LocalStockLog {
  String? productId;
  String? adminId;
  int delta;
  String? type;
  String? reason;
  DateTime createdAt;
  bool isSynced;

  LocalStockLog({
    this.productId,
    this.adminId,
    this.delta = 0,
    this.type,
    this.reason,
    required this.createdAt,
    this.isSynced = false,
  });
}
