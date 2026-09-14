import '../database.dart';

class PedidosTable extends SupabaseTable<PedidosRow> {
  @override
  String get tableName => 'pedidos';

  @override
  PedidosRow createRow(Map<String, dynamic> data) => PedidosRow(data);
}

class PedidosRow extends SupabaseDataRow {
  PedidosRow(super.data);

  @override
  SupabaseTable get table => PedidosTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  double? get totalPrice => getField<double>('total_price');
  set totalPrice(double? value) => setField<double>('total_price', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  int? get idWoo => getField<int>('id_woo');
  set idWoo(int? value) => setField<int>('id_woo', value);

  String? get nombreCliente => getField<String>('nombre_cliente');
  set nombreCliente(String? value) => setField<String>('nombre_cliente', value);

  String? get emailCliente => getField<String>('email_cliente');
  set emailCliente(String? value) => setField<String>('email_cliente', value);

  double? get total => getField<double>('total');
  set total(double? value) => setField<double>('total', value);

  String? get estado => getField<String>('estado');
  set estado(String? value) => setField<String>('estado', value);

  String? get fechaCreacion => getField<String>('fecha_creacion');
  set fechaCreacion(String? value) => setField<String>('fecha_creacion', value);

  String? get pedidoNombre => getField<String>('pedido_nombre');
  set pedidoNombre(String? value) => setField<String>('pedido_nombre', value);

  DateTime? get fechaExpiracion => getField<DateTime>('fecha_expiracion');
  set fechaExpiracion(DateTime? value) => setField<DateTime>('fecha_expiracion', value);

  double? get tax => getField<double>('tax');
  set tax(double? value) => setField<double>('tax', value);

  dynamic get shippingAddress => getField<dynamic>('shipping_address');
  set shippingAddress(dynamic value) =>
      setField<dynamic>('shipping_address', value);

  dynamic get datosPago => getField<dynamic>('datos_pago');
  set datosPago(dynamic value) => setField<dynamic>('datos_pago', value);
}
