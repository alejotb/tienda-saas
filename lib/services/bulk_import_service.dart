import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';

class ParsedFileData {
  final String fileName;
  final List<String> headers;
  final List<List<dynamic>> rows;
  final int totalRows;

  ParsedFileData({
    required this.fileName,
    required this.headers,
    required this.rows,
    required this.totalRows,
  });
}

class ImportColumnDefinition {
  final String key;
  final String label;
  final bool isRequired;
  final String description;
  final List<String> aliases;

  const ImportColumnDefinition({
    required this.key,
    required this.label,
    required this.isRequired,
    required this.description,
    required this.aliases,
  });
}

class BulkImportResult {
  final bool success;
  final int totalRows;
  final int importedCount;
  final int skippedCount;
  final List<String> errors;
  final bool limitReached;
  final String message;

  BulkImportResult({
    required this.success,
    required this.totalRows,
    required this.importedCount,
    required this.skippedCount,
    this.errors = const [],
    this.limitReached = false,
    required this.message,
  });
}

class BulkImportService {
  static final BulkImportService instance = BulkImportService._internal();
  BulkImportService._internal();

  /// Definición de campos disponibles para mapear en la tienda
  static const List<ImportColumnDefinition> standardColumns = [
    ImportColumnDefinition(
      key: 'nombre',
      label: 'Nombre del Producto',
      isRequired: true,
      description: 'Título o nombre visible para los clientes',
      aliases: [
        'nombre', 'name', 'title', 'producto', 'titulo', 'item',
        'articulo', 'artículo', 'descripcion_corta', 'post_title', 'product_name'
      ],
    ),
    ImportColumnDefinition(
      key: 'precio',
      label: 'Precio Regular / Venta',
      isRequired: true,
      description: 'Precio numérico del producto (ej: 19.99)',
      aliases: [
        'precio', 'price', 'regular_price', 'regular price', '_regular_price',
        'costo', 'pvp', 'monto', 'valor', 'precio_unitario', 'precio_venta',
        'unit_price', 'sale_price', 'precio regular'
      ],
    ),
    ImportColumnDefinition(
      key: 'stock',
      label: 'Cantidad en Stock',
      isRequired: false,
      description: 'Existencias disponibles (ej: 50)',
      aliases: [
        'stock', 'cantidad', 'qty', 'quantity', 'inventario', 'existencia',
        'existencias', 'unidades', 'cant', '_stock', 'inventory'
      ],
    ),
    ImportColumnDefinition(
      key: 'codigo_barras',
      label: 'Código de Barras / SKU',
      isRequired: false,
      description: 'Identificador único o código de barras',
      aliases: [
        'codigo_barras', 'codigo barras', 'barcode', 'codigo', 'código',
        'cod', 'sku', 'upc', 'ean', 'referencia', 'ref', '_sku', 'code'
      ],
    ),
    ImportColumnDefinition(
      key: 'categoria',
      label: 'Categoría',
      isRequired: false,
      description: 'Nombre del rubro o categoría (ej: Ropa, Calzado)',
      aliases: [
        'categoria', 'categoría', 'category', 'departamento', 'rubro',
        'familia', 'seccion', 'sección', 'categories', 'tax:product_cat'
      ],
    ),
    ImportColumnDefinition(
      key: 'descripcion',
      label: 'Descripción Detallada',
      isRequired: false,
      description: 'Detalle de características, especificaciones, etc.',
      aliases: [
        'descripcion', 'descripción', 'description', 'detalle', 'notes',
        'notas', 'especificaciones', 'post_content', 'post_excerpt', 'detalles'
      ],
    ),
    ImportColumnDefinition(
      key: 'image_url',
      label: 'URL de Imagen',
      isRequired: false,
      description: 'Enlace web directo a la foto del producto (https://...)',
      aliases: [
        'imagen', 'image', 'foto', 'photo', 'image_url', 'url_imagen',
        'link_imagen', 'img', 'images', 'featured_image', 'imagen_url', 'pictures'
      ],
    ),
  ];

