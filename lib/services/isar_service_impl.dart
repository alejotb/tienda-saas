import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/isar/local_inventory_models.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class IsarService {
  // Implementación de Singleton: una única instancia para toda la app
  static final IsarService instance = IsarService._internal();
  IsarService._internal();

  Isar? _isar;

  // Getter para acceder a la instancia de Isar desde cualquier lado
  Isar get isar {
    if (_isar == null) {
      throw Exception(
        "Isar no ha sido inicializado. Asegurate de llamar a IsarService.instance.init() en el main.dart",
      );
    }
    return _isar!;
  }

  /// Inicializa la base de datos Isar
  Future<void> init() async {
    if (kIsWeb) {
      print("Isar no soportado en Web");
      return;
    }
    // Si ya está inicializado, no hacemos nada
    if (_isar != null) return;

    try {
      // 1. Obtenemos la ruta de la carpeta de documentos del dispositivo
      final dir = await getApplicationDocumentsDirectory();

      // 2. Abrimos la instancia de Isar pasando las colecciones que definimos
      _isar = await Isar.open(
        [
          LocalProductSchema, 
          LocalStockLogSchema,
        ], 
        directory: dir.path,
      );
      
      print("✅ Isar inicializado correctamente en: ${dir.path}");
    } catch (e) {
      print("❌ Error inicializando Isar: $e");
      rethrow;
    }
  }

  /// Método para cerrar la base de datos (útil en tests o cierre de sesión)
  Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}