import '../database.dart';

class UsuariosTable extends SupabaseTable<UsuariosRow> {
  @override
  String get tableName => 'usuarios';

  @override
  UsuariosRow createRow(Map<String, dynamic> data) => UsuariosRow(data);
}

class UsuariosRow extends SupabaseDataRow {
  UsuariosRow(super.data);

  @override
  SupabaseTable get table => UsuariosTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  String? get nombre => getField<String>('nombre');
  set nombre(String? value) => setField<String>('nombre', value);

  String? get telefono => getField<String>('telefono');
  set telefono(String? value) => setField<String>('telefono', value);

  String? get email => getField<String>('email');
  set email(String? value) => setField<String>('email', value);

  List<String> get favoriteItems => getListField<String>('favoriteItems');
  set favoriteItems(List<String>? value) =>
      setListField<String>('favoriteItems', value);

  List<dynamic> get datosDireccion => getListField<dynamic>('datos_direccion');
  set datosDireccion(List<dynamic>? value) =>
      setListField<dynamic>('datos_direccion', value);

  String? get photoPath => getField<String>('photo_path');
  set photoPath(String? value) => setField<String>('photo_path', value);

  String? get bio => getField<String>('bio');
  set bio(String? value) => setField<String>('bio', value);

  String? get stateAddress => getField<String>('state_address');
  set stateAddress(String? value) => setField<String>('state_address', value);

  bool get isAdmin => getField<bool>('is_admin') ?? false;
  set isAdmin(bool value) => setField<bool>('is_admin', value);

  int get productosComprados => getField<int>('productos_comprados') ?? 0;
  set productosComprados(int value) => setField<int>('productos_comprados', value);

  int get puntosLealtad => getField<int>('puntos_lealtad') ?? 0;
  set puntosLealtad(int value) => setField<int>('puntos_lealtad', value);
}
