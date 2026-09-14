import '../database.dart';

class InventoryLogsTable extends SupabaseTable<InventoryLogsRow> {
  @override
  String get tableName => 'inventory_logs';

  @override
  InventoryLogsRow createRow(Map<String, dynamic> data) => InventoryLogsRow(data);
}

class InventoryLogsRow extends SupabaseDataRow {
  InventoryLogsRow(super.data);

  @override
  SupabaseTable get table => InventoryLogsTable();

  String get id => getField<String>('id') ?? '';
  set id(String value) => setField<String>('id', value);

  String get productoId => getField<String>('producto_id') ?? '';
  set productoId(String value) => setField<String>('producto_id', value);

  String? get usuarioId => getField<String>('usuario_id');
  set usuarioId(String? value) => setField<String>('usuario_id', value);

  int get cantidad => getField<int>('cantidad') ?? 0;
  set cantidad(int value) => setField<int>('cantidad', value);

  String get tipoOperacion => getField<String>('tipo_operacion') ?? 'ajuste';
  set tipoOperacion(String value) => setField<String>('tipo_operacion', value);

  String? get notas => getField<String>('notas');
  set notas(String? value) => setField<String>('notas', value);

  DateTime get createdAt => getField<DateTime>('created_at') ?? DateTime.now();
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);
}
