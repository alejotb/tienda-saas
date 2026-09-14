// ignore_for_file: unnecessary_getters_setters

import 'package:baul_pandora/backend/schema/util/schema_util.dart';

import 'index.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';

class AddressStruct extends BaseStruct {
  AddressStruct({
    bool? defaultAddress,
    String? addressName,
    String? address,
    String? address2,
    String? city,
    String? state,
    int? postalCode,
    String? tipoDireccion,
    String? agencia,
  })  : _defaultAddress = defaultAddress,
        _addressName = addressName,
        _address = address,
        _address2 = address2,
        _city = city,
        _state = state,
        _postalCode = postalCode,
        _tipoDireccion = tipoDireccion,
        _agencia = agencia;

  // "defaultAddress" field.
  bool? _defaultAddress;
  bool get defaultAddress => _defaultAddress ?? false;
  set defaultAddress(bool? val) => _defaultAddress = val;

  bool hasDefaultAddress() => _defaultAddress != null;

  // "addressName" field.
  String? _addressName;
  String get addressName => _addressName ?? '';
  set addressName(String? val) => _addressName = val;

  bool hasAddressName() => _addressName != null;

  // "address" field.
  String? _address;
  String get address => _address ?? '';
  set address(String? val) => _address = val;

  bool hasAddress() => _address != null;

  // "address_2" field.
  String? _address2;
  String get address2 => _address2 ?? '';
  set address2(String? val) => _address2 = val;

  bool hasAddress2() => _address2 != null;

  // "city" field.
  String? _city;
  String get city => _city ?? '';
  set city(String? val) => _city = val;

  bool hasCity() => _city != null;

  // "state" field.
  String? _state;
  String get state => _state ?? '';
  set state(String? val) => _state = val;

  bool hasState() => _state != null;

  // "postalCode" field.
  int? _postalCode;
  int get postalCode => _postalCode ?? 0;
  set postalCode(int? val) => _postalCode = val;

  void incrementPostalCode(int amount) => postalCode = postalCode + amount;

  bool hasPostalCode() => _postalCode != null;

  // "tipoDireccion" field.
  String? _tipoDireccion;
  String get tipoDireccion => _tipoDireccion ?? 'casa';
  set tipoDireccion(String? val) => _tipoDireccion = val;

  bool hasTipoDireccion() => _tipoDireccion != null;

  // "agencia" field.
  String? _agencia;
  String get agencia => _agencia ?? '';
  set agencia(String? val) => _agencia = val;

  bool hasAgencia() => _agencia != null;

  static AddressStruct fromMap(Map<String, dynamic> data) => AddressStruct(
        defaultAddress: data['defaultAddress'] as bool?,
        addressName: data['addressName'] as String?,
        address: data['address'] as String?,
        address2: data['address_2'] as String? ?? data['address2'] as String?,
        city: data['city'] as String?,
        state: data['state'] as String?,
        postalCode: castToType<int>(data['postalCode']),
        tipoDireccion: data['tipoDireccion'] as String?,
        agencia: data['agencia'] as String? ?? data['codigoAgencia'] as String? ?? data['codigo_agencia'] as String?,
      );

  static AddressStruct? maybeFromMap(dynamic data) =>
      data is Map ? AddressStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'defaultAddress': _defaultAddress,
        'addressName': _addressName,
        'address': _address,
        'address_2': _address2,
        'city': _city,
        'state': _state,
        'postalCode': _postalCode,
        'tipoDireccion': _tipoDireccion,
        'agencia': _agencia,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'defaultAddress': serializeParam(
          _defaultAddress,
          ParamType.bool,
        ),
        'addressName': serializeParam(
          _addressName,
          ParamType.String,
        ),
        'address': serializeParam(
          _address,
          ParamType.String,
        ),
        'address_2': serializeParam(
          _address2,
          ParamType.String,
        ),
        'city': serializeParam(
          _city,
          ParamType.String,
        ),
        'state': serializeParam(
          _state,
          ParamType.String,
        ),
        'postalCode': serializeParam(
          _postalCode,
          ParamType.int,
        ),
        'tipoDireccion': serializeParam(
          _tipoDireccion,
          ParamType.String,
        ),
        'agencia': serializeParam(
          _agencia,
          ParamType.String,
        ),
      }.withoutNulls;

  static AddressStruct fromSerializableMap(Map<String, dynamic> data) =>
      AddressStruct(
        defaultAddress: deserializeParam(
          data['defaultAddress'],
          ParamType.bool,
          false,
        ),
        addressName: deserializeParam(
          data['addressName'],
          ParamType.String,
          false,
        ),
        address: deserializeParam(
          data['address'],
          ParamType.String,
          false,
        ),
        address2: deserializeParam(
          data['address_2'],
          ParamType.String,
          false,
        ),
        city: deserializeParam(
          data['city'],
          ParamType.String,
          false,
        ),
        state: deserializeParam(
          data['state'],
          ParamType.String,
          false,
        ),
        postalCode: deserializeParam(
          data['postalCode'],
          ParamType.int,
          false,
        ),
        tipoDireccion: deserializeParam(
          data['tipoDireccion'],
          ParamType.String,
          false,
        ),
        agencia: deserializeParam(
          data['agencia'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'AddressStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is AddressStruct &&
        defaultAddress == other.defaultAddress &&
        addressName == other.addressName &&
        address == other.address &&
        address2 == other.address2 &&
        city == other.city &&
        state == other.state &&
        postalCode == other.postalCode &&
        tipoDireccion == other.tipoDireccion &&
        agencia == other.agencia;
  }

  @override
  int get hashCode => const ListEquality().hash([
        defaultAddress,
        addressName,
        address,
        address2,
        city,
        state,
        postalCode,
        tipoDireccion,
        agencia
      ]);
}

AddressStruct createAddressStruct({
  bool? defaultAddress,
  String? addressName,
  String? address,
  String? address2,
  String? city,
  String? state,
  int? postalCode,
  String? tipoDireccion,
  String? agencia,
}) =>
    AddressStruct(
      defaultAddress: defaultAddress,
      addressName: addressName,
      address: address,
      address2: address2,
      city: city,
      state: state,
      postalCode: postalCode,
      tipoDireccion: tipoDireccion,
      agencia: agencia,
    );
