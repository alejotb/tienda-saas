// Automatic FlutterFlow imports
import 'package:baul_pandora/backend/supabase/supabase.dart';
// Imports other custom actions
// Imports custom functions
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

/// DTO para asegurar que la data de WooCommerce sea válida y tipada.
class WooProductDto {
  final int id;
  final String name;
  final double price;
  final int stock;
  final List<String> images;
  final dynamic catIds;
  final String sku;
  final String type; // simple, variable, variation
  final int? parentId;
  final Map<String, dynamic> attributes;

  WooProductDto({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.images,
    required this.catIds,
    required this.sku,
    required this.type,
    this.parentId,
    required this.attributes,
  });

  factory WooProductDto.fromJson(Map<String, dynamic> json) {
    // Extraer los IDs de la lista de objetos de categorías
    final categories = json['categories'] as List?;
    
    final Set<int> allCategoryIds = {};
    if (categories != null) {
      for (var cat in categories) {
        if (cat is Map) {
          final id = cat['id'] as int?;
          final parentId = cat['parent'] as int?;
          
          if (id != null) allCategoryIds.add(id);
          if (parentId != null && parentId != 0) allCategoryIds.add(parentId);
        }
      }
    }
    
    final finalCategoryIds = allCategoryIds.toList();

    // Mapear atributos (Talla, Color, etc.)
    final Map<String, dynamic> mappedAttributes = {};
    final attributesList = json['attributes'] as List?;
    if (attributesList != null) {
      for (var attr in attributesList) {
        if (attr is Map) {
          final attrName = attr['name']?.toString() ?? '';
          final attrOption = attr['option']?.toString() ?? '';
          if (attrName.isNotEmpty && attrOption.isNotEmpty) {
            mappedAttributes[attrName] = attrOption;
          }
        }
      }
    }
    
    return WooProductDto(
      id: json['id'] as int,
      name: json['name']?.toString() ?? 'Sin nombre',
      price: double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0,
      stock: json['stock_quantity'] != null 
          ? (int.tryParse(json['stock_quantity'].toString()) ?? 0) 
          : 0,
      images: () {
        final List<String> imgs = [];
        if (json['images'] != null && json['images'] is List) {
          imgs.addAll((json['images'] as List).map((img) => img['src'] as String));
        }
        if (json['image'] != null && json['image'] is Map) {
          final singleImgUrl = json['image']['src'] as String?;
          if (singleImgUrl != null && singleImgUrl.isNotEmpty && !imgs.contains(singleImgUrl)) {
            imgs.insert(0, singleImgUrl); // Prioritize variation specific image
          }
        }
        return imgs;
      }(),
      catIds: finalCategoryIds,
      sku: json['sku']?.toString() ?? '',
      type: json['type']?.toString() ?? 'simple',
      parentId: (json['parent_id'] != null && json['parent_id'] != 0) 
          ? json['parent_id'] as int 
          : null,
      attributes: mappedAttributes,
    );
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'id_woo': id,
      'nombre': name,
      'precio': price,
      'stock': stock,
      'image_path': images,
      'categoria_id_woo': catIds,
      'sku': sku,
      'parent_id_woo': parentId,
      'es_variacion': type == 'variation',
      'atributos': attributes,
    };
  }
}

Future syncProducts(List<dynamic>? wooProductsJson) async {
  if (wooProductsJson == null || wooProductsJson.isEmpty) {
    print("No hay productos para sincronizar.");
    return;
  }

  final supabase = Supabase.instance.client;

  try {
    // 1. Mapear y filtrar productos de WooCommerce PRIMERO para obtener sus IDs
    final List<Map<String, dynamic>> allProducts = [];
    final Map<int, bool> seenIds = {};
    final List<int> idWooList = [];

    for (final json in wooProductsJson) {
      final productMap = WooProductDto.fromJson(json as Map<String, dynamic>).toSupabaseMap();
      final idWoo = productMap['id_woo'] as int;

      if (seenIds.containsKey(idWoo)) {
        continue; // Saltar duplicados en el mismo JSON
      }
      seenIds[idWoo] = true;
      allProducts.add(productMap);
      idWooList.add(idWoo);
    }

    if (idWooList.isEmpty) return;

    // 2. Obtener SOLAMENTE los productos existentes que coinciden con los de este lote
    // Esto evita el límite de 1000 filas del select() de Supabase.
    final existingProducts = await supabase
        .from('productos')
        .select('id, id_woo, nombre, precio, stock, image_path, categoria_id_woo')
        .inFilter('id_woo', idWooList);
    
    final Map<int, Map<String, dynamic>> existingMap = {};
    for (final prod in (existingProducts as List)) {
      existingMap[prod['id_woo'] as int] = Map<String, dynamic>.from(prod);
    }

    final List<Map<String, dynamic>> productsToInsert = [];
    final List<Map<String, dynamic>> productsToUpdate = [];
    
    for (final product in allProducts) {
      final int idWoo = product['id_woo'] as int;
      final existing = existingMap[idWoo];
      
      // Comprobar si existe y si ha cambiado algo
      bool necesitaActualizar = existing == null ||
          existing['nombre'] != product['nombre'] ||
          existing['precio'] != product['precio'] ||
          existing['stock'] != product['stock'] ||
          '${existing['image_path']}' != '${product['image_path']}' ||
          '${existing['categoria_id_woo']}' != '${product['categoria_id_woo']}';
      
      if (necesitaActualizar) {
        if (existing != null) {
          // Es una actualización, inyectamos el ID primario
          product['id'] = existing['id'];
          productsToUpdate.add(product);
        } else {
          // Es un producto nuevo, NO tiene ID primario
          productsToInsert.add(product);
        }
      }
    }

    if (productsToUpdate.isEmpty && productsToInsert.isEmpty) {
      print("Todos los productos ya están actualizados.");
      return;
    }

    const int batchSize = 50;

    // 3. ACTUALIZAR productos existentes (Update)
    for (var i = 0; i < productsToUpdate.length; i += batchSize) {
      final end = (i + batchSize < productsToUpdate.length) 
          ? i + batchSize 
          : productsToUpdate.length;
      final batch = productsToUpdate.sublist(i, end);
      
      try {
        await supabase.from('productos').upsert(batch);
        print("Actualizado lote de productos: ${i + 1} a $end");
      } catch (e) {
        print("ERROR en Update Batch (${i + 1} a $end): $e");
        print("Muestra del batch (primer elemento): ${batch.first}");
      }
    }

    // 4. INSERTAR productos nuevos (Insert)
    for (var i = 0; i < productsToInsert.length; i += batchSize) {
      final end = (i + batchSize < productsToInsert.length) 
          ? i + batchSize 
          : productsToInsert.length;
      final batch = productsToInsert.sublist(i, end);
      
      try {
        await supabase.from('productos').insert(batch);
        print("Insertado lote de productos nuevos: ${i + 1} a $end");
      } catch (e) {
        print("ERROR en Insert Batch (${i + 1} a $end): $e");
        print("Muestra del batch insert (primer elemento): ${batch.first}");
      }
    }

    final total = productsToUpdate.length + productsToInsert.length;
    print("Sincronización de productos exitosa: $total procesados (${productsToUpdate.length} actualizados, ${productsToInsert.length} nuevos).");
  } catch (e) {
    print("ERROR CRÍTICO en syncProducts: $e");
  }
}
