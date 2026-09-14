import '../database.dart';
import 'package:baul_pandora/models/i_product.dart'; 

class ProductosTable extends SupabaseTable<ProductosRow> {
  @override
  String get tableName => 'productos';

  @override
  ProductosRow createRow(Map<String, dynamic> data) => ProductosRow(data);
}

// 🆕 Agregamos "implements IProduct"
class ProductosRow extends SupabaseDataRow implements IProduct {
  ProductosRow(super.data);

  @override
  SupabaseTable get table => ProductosTable();

  // --- Implementación de IProduct ---
  @override
  String get id => getField<String>('id')!;

  @override
  String get nombre => getField<String>('nombre') ?? 'Sin nombre';

  @override
  int get stock => getField<int>('stock') ?? 0;

  @override
  double? get precio => getField<double>('precio');

  @override
  List<String>? get imagePath => getListField<String>('image_path');
  // ----------------------------------

  set id(String value) => setField<String>('id', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  set nombre(String? value) => setField<String>('nombre', value);

  String? get descripcion => getField<String>('descripcion');
  set descripcion(String? value) => setField<String>('descripcion', value);

  String? get ubicacion => getField<String>('ubicacion');
  set ubicacion(String? value) => setField<String>('ubicacion', value);

  set precio(double? value) => setField<double>('precio', value);

  List<String> get categorias => getListField<String>('categorias');
  set categorias(List<String>? value) =>
      setListField<String>('categorias', value);

  set imagePath(List<String>? value) =>
      setListField<String>('image_path', value);

  set stock(int? value) => setField<int>('stock', value);

  int? get idWoo => getField<int>('id_woo');
  set idWoo(int? value) => setField<int>('id_woo', value);

  int? get stockReservado => getField<int>('stock_reservado');
  set stockReservado(int? value) => setField<int>('stock_reservado', value);

  List<int> get categoriaIdWoo => getListField<int>('categoria_id_woo');
  set categoriaIdWoo(List<int>? value) =>
      setListField<int>('categoria_id_woo', value);

  bool get esVariacion => getField<bool>('es_variacion') ?? false;
  set esVariacion(bool? value) => setField<bool>('es_variacion', value);

  int? get parentIdWoo => getField<int>('parent_id_woo');
  set parentIdWoo(int? value) => setField<int>('parent_id_woo', value);

  String? get parentId => getField<String>('parent_id');
  set parentId(String? value) => setField<String>('parent_id', value);

  dynamic get atributos => getField<dynamic>('atributos');
  set atributos(dynamic value) => setField<dynamic>('atributos', value);

  String? get codigoBarras => getField<String>('codigo_barras');
  set codigoBarras(String? value) => setField<String>('codigo_barras', value);

  String? get sku => getField<String>('sku');
  set sku(String? value) => setField<String>('sku', value);
}
