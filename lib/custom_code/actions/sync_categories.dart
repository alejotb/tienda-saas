// Automatic FlutterFlow imports
import 'package:baul_pandora/backend/supabase/supabase.dart';
// Imports other custom actions
// Imports custom functions
import 'sync_dtos.dart'; // Import the DTOs
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

Future syncCategories(List<dynamic>? wooCategoriesJson) async {
  if (wooCategoriesJson == null || wooCategoriesJson.isEmpty) {
    print("No hay categorías para sincronizar.");
    return;
  }
  
  print('Total de categorías recibidas de Woo: ${wooCategoriesJson.length}');
  final List<int> idsRecibidos = wooCategoriesJson.map((c) => c['id'] as int).toList();
  final Set<int> idsUnicos = idsRecibidos.toSet();
  print('IDs únicos recibidos: ${idsUnicos.length}');
  if (idsRecibidos.length != idsUnicos.length) {
    print('¡AVISO! Se detectaron duplicados en la entrada de WooCommerce.');
  }

  final supabase = Supabase.instance.client;

  try {
    // 1. Obtener categorías existentes de Supabase para comparar
    final existingCategories = await supabase
        .from('categorias')
        .select('id, id_woo, nombre, photo_path, parent_id');
    
    final Map<int, Map<String, dynamic>> existingMap = {};
    for (final cat in (existingCategories as List)) {
      if (cat['id_woo'] != null) {
        existingMap[cat['id_woo'] as int] = Map<String, dynamic>.from(cat);
      }
    }

    // 2. Mapear y filtrar categorías de WooCommerce (Deduplicación interna)
    final Map<int, Map<String, dynamic>> uniqueWooCategories = {};
    for (final catJson in wooCategoriesJson) {
      final category = WooCategoryDto.fromJson(catJson as Map<String, dynamic>);
      uniqueWooCategories[category.id] = {
        'id_woo': category.id,
        'nombre': category.name,
        'photo_path': category.image,
        'woo_parent_id': category.parentId, // Guardar temporalmente el ID de Woo
      };
    }

    final List<Map<String, dynamic>> categoriesToUpsert = [];
    
    for (final category in uniqueWooCategories.values) {
      final int idWoo = category['id_woo'] as int;
      final existing = existingMap[idWoo];

      print('Procesando categoría ID: $idWoo, Nombre: ${category['nombre']}');

      final existingPhoto = existing?['photo_path'] as String?;
      final wooPhoto = category['photo_path'] as String?;
      final photoToSave = (wooPhoto != null && wooPhoto.trim().isNotEmpty) ? wooPhoto : existingPhoto;

      // Comprobar si existe y si ha cambiado algo de los datos básicos
      bool necesitaActualizar = existing == null ||
          existing['nombre'] != category['nombre'] ||
          existing['photo_path'] != photoToSave;
          
      if (necesitaActualizar) {
        categoriesToUpsert.add({
          'id_woo': category['id_woo'],
          'nombre': category['nombre'],
          'photo_path': photoToSave,
        });
      }
    }

    // PASO 1: Upsert de información básica (sin parent_id para no causar problemas si el padre no existe aún)
    if (categoriesToUpsert.isNotEmpty) {
      const int batchSize = 100;
      for (var i = 0; i < categoriesToUpsert.length; i += batchSize) {
        final end = (i + batchSize < categoriesToUpsert.length) 
            ? i + batchSize 
            : categoriesToUpsert.length;
        
        final batch = categoriesToUpsert.sublist(i, end);
        await supabase.from('categorias').upsert(batch, onConflict: 'id_woo');
        print("Procesado lote básico de categorías: ${i + 1} a $end");
      }
    } else {
      print("Los datos básicos de categorías ya están actualizados.");
    }

    // PASO 2: Resolver parent_id nativos (UUIDs de Supabase)
    // Refrescar las categorías para tener los UUIDs de las que acabamos de insertar
    final allCategories = await supabase.from('categorias').select('id, id_woo, parent_id');
    final Map<int, String> wooToNativeId = {};
    final Map<int, String?> currentNativeParents = {};
    
    for (final cat in (allCategories as List)) {
      if (cat['id_woo'] != null) {
        wooToNativeId[cat['id_woo'] as int] = cat['id'].toString();
        currentNativeParents[cat['id_woo'] as int] = cat['parent_id']?.toString();
      }
    }

    final List<Map<String, dynamic>> parentUpdates = [];
    
    for (final category in uniqueWooCategories.values) {
      final int idWoo = category['id_woo'] as int;
      final int? wooParentId = category['woo_parent_id'] as int?;
      
      String? targetNativeParentId;
      if (wooParentId != null && wooParentId > 0) {
        targetNativeParentId = wooToNativeId[wooParentId];
      }

      final String? currentNativeParentId = currentNativeParents[idWoo];
      
      // Si el parent_id nativo no coincide, lo actualizamos
      if (currentNativeParentId != targetNativeParentId) {
        parentUpdates.add({
          'id_woo': idWoo,
          'parent_id': targetNativeParentId,
        });
      }
    }

    if (parentUpdates.isNotEmpty) {
      const int batchSize = 100;
      for (var i = 0; i < parentUpdates.length; i += batchSize) {
        final end = (i + batchSize < parentUpdates.length) 
            ? i + batchSize 
            : parentUpdates.length;
        
        final batch = parentUpdates.sublist(i, end);
        await supabase.from('categorias').upsert(batch, onConflict: 'id_woo');
        print("Procesado lote de parent_ids: ${i + 1} a $end");
      }
      print("Sincronización de categorías exitosa: ${categoriesToUpsert.length} insertadas/actualizadas, ${parentUpdates.length} relaciones padre-hijo corregidas.");
    } else {
      print("Sincronización de categorías exitosa: todas las relaciones padre-hijo ya estaban correctas.");
    }

  } catch (e) {
    print("ERROR CRÍTICO en syncCategories: $e");
  }
}
