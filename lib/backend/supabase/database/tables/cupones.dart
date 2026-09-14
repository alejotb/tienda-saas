import '../database.dart';

class CuponesTable extends SupabaseTable<CuponesRow> {
  @override
  String get tableName => 'cupones';

  @override
  CuponesRow createRow(Map<String, dynamic> data) => CuponesRow(data);
}

class CuponesRow extends SupabaseDataRow {
  CuponesRow(super.data);

  @override
  SupabaseTable get table => CuponesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get codigo => getField<String>('codigo')!;
  set codigo(String value) => setField<String>('codigo', value);

  double get descuentoPorcentaje => getField<double>('descuento_porcentaje')!;
  set descuentoPorcentaje(double value) => setField<double>('descuento_porcentaje', value);

  DateTime get fechaExpiracion => getField<DateTime>('fecha_expiracion')!;
  set fechaExpiracion(DateTime value) => setField<DateTime>('fecha_expiracion', value);

  int get limiteUsos => getField<int>('limite_usos')!;
  set limiteUsos(int value) => setField<int>('limite_usos', value);

  int get usosActuales => getField<int>('usos_actuales')!;
  set usosActuales(int value) => setField<int>('usos_actuales', value);

  bool get activo => getField<bool>('activo')!;
  set activo(bool value) => setField<bool>('activo', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);
}