  /// Parsea un archivo CSV o Excel (.xlsx, .xls) a memoria
  Future<ParsedFileData> parseFile({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final lowerName = fileName.toLowerCase();

    if (lowerName.endsWith('.csv') || lowerName.endsWith('.txt') || lowerName.endsWith('.tsv')) {
      return _parseCsv(bytes, fileName);
    } else if (lowerName.endsWith('.xlsx') || lowerName.endsWith('.xls')) {
      return _parseExcel(bytes, fileName);
    } else {
      throw Exception('Formato de archivo no soportado. Por favor sube un archivo CSV o Excel (.xlsx/.xls).');
    }
  }

  ParsedFileData _parseCsv(Uint8List bytes, String fileName) {
    // Decodificar bytes intentando UTF-8 y luego Latin-1 como fallback
    String content;
    try {
      content = utf8.decode(bytes);
    } catch (_) {
      content = latin1.decode(bytes);
    }

    // Remover BOM si está presente
    if (content.startsWith('\uFEFF')) {
      content = content.substring(1);
    }

    // Auto-detectar delimitador en las primeras líneas
    final firstLine = content.split(RegExp(r'\r\n|\r|\n')).firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
    String delimiter = ',';
    if (firstLine.contains(';') && !firstLine.contains(',')) {
      delimiter = ';';
    } else if (firstLine.contains('\t') && !firstLine.contains(',')) {
      delimiter = '\t';
    } else if (firstLine.split(';').length > firstLine.split(',').length) {
      delimiter = ';';
    }

    final converter = CsvToListConverter(
      fieldDelimiter: delimiter,
      shouldParseNumbers: false,
      allowInvalid: true,
      eol: '\n',
    );

    // Normalizar saltos de línea para CsvToListConverter
    final normalizedContent = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final rawRows = converter.convert(normalizedContent);

    if (rawRows.isEmpty) {
      throw Exception('El archivo CSV está vacío.');
    }

    final headers = rawRows.first.map((e) => e.toString().trim()).toList();
    final dataRows = rawRows.sublist(1).where((r) => r.any((c) => c.toString().trim().isNotEmpty)).toList();

    return ParsedFileData(
      fileName: fileName,
      headers: headers,
      rows: dataRows,
      totalRows: dataRows.length,
    );
  }

  ParsedFileData _parseExcel(Uint8List bytes, String fileName) {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) {
      throw Exception('El archivo Excel no contiene hojas de cálculo con datos.');
    }

    // Buscar la primera hoja que contenga filas
    String? targetTable;
    for (final tableName in excel.tables.keys) {
      final table = excel.tables[tableName];
      if (table != null && table.rows.isNotEmpty) {
        targetTable = tableName;
        break;
      }
    }

    if (targetTable == null) {
      throw Exception('El archivo Excel está vacío o no contiene filas legibles.');
    }

    final sheet = excel.tables[targetTable]!;
    final List<List<dynamic>> allRows = [];

    for (final row in sheet.rows) {
      final List<String> rowValues = [];
      for (final cell in row) {
        if (cell == null || cell.value == null) {
          rowValues.add('');
        } else {
          final v = cell.value;
          if (v is TextCellValue) {
            rowValues.add(v.value.text ?? '');
          } else if (v is IntCellValue) {
            rowValues.add(v.value.toString());
          } else if (v is DoubleCellValue) {
            rowValues.add(v.value.toString());
          } else if (v is DateCellValue) {
            rowValues.add(v.asDateTimeLocal().toIso8601String());
          } else {
            rowValues.add(v.toString());
          }
        }
      }
      if (rowValues.any((c) => c.trim().isNotEmpty)) {
        allRows.add(rowValues);
      }
    }

    if (allRows.isEmpty) {
      throw Exception('La hoja de cálculo no contiene filas válidas.');
    }

    final headers = allRows.first.map((e) => e.toString().trim()).toList();
    final dataRows = allRows.sublist(1);

    return ParsedFileData(
      fileName: fileName,
      headers: headers,
      rows: dataRows,
      totalRows: dataRows.length,
    );
  }

  /// Normaliza texto para comparación inteligente (remueve tildes, símbolos, espacios)
  String _normalize(String input) {
    var result = input.toLowerCase().trim();
    const withAccents = 'áéíóúüñ';
    const withoutAccents = 'aeiouun';
    for (int i = 0; i < withAccents.length; i++) {
      result = result.replaceAll(withAccents[i], withoutAccents[i]);
    }
    result = result.replaceAll(RegExp(r'[^a-z0-9]'), '');
    return result;
  }

  /// Sugiere automáticamente el mapeo de columnas para los campos de la tienda
  Map<String, String?> suggestColumnMapping(List<String> fileHeaders) {
    final Map<String, String?> mapping = {};

    for (final colDef in standardColumns) {
      String? matchedHeader;

      for (final alias in colDef.aliases) {
        final normalizedAlias = _normalize(alias);

        for (final header in fileHeaders) {
          final normalizedHeader = _normalize(header);
          if (normalizedHeader == normalizedAlias ||
              normalizedHeader.contains(normalizedAlias) ||
              normalizedAlias.contains(normalizedHeader)) {
            matchedHeader = header;
            break;
          }
        }
        if (matchedHeader != null) break;
      }

      mapping[colDef.key] = matchedHeader;
    }

    return mapping;
  }

