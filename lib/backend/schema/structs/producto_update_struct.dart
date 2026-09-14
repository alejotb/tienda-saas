// ignore_for_file: unnecessary_getters_setters

import 'package:baul_pandora/backend/schema/util/schema_util.dart';

import 'index.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';

class ProductoUpdateStruct extends BaseStruct {
  ProductoUpdateStruct({
    String? id,
    int? cantidad,
  })  : _id = id,
        _cantidad = cantidad;

  // "id" field.
  String? _id;
  String get id => _id ?? '';
  set id(String? val) => _id = val;

  bool hasId() => _id != null;

  // "cantidad" field.
  int? _cantidad;
  int get cantidad => _cantidad ?? 0;
  set cantidad(int? val) => _cantidad = val;

  void incrementCantidad(int amount) => cantidad = cantidad + amount;

  bool hasCantidad() => _cantidad != null;

  static ProductoUpdateStruct fromMap(Map<String, dynamic> data) =>
      ProductoUpdateStruct(
        id: data['id'] as String?,
        cantidad: castToType<int>(data['cantidad']),
      );

  static ProductoUpdateStruct? maybeFromMap(dynamic data) => data is Map
      ? ProductoUpdateStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'id': _id,
        'cantidad': _cantidad,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'id': serializeParam(
          _id,
          ParamType.String,
        ),
        'cantidad': serializeParam(
          _cantidad,
          ParamType.int,
        ),
      }.withoutNulls;

  static ProductoUpdateStruct fromSerializableMap(Map<String, dynamic> data) =>
      ProductoUpdateStruct(
        id: deserializeParam(
          data['id'],
          ParamType.String,
          false,
        ),
        cantidad: deserializeParam(
          data['cantidad'],
          ParamType.int,
          false,
        ),
      );

  @override
  String toString() => 'ProductoUpdateStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is ProductoUpdateStruct &&
        id == other.id &&
        cantidad == other.cantidad;
  }

  @override
  int get hashCode => const ListEquality().hash([id, cantidad]);
}

ProductoUpdateStruct createProductoUpdateStruct({
  String? id,
  int? cantidad,
}) =>
    ProductoUpdateStruct(
      id: id,
      cantidad: cantidad,
    );
