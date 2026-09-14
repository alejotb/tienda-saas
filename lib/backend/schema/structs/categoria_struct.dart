// ignore_for_file: unnecessary_getters_setters

import 'package:baul_pandora/backend/schema/util/schema_util.dart';

import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';

class CategoriaStruct extends BaseStruct {
  CategoriaStruct({
    String? nombre,
    List<String>? categoriasHijas,
    String? imagePath,
  })  : _nombre = nombre,
        _categoriasHijas = categoriasHijas,
        _imagePath = imagePath;

  // "nombre" field.
  String? _nombre;
  String get nombre => _nombre ?? '';
  set nombre(String? val) => _nombre = val;

  bool hasNombre() => _nombre != null;

  // "categoriasHijas" field.
  List<String>? _categoriasHijas;
  List<String> get categoriasHijas => _categoriasHijas ?? const [];
  set categoriasHijas(List<String>? val) => _categoriasHijas = val;

  void updateCategoriasHijas(Function(List<String>) updateFn) {
    updateFn(_categoriasHijas ??= []);
  }

  bool hasCategoriasHijas() => _categoriasHijas != null;

  // "imagePath" field.
  String? _imagePath;
  String get imagePath => _imagePath ?? '';
  set imagePath(String? val) => _imagePath = val;

  bool hasImagePath() => _imagePath != null;

  static CategoriaStruct fromMap(Map<String, dynamic> data) => CategoriaStruct(
        nombre: data['nombre'] as String?,
        categoriasHijas: getDataList(data['categoriasHijas']),
        imagePath: data['imagePath'] as String?,
      );

  static CategoriaStruct? maybeFromMap(dynamic data) => data is Map
      ? CategoriaStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'nombre': _nombre,
        'categoriasHijas': _categoriasHijas,
        'imagePath': _imagePath,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'nombre': serializeParam(
          _nombre,
          ParamType.String,
        ),
        'categoriasHijas': serializeParam(
          _categoriasHijas,
          ParamType.String,
          isList: true,
        ),
        'imagePath': serializeParam(
          _imagePath,
          ParamType.String,
        ),
      }.withoutNulls;

  static CategoriaStruct fromSerializableMap(Map<String, dynamic> data) =>
      CategoriaStruct(
        nombre: deserializeParam(
          data['nombre'],
          ParamType.String,
          false,
        ),
        categoriasHijas: deserializeParam<String>(
          data['categoriasHijas'],
          ParamType.String,
          true,
        ),
        imagePath: deserializeParam(
          data['imagePath'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'CategoriaStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    const listEquality = ListEquality();
    return other is CategoriaStruct &&
        nombre == other.nombre &&
        listEquality.equals(categoriasHijas, other.categoriasHijas) &&
        imagePath == other.imagePath;
  }

  @override
  int get hashCode =>
      const ListEquality().hash([nombre, categoriasHijas, imagePath]);
}

CategoriaStruct createCategoriaStruct({
  String? nombre,
  String? imagePath,
}) =>
    CategoriaStruct(
      nombre: nombre,
      imagePath: imagePath,
    );