  /// Retorna la plantilla CSV de ejemplo
  String generateSampleCsv() {
    return 'nombre,precio,stock,codigo_barras,categoria,descripcion,image_url\r\n'
        'Camiseta Básica Algodón,19.99,50,SKU-1001,Ropa,"Camiseta 100% algodón suave y transpirable",https://images.unsplash.com/photo-1521572267360-ee0c2909d518\r\n'
        'Pantalón Jean Slim Fit,39.50,30,SKU-1002,Ropa,"Pantalón de mezclilla azul con corte moderno y cómodo",https://images.unsplash.com/photo-1542272604-780c96856592\r\n'
        'Zapatillas Deportivas Urban,59.00,20,SKU-1003,Calzado,"Zapatillas ligeras ideales para uso diario y caminatas",https://images.unsplash.com/photo-1542291026-7eec264c27ff\r\n'
        'Gorra Urbana Ajustable,15.00,45,SKU-1004,Accesorios,"Gorra deportiva con visera curva y broche de ajuste rápido",https://images.unsplash.com/photo-1588850561407-ed78c282e89b\r\n'
        'Mochila Antirrobo Impermeable,45.00,15,SKU-1005,Accesorios,"Mochila con compartimento para laptop de 15.6 pulgadas",https://images.unsplash.com/photo-1553062407-98eeb64c6a62';
  }

