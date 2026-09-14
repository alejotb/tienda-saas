// ignore_for_file: unnecessary_getters_setters

import 'package:baul_pandora/backend/schema/util/schema_util.dart';

import 'index.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';

class PagoStruct extends BaseStruct {
  PagoStruct({
    String? nombre,
    String? email,
    String? tipo,
    String? referencia,
    String? comprobanteUrl,
    String? numeroTelefono,
    String? bancoEnviado,
    String? bancoRecibido,
    double? montoVes,
    double? tasaAplicada,
    double? montoUsd,
  })  : _nombre = nombre,
        _email = email,
        _tipo = tipo,
        _referencia = referencia,
        _comprobanteUrl = comprobanteUrl,
        _numeroTelefono = numeroTelefono,
        _bancoEnviado = bancoEnviado,
        _bancoRecibido = bancoRecibido,
        _montoVes = montoVes,
        _tasaAplicada = tasaAplicada,
        _montoUsd = montoUsd;

  // "nombre" field.
  String? _nombre;
  String get nombre => _nombre ?? '';
  set nombre(String? val) => _nombre = val;

  bool hasNombre() => _nombre != null;

  // "email" field.
  String? _email;
  String get email => _email ?? '';
  set email(String? val) => _email = val;

  bool hasEmail() => _email != null;

  // "tipo" field.
  String? _tipo;
  String get tipo => _tipo ?? '';
  set tipo(String? val) => _tipo = val;

  bool hasTipo() => _tipo != null;

  // "referencia" field.
  String? _referencia;
  String get referencia => _referencia ?? '';
  set referencia(String? val) => _referencia = val;

  bool hasReferencia() => _referencia != null;

  // "comprobanteUrl" field.
  String? _comprobanteUrl;
  String get comprobanteUrl => _comprobanteUrl ?? '';
  set comprobanteUrl(String? val) => _comprobanteUrl = val;

  bool hasComprobanteUrl() => _comprobanteUrl != null;

  // "numeroTelefono" field.
  String? _numeroTelefono;
  String get numeroTelefono => _numeroTelefono ?? '';
  set numeroTelefono(String? val) => _numeroTelefono = val;

  bool hasNumeroTelefono() => _numeroTelefono != null;

  // "bancoEnviado" field.
  String? _bancoEnviado;
  String get bancoEnviado => _bancoEnviado ?? '';
  set bancoEnviado(String? val) => _bancoEnviado = val;

  bool hasBancoEnviado() => _bancoEnviado != null;

  // "bancoRecibido" field.
  String? _bancoRecibido;
  String get bancoRecibido => _bancoRecibido ?? '';
  set bancoRecibido(String? val) => _bancoRecibido = val;

  bool hasBancoRecibido() => _bancoRecibido != null;

  // "montoVes" field.
  double? _montoVes;
  double get montoVes => _montoVes ?? 0.0;
  set montoVes(double? val) => _montoVes = val;

  bool hasMontoVes() => _montoVes != null;

  // "tasaAplicada" field.
  double? _tasaAplicada;
  double get tasaAplicada => _tasaAplicada ?? 0.0;
  set tasaAplicada(double? val) => _tasaAplicada = val;

  bool hasTasaAplicada() => _tasaAplicada != null;

  // "montoUsd" field.
  double? _montoUsd;
  double get montoUsd => _montoUsd ?? 0.0;
  set montoUsd(double? val) => _montoUsd = val;

  bool hasMontoUsd() => _montoUsd != null;

  static PagoStruct fromMap(Map<String, dynamic> data) => PagoStruct(
        nombre: data['nombre'] as String?,
        email: data['email'] as String?,
        tipo: data['tipo'] as String?,
        referencia: data['referencia'] as String?,
        comprobanteUrl: data['comprobanteUrl'] as String? ?? data['comprobante_url'] as String?,
        numeroTelefono: data['numeroTelefono'] as String?,
        bancoEnviado: data['bancoEnviado'] as String?,
        bancoRecibido: data['bancoRecibido'] as String?,
        montoVes: castToType<double>(data['montoVes']),
        tasaAplicada: castToType<double>(data['tasaAplicada']),
        montoUsd: castToType<double>(data['montoUsd']),
      );

