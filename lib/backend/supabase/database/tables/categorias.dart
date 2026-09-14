import '../database.dart';

class CategoriasTable extends SupabaseTable<CategoriasRow> {
  @override
  String get tableName => 'categorias';

  @override
  CategoriasRow createRow(Map<String, dynamic> data) => CategoriasRow(data);
}

class CategoriasRow extends SupabaseDataRow {
  CategoriasRow(super.data);

  @override
  SupabaseTable get table => CategoriasTable();

  String get id => getField<dynamic>('id').toString();
  set id(String value) => setField<dynamic>('id', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  String? get descripcion => getField<String>('descripcion');
  set descripcion(String? value) => setField<String>('descripcion', value);

  String? get nombre => getField<String>('nombre');
  set nombre(String? value) => setField<String>('nombre', value);

  String? get parentId => getField<dynamic>('parent_id')?.toString();
  set parentId(String? value) => setField<dynamic>('parent_id', value);

  bool? get destacada => getField<bool>('destacada');
  set destacada(bool? value) => setField<bool>('destacada', value);

  String? get photoPath => getField<String>('photo_path');
  set photoPath(String? value) => setField<String>('photo_path', value);

  int? get idWoo => getField<int>('id_woo');
  set idWoo(int? value) => setField<int>('id_woo', value);

  String? get slug => getField<String>('slug');
  set slug(String? value) => setField<String>('slug', value);
}
