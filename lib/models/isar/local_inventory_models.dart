import 'package:isar/isar.dart';
import '../i_product.dart';


// ESTA LÍNEA ES VITAL. 
// Isar generará este archivo automáticamente cuando corras el build_runner.
// Al principio verás un error en rojo aquí, ES NORMAL hasta que corras el comando.
part 'local_inventory_models.g.dart';


@collection
class LocalProduct implements IProduct { // 🆕 Implementa IProduct
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String? supabaseId;

  @override
  String get id => supabaseId ?? ''; // Retorna el ID de Supabase

  @override
  String get nombre => name ?? 'Sin nombre';

  @override
  int get stock => stockActual;

  @override
  double? get precio => price;

  @override
  List<String>? get imagePath => []; // Implementar si guardás imágenes locales

  String? name;
  int stockActual = 0;
  double? price;
  DateTime? lastSynced;

  LocalProduct({
    this.supabaseId,
    this.name,
    this.stockActual = 0,
    this.price,
    this.lastSynced,
  });
}

@collection
class LocalStockLog {
  Id id = Isar.autoIncrement; // ID interno de Isar

  @Index()
  String? productId; // ID de Supabase del producto afectado

  @Index()
  String? adminId; // ID de Supabase del administrador que hizo el cambio

  int delta = 0; // Ejemplo: +5 o -2. NUNCA el valor final.
  
  String? type; // 'ENTRADA', 'SALIDA', 'AJUSTE'
  String? reason; // Motivo del cambio
  
  DateTime createdAt = DateTime.now();
  
  // Clave para el sincronizador: false = pendiente, true = ya está en la nube
  bool isSynced = false;

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