  static PagoStruct? maybeFromMap(dynamic data) =>
      data is Map ? PagoStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'nombre': _nombre,
        'email': _email,
        'tipo': _tipo,
        'referencia': _referencia,
        'comprobanteUrl': _comprobanteUrl,
        'numeroTelefono': _numeroTelefono,
        'bancoEnviado': _bancoEnviado,
        'bancoRecibido': _bancoRecibido,
        'montoVes': _montoVes,
        'tasaAplicada': _tasaAplicada,
        'montoUsd': _montoUsd,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'nombre': serializeParam(_nombre, ParamType.String),
        'email': serializeParam(_email, ParamType.String),
        'tipo': serializeParam(_tipo, ParamType.String),
        'referencia': serializeParam(_referencia, ParamType.String),
        'comprobanteUrl': serializeParam(_comprobanteUrl, ParamType.String),
        'numeroTelefono': serializeParam(_numeroTelefono, ParamType.String),
        'bancoEnviado': serializeParam(_bancoEnviado, ParamType.String),
        'bancoRecibido': serializeParam(_bancoRecibido, ParamType.String),
        'montoVes': serializeParam(_montoVes, ParamType.double),
        'tasaAplicada': serializeParam(_tasaAplicada, ParamType.double),
        'montoUsd': serializeParam(_montoUsd, ParamType.double),
      }.withoutNulls;

  static PagoStruct fromSerializableMap(Map<String, dynamic> data) =>
      PagoStruct(
        nombre: deserializeParam(data['nombre'], ParamType.String, false),
        email: deserializeParam(data['email'], ParamType.String, false),
        tipo: deserializeParam(data['tipo'], ParamType.String, false),
        referencia: deserializeParam(data['referencia'], ParamType.String, false),
        comprobanteUrl: deserializeParam(data['comprobanteUrl'], ParamType.String, false),
        numeroTelefono: deserializeParam(data['numeroTelefono'], ParamType.String, false),
        bancoEnviado: deserializeParam(data['bancoEnviado'], ParamType.String, false),
        bancoRecibido: deserializeParam(data['bancoRecibido'], ParamType.String, false),
        montoVes: deserializeParam(data['montoVes'], ParamType.double, false),
        tasaAplicada: deserializeParam(data['tasaAplicada'], ParamType.double, false),
        montoUsd: deserializeParam(data['montoUsd'], ParamType.double, false),
      );

  @override
  String toString() => 'PagoStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is PagoStruct &&
        nombre == other.nombre &&
        email == other.email &&
        tipo == other.tipo &&
        referencia == other.referencia &&
        comprobanteUrl == other.comprobanteUrl &&
        numeroTelefono == other.numeroTelefono &&
        bancoEnviado == other.bancoEnviado &&
        bancoRecibido == other.bancoRecibido &&
        montoVes == other.montoVes &&
        tasaAplicada == other.tasaAplicada &&
        montoUsd == other.montoUsd;
  }

  @override
  int get hashCode => const ListEquality().hash([
        nombre,
        email,
        tipo,
        referencia,
        comprobanteUrl,
        numeroTelefono,
        bancoEnviado,
        bancoRecibido,
        montoVes,
        tasaAplicada,
        montoUsd
      ]);
}

PagoStruct createPagoStruct({
  String? nombre,
  String? email,
  String? tipo,
  String? referencia,
  String? comprobanteUrl,
  String? numeroTelefono,
  String? bancoEnviado,
  String? bancoRecibido,
  double? montoVes,
  double? tasaAplicada,
  double? montoUsd,
}) =>
    PagoStruct(
      nombre: nombre,
      email: email,
      tipo: tipo,
      referencia: referencia,
      comprobanteUrl: comprobanteUrl,
      numeroTelefono: numeroTelefono,
      bancoEnviado: bancoEnviado,
      bancoRecibido: bancoRecibido,
      montoVes: montoVes,
      tasaAplicada: tasaAplicada,
      montoUsd: montoUsd,
    );
