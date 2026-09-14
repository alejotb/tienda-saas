import '../database.dart';

class AgenciasEnvioTable extends SupabaseTable<AgenciasEnvioRow> {
  @override
  String get tableName => 'agencias_envio';

  @override
  AgenciasEnvioRow createRow(Map<String, dynamic> data) => AgenciasEnvioRow(data);
}

class AgenciasEnvioRow extends SupabaseDataRow {
  AgenciasEnvioRow(super.data);

  @override
  SupabaseTable get table => AgenciasEnvioTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String? get empresa => getField<String>('empresa');
  set empresa(String? value) => setField<String>('empresa', value);

  String? get estado => getField<String>('estado');
  set estado(String? value) => setField<String>('estado', value);

  String? get nombreAgencia => getField<String>('nombre_agencia');
  set nombreAgencia(String? value) => setField<String>('nombre_agencia', value);

  String? get codigoAgencia => getField<String>('codigo_agencia');
  set codigoAgencia(String? value) => setField<String>('codigo_agencia', value);

  String? get direccion => getField<String>('direccion');
  set direccion(String? value) => setField<String>('direccion', value);
}
