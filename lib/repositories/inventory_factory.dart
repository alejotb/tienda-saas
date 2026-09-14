import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:baul_pandora/repositories/inventory_repository.dart';
import 'isar_inventory_repository_stub.dart'
    if (dart.library.io) 'isar_inventory_repository.dart';
import 'package:baul_pandora/repositories/cloud_inventory_repository.dart';
import 'package:baul_pandora/auth/supabase_auth/auth_util.dart';
import 'package:baul_pandora/backend/supabase/database/tables/usuarios.dart';
import 'package:baul_pandora/app_state.dart';


class InventoryFactory {
  static IInventoryRepository getRepository() {
    final appState = FFAppState();

    // 1. Si es Web, usamos obligatoriamente el repositorio de Nube
    if (kIsWeb) {
      return CloudInventoryRepository();
    }

    // 2. Si el debug forceLocalDB está activo, usamos Isar sin importar el rol
    if (appState.forceLocalDB) {
      return IsarInventoryRepository();
    }

    // 3. Si es Admin, usamos Isar
    if (appState.isAdmin) {
      return IsarInventoryRepository();
    }

    // 4. Por defecto, usamos el repositorio de Nube
    return CloudInventoryRepository();
  }
}