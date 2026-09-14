// ignore_for_file: unnecessary_getters_setters

import 'package:baul_pandora/backend/schema/util/schema_util.dart';

import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';

class ShippingOptionsStruct extends BaseStruct {
  ShippingOptionsStruct({
    String? shippingName,
    String? description,
    double? price,
  })  : _shippingName = shippingName,
        _description = description,
        _price = price;

  // "shippingName" field.
  String? _shippingName;
  String get shippingName => _shippingName ?? '';
  set shippingName(String? val) => _shippingName = val;

  bool hasShippingName() => _shippingName != null;

  // "description" field.
  String? _description;
  String get description => _description ?? '';
  set description(String? val) => _description = val;

  bool hasDescription() => _description != null;

  // "price" field.
  double? _price;
  double get price => _price ?? 0.0;
  set price(double? val) => _price = val;

  void incrementPrice(double amount) => price = price + amount;

  bool hasPrice() => _price != null;

  static ShippingOptionsStruct fromMap(Map<String, dynamic> data) =>
      ShippingOptionsStruct(
        shippingName: data['shippingName'] as String?,
        description: data['description'] as String?,
        price: castToType<double>(data['price']),
      );

  static ShippingOptionsStruct? maybeFromMap(dynamic data) => data is Map
      ? ShippingOptionsStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'shippingName': _shippingName,
        'description': _description,
        'price': _price,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'shippingName': serializeParam(
          _shippingName,
          ParamType.String,
        ),
        'description': serializeParam(
          _description,
          ParamType.String,
        ),
        'price': serializeParam(
          _price,
          ParamType.double,
        ),
      }.withoutNulls;

  static ShippingOptionsStruct fromSerializableMap(Map<String, dynamic> data) =>
      ShippingOptionsStruct(
        shippingName: deserializeParam(
          data['shippingName'],
          ParamType.String,
          false,
        ),
        description: deserializeParam(
          data['description'],
          ParamType.String,
          false,
        ),
        price: deserializeParam(
          data['price'],
          ParamType.double,
          false,
        ),
      );

  @override
  String toString() => 'ShippingOptionsStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is ShippingOptionsStruct &&
        shippingName == other.shippingName &&
        description == other.description &&
        price == other.price;
  }

  @override
  int get hashCode =>
      const ListEquality().hash([shippingName, description, price]);
}

ShippingOptionsStruct createShippingOptionsStruct({
  String? shippingName,
  String? description,
  double? price,
}) =>
    ShippingOptionsStruct(
      shippingName: shippingName,
      description: description,
      price: price,
    );
