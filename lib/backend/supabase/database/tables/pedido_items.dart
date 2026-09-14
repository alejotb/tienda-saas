import '../database.dart';

class PedidoItemsTable extends SupabaseTable<PedidoItemsRow> {
  @override
  String get tableName => 'pedido_items';

  @override
  PedidoItemsRow createRow(Map<String, dynamic> data) => PedidoItemsRow(data);
}

class PedidoItemsRow extends SupabaseDataRow {
  PedidoItemsRow(super.data);

  @override
  SupabaseTable get table => PedidoItemsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  String? get pedidoId => getField<String>('pedido_id');
  set pedidoId(String? value) => setField<String>('pedido_id', value);

  String? get productId => getField<String>('product_id');
  set productId(String? value) => setField<String>('product_id', value);

  int? get quantity => getField<int>('quantity');
  set quantity(int? value) => setField<int>('quantity', value);

  double? get priceAtPurchase => getField<double>('price_at_purchase');
  set priceAtPurchase(double? value) =>
      setField<double>('price_at_purchase', value);
}
