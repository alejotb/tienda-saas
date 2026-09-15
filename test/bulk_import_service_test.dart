import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:baul_pandora/services/bulk_import_service.dart';

void main() {
  group('BulkImportService Tests', () {
    final service = BulkImportService.instance;

    test('parseFile parses comma-separated CSV correctly', () async {
      const csvStr = 'Nombre,Precio,Stock,Codigo\nCamisa Polo,25.50,10,SKU-001\nPantalón Jean,45.00,5,SKU-002';
      final bytes = Uint8List.fromList(utf8.encode(csvStr));

      final result = await service.parseFile(bytes: bytes, fileName: 'productos.csv');

      expect(result.headers, ['Nombre', 'Precio', 'Stock', 'Codigo']);
      expect(result.totalRows, 2);
      expect(result.rows[0][0], 'Camisa Polo');
      expect(result.rows[0][1], '25.50');
      expect(result.rows[1][0], 'Pantalón Jean');
    });

    test('parseFile parses semicolon-separated CSV correctly', () async {
      const csvStr = 'item;precio_unitario;existencias;ref\nZapato Cuero;80.00;12;ZAP-01\nCinturón;15.00;20;CIN-02';
      final bytes = Uint8List.fromList(utf8.encode(csvStr));

      final result = await service.parseFile(bytes: bytes, fileName: 'catalogo.csv');

      expect(result.headers, ['item', 'precio_unitario', 'existencias', 'ref']);
      expect(result.totalRows, 2);
      expect(result.rows[0][0], 'Zapato Cuero');
    });

    test('suggestColumnMapping auto-detects Spanish column headers', () {
      final headers = ['Nombre del Producto', 'Precio de Venta', 'Cantidad en Stock', 'Código de Barras', 'Categoría', 'Descripción'];
      final mapping = service.suggestColumnMapping(headers);

      expect(mapping['nombre'], 'Nombre del Producto');
      expect(mapping['precio'], 'Precio de Venta');
      expect(mapping['stock'], 'Cantidad en Stock');
      expect(mapping['codigo_barras'], 'Código de Barras');
      expect(mapping['categoria'], 'Categoría');
      expect(mapping['descripcion'], 'Descripción');
    });

    test('suggestColumnMapping auto-detects WooCommerce / English column headers', () {
      final headers = ['post_title', 'regular_price', '_stock', 'sku', 'tax:product_cat', 'featured_image'];
      final mapping = service.suggestColumnMapping(headers);

      expect(mapping['nombre'], 'post_title');
      expect(mapping['precio'], 'regular_price');
      expect(mapping['stock'], '_stock');
      expect(mapping['codigo_barras'], 'sku');
      expect(mapping['categoria'], 'tax:product_cat');
      expect(mapping['image_url'], 'featured_image');
    });

    test('generateSampleCsv contains standard headers and non-empty template rows', () {
      final template = service.generateSampleCsv();
      expect(template.contains('nombre'), isTrue);
      expect(template.contains('precio'), isTrue);
      expect(template.contains('stock'), isTrue);
      expect(template.contains('Camiseta Básica Algodón'), isTrue);
    });
  });
}
