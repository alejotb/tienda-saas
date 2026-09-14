// ignore_for_file: unnecessary_getters_setters

import 'package:baul_pandora/backend/schema/util/schema_util.dart';

import 'index.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';

class CarritoStruct extends BaseStruct {
  CarritoStruct({
    String? idProducto,
    int? cantidad,
  })  : _idProducto = idProducto,
        _cantidad = cantidad;

  // "idProducto" field.
  String? _idProducto;
  String get idProducto => _idProducto ?? '';
  set idProducto(String? val) => _idProducto = val;

  bool hasIdProducto() => _idProducto != null;

  // "cantidad" field.
  int? _cantidad;
  int get cantidad => _cantidad ?? 0;
  set cantidad(int? val) => _cantidad = val;

  void incrementCantidad(int amount) => cantidad = cantidad + amount;

  bool hasCantidad() => _cantidad != null;

  static CarritoStruct fromMap(Map<String, dynamic> data) => CarritoStruct(
        idProducto: data['idProducto'] as String?,
        cantidad: castToType<int>(data['cantidad']),
      );

  static CarritoStruct? maybeFromMap(dynamic data) =>
      data is Map ? CarritoStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'idProducto': _idProducto,
        'cantidad': _cantidad,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'idProducto': serializeParam(
          _idProducto,
          ParamType.String,
        ),
        'cantidad': serializeParam(
          _cantidad,
          ParamType.int,
        ),
      }.withoutNulls;

  static CarritoStruct fromSerializableMap(Map<String, dynamic> data) =>
      CarritoStruct(
        idProducto: deserializeParam(
          data['idProducto'],
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
  String toString() => 'CarritoStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is CarritoStruct &&
        idProducto == other.idProducto &&
        cantidad == other.cantidad;
  }

  @override
  int get hashCode => const ListEquality().hash([idProducto, cantidad]);
}

CarritoStruct createCarritoStruct({
  String? idProducto,
  int? cantidad,
}) =>
    CarritoStruct(
      idProducto: idProducto,
      cantidad: cantidad,
    );