  /// Ejecuta la importación masiva verificando límites del plan y guardando en Supabase
  Future<BulkImportResult> executeBulkImport({
    required String storeId,
    required String storePlan,
    required ParsedFileData fileData,
    required Map<String, String?> columnMapping,
    Function(int processed, int total, String status)? onProgress,
  }) async {
    // 1. Validar que al menos 'nombre' y 'precio' estén mapeados
    final nombreHeader = columnMapping['nombre'];
    final precioHeader = columnMapping['precio'];

    if (nombreHeader == null || !fileData.headers.contains(nombreHeader)) {
      return BulkImportResult(
        success: false,
        totalRows: fileData.totalRows,
        importedCount: 0,
        skippedCount: fileData.totalRows,
        message: 'Debes seleccionar la columna que contiene el "Nombre del Producto".',
      );
    }

    // 2. Verificar el límite de productos según el plan (Free = máx 100 productos)
    final isFreePlan = storePlan.toLowerCase() != 'pro' && storePlan.toLowerCase() != 'premium';
    int currentProductCount = 0;

    try {
      final countRes = await SupaFlow.client
          .from('productos')
          .select('id')
          .eq('tienda_id', storeId)
          .eq('es_variacion', false)
          .count(CountOption.exact);
      currentProductCount = countRes.count;
    } catch (e) {
      debugPrint('Error obteniendo conteo de productos de la tienda: $e');
    }

    const int freePlanMax = 100;
    final int availableSlots = isFreePlan ? (freePlanMax - currentProductCount) : 999999;

    if (isFreePlan && availableSlots <= 0) {
      return BulkImportResult(
        success: false,
        totalRows: fileData.totalRows,
        importedCount: 0,
        skippedCount: fileData.totalRows,
        limitReached: true,
        message: 'Has alcanzado el límite máximo de $freePlanMax productos del Plan Free. Actualiza a Pro para importar productos ilimitados.',
      );
    }

    // 3. Obtener índices de cada columna
    final int nameIndex = fileData.headers.indexOf(nombreHeader);
    final int priceIndex = precioHeader != null ? fileData.headers.indexOf(precioHeader) : -1;
    final int stockIndex = columnMapping['stock'] != null ? fileData.headers.indexOf(columnMapping['stock']!) : -1;
    final int barcodeIndex = columnMapping['codigo_barras'] != null ? fileData.headers.indexOf(columnMapping['codigo_barras']!) : -1;
    final int categoryIndex = columnMapping['categoria'] != null ? fileData.headers.indexOf(columnMapping['categoria']!) : -1;
    final int descIndex = columnMapping['descripcion'] != null ? fileData.headers.indexOf(columnMapping['descripcion']!) : -1;
    final int imageIndex = columnMapping['image_url'] != null ? fileData.headers.indexOf(columnMapping['image_url']!) : -1;

    final List<Map<String, dynamic>> recordsToInsert = [];
    final List<String> errorList = [];
    int skipped = 0;
    bool limitHitDuringImport = false;

    for (int i = 0; i < fileData.rows.length; i++) {
      if (isFreePlan && recordsToInsert.length >= availableSlots) {
        limitHitDuringImport = true;
        skipped += (fileData.rows.length - i);
        break;
      }

      final row = fileData.rows[i];
      final rawName = (nameIndex >= 0 && nameIndex < row.length) ? row[nameIndex]?.toString().trim() ?? '' : '';

      if (rawName.isEmpty) {
        skipped++;
        continue;
      }

      // Parsear precio
      double price = 0.0;
      if (priceIndex >= 0 && priceIndex < row.length) {
        final rawPrice = row[priceIndex]?.toString().replaceAll(r'$', '').replaceAll(',', '.').trim() ?? '0';
        price = double.tryParse(rawPrice) ?? 0.0;
      }

      // Parsear stock
      int stock = 0;
      if (stockIndex >= 0 && stockIndex < row.length) {
        final rawStock = row[stockIndex]?.toString().trim() ?? '0';
        stock = int.tryParse(rawStock) ?? 0;
      }

      // Código de barras / SKU
      String? barcode;
      if (barcodeIndex >= 0 && barcodeIndex < row.length) {
        final val = row[barcodeIndex]?.toString().trim() ?? '';
        if (val.isNotEmpty) barcode = val;
      }

      // Categoría
      List<String> categories = [];
      if (categoryIndex >= 0 && categoryIndex < row.length) {
        final val = row[categoryIndex]?.toString().trim() ?? '';
        if (val.isNotEmpty) {
          categories = val.split(RegExp(r'[,|>]')).map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
        }
      }

      // Descripción
      String? desc;
      if (descIndex >= 0 && descIndex < row.length) {
        final val = row[descIndex]?.toString().trim() ?? '';
        if (val.isNotEmpty) desc = val;
      }

      // Imagen
      List<String> images = [];
      if (imageIndex >= 0 && imageIndex < row.length) {
        final val = row[imageIndex]?.toString().trim() ?? '';
        if (val.isNotEmpty) {
          images = val.split(RegExp(r'[,|]')).map((url) => url.trim()).where((url) => url.startsWith('http')).toList();
          if (images.isEmpty && val.startsWith('http')) {
            images = [val];
          }
        }
      }

      recordsToInsert.add({
        'nombre': rawName,
        'precio': price,
        'stock': stock,
        'codigo_barras': barcode,
        'sku': barcode,
        'descripcion': desc,
        'categorias': categories,
        'image_path': images,
        'tienda_id': storeId,
        'es_variacion': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    if (recordsToInsert.isEmpty) {
      return BulkImportResult(
        success: false,
        totalRows: fileData.totalRows,
        importedCount: 0,
        skippedCount: skipped,
        message: 'No se encontraron filas con nombres de producto válidos para importar.',
      );
    }

    // 4. Inserción en lotes de 50 registros a Supabase
    int imported = 0;
    const int batchSize = 50;

    for (int i = 0; i < recordsToInsert.length; i += batchSize) {
      final end = (i + batchSize < recordsToInsert.length) ? i + batchSize : recordsToInsert.length;
      final batch = recordsToInsert.sublist(i, end);

      onProgress?.call(imported, recordsToInsert.length, 'Guardando lote ${((i / batchSize) + 1).toInt()} de ${((recordsToInsert.length / batchSize).ceil())}...');

      try {
        await SupaFlow.client.from('productos').insert(batch);
        imported += batch.length;
      } catch (e) {
        debugPrint('Error insertando lote en Supabase: $e');
        errorList.add('Error en lote ${(i / batchSize) + 1}: $e');
        // Si falla el batch completo, intentamos insertar fila a fila para rescatar las válidas
        for (final item in batch) {
          try {
            await SupaFlow.client.from('productos').insert(item);
            imported++;
          } catch (rowErr) {
            skipped++;
            final itemName = item['nombre'];
            errorList.add('Error en "$itemName": $rowErr');
          }
        }
      }

      onProgress?.call(imported, recordsToInsert.length, 'Importados $imported de ${recordsToInsert.length} productos...');
    }

    final successMsg = limitHitDuringImport
        ? '¡Se importaron $imported productos! Se alcanzó el límite del Plan Free ($freePlanMax productos). Pasa a Pro para añadir más.'
        : '¡Importación completada con éxito! Se añadieron $imported productos a tu catálogo.';

    return BulkImportResult(
      success: imported > 0,
      totalRows: fileData.totalRows,
      importedCount: imported,
      skippedCount: skipped,
      errors: errorList,
      limitReached: limitHitDuringImport,
      message: successMsg,
    );
  }
}
