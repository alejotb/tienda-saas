// ignore_for_file: unnecessary_getters_setters

import 'package:baul_pandora/backend/schema/util/schema_util.dart';

import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';

class ProductoStruct extends BaseStruct {
  ProductoStruct({
    String? nombre,
    double? precio,
    String? descripcion,
    List<String>? categorias,
    List<String>? photoPath,
    int? cantidad,
    String? id,
  })  : _nombre = nombre,
        _precio = precio,
        _descripcion = descripcion,
        _categorias = categorias,
        _photoPath = photoPath,
        _cantidad = cantidad,
        _id = id;

  // "nombre" field.
  String? _nombre;
  String get nombre => _nombre ?? '';
  set nombre(String? val) => _nombre = val;

  bool hasNombre() => _nombre != null;

  // "precio" field.
  double? _precio;
  double get precio => _precio ?? 0.0;
  set precio(double? val) => _precio = val;

  void incrementPrecio(double amount) => precio = precio + amount;

  bool hasPrecio() => _precio != null;

  // "descripcion" field.
  String? _descripcion;
  String get descripcion => _descripcion ?? '';
  set descripcion(String? val) => _descripcion = val;

  bool hasDescripcion() => _descripcion != null;

  // "categorias" field.
  List<String>? _categorias;
  List<String> get categorias => _categorias ?? const [];
  set categorias(List<String>? val) => _categorias = val;

  void updateCategorias(Function(List<String>) updateFn) {
    updateFn(_categorias ??= []);
  }

  bool hasCategorias() => _categorias != null;

  // "photoPath" field.
  List<String>? _photoPath;
  List<String> get photoPath => _photoPath ?? const [];
  set photoPath(List<String>? val) => _photoPath = val;

  void updatePhotoPath(Function(List<String>) updateFn) {
    updateFn(_photoPath ??= []);
  }

  bool hasPhotoPath() => _photoPath != null;

  // "cantidad" field.
  int? _cantidad;
  int get cantidad => _cantidad ?? 0;
  set cantidad(int? val) => _cantidad = val;

  void incrementCantidad(int amount) => cantidad = cantidad + amount;

  bool hasCantidad() => _cantidad != null;

  // "id" field.
  String? _id;
  String get id => _id ?? '';
  set id(String? val) => _id = val;

  bool hasId() => _id != null;

  static ProductoStruct fromMap(Map<String, dynamic> data) => ProductoStruct(
        nombre: data['nombre'] as String?,
        precio: castToType<double>(data['precio']),
        descripcion: data['descripcion'] as String?,
        categorias: getDataList(data['categorias']),
        photoPath: getDataList(data['photoPath']),
        cantidad: castToType<int>(data['cantidad']),
        id: data['id'] as String?,
      );

  static ProductoStruct? maybeFromMap(dynamic data) =>
      data is Map ? ProductoStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'nombre': _nombre,
        'precio': _precio,
        'descripcion': _descripcion,
        'categorias': _categorias,
        'photoPath': _photoPath,
        'cantidad': _cantidad,
        'id': _id,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'nombre': serializeParam(
          _nombre,
          ParamType.String,
        ),
        'precio': serializeParam(
          _precio,
          ParamType.double,
        ),
        'descripcion': serializeParam(
          _descripcion,
          ParamType.String,
        ),
        'categorias': serializeParam(
          _categorias,
          ParamType.String,
          isList: true,
        ),
        'photoPath': serializeParam(
          _photoPath,
          ParamType.String,
          isList: true,
        ),
        'cantidad': serializeParam(
          _cantidad,
          ParamType.int,
        ),
        'id': serializeParam(
          _id,
          ParamType.String,
        ),
      }.withoutNulls;

  static ProductoStruct fromSerializableMap(Map<String, dynamic> data) =>
      ProductoStruct(
        nombre: deserializeParam(
          data['nombre'],
          ParamType.String,
          false,
        ),
        precio: deserializeParam(
          data['precio'],
          ParamType.double,
          false,
        ),
        descripcion: deserializeParam(
          data['descripcion'],
          ParamType.String,
          false,
        ),
        categorias: deserializeParam<String>(
          data['categorias'],
          ParamType.String,
          true,
        ),
        photoPath: deserializeParam<String>(
          data['photoPath'],
          ParamType.String,
          true,
        ),
        cantidad: deserializeParam(
          data['cantidad'],
          ParamType.int,
          false,
        ),
        id: deserializeParam(
          data['id'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'ProductoStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    const listEquality = ListEquality();
    return other is ProductoStruct &&
        nombre == other.nombre &&
        precio == other.precio &&
        descripcion == other.descripcion &&
        listEquality.equals(categorias, other.categorias) &&
        listEquality.equals(photoPath, other.photoPath) &&
        cantidad == other.cantidad &&
        id == other.id;
  }

  @override
  int get hashCode => const ListEquality()
      .hash([nombre, precio, descripcion, categorias, photoPath, cantidad, id]);
}

ProductoStruct createProductoStruct({
  String? nombre,
  double? precio,
  String? descripcion,
  int? cantidad,
  String? id,
}) =>
    ProductoStruct(
      nombre: nombre,
      precio: precio,
      descripcion: descripcion,
      cantidad: cantidad,
      id: id,
    );
