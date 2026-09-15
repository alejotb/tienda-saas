import 'package:flutter/material.dart';
import 'flutter_flow/request_manager.dart';
import 'package:baul_pandora/backend/schema/structs/index.dart';
import 'backend/supabase/supabase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'flutter_flow/custom_functions.dart';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {
    prefs = await SharedPreferences.getInstance();
    _safeInit(() {
      _activeStoreId = prefs.getString('ff_activeStoreId') ?? '';
    });
    _safeInit(() {
      _activeStoreSlug = prefs.getString('ff_activeStoreSlug') ?? '';
    });
    _safeInit(() {
      _invitado = prefs.getBool('ff_invitado') ?? false;
    });
    _safeInit(() {
      _isAdmin = prefs.getBool('ff_isAdmin') ?? false;
    });
    _safeInit(() {
      _forceLocalDB = prefs.getBool('ff_forceLocalDB') ?? false;
    });
    _safeInit(() {
      _guestUuid = prefs.getString('ff_guestUuid') ?? '';
    });
    _safeInit(() {
      _carritoActual = prefs.getString('ff_carritoActual') ?? _carritoActual;
    });
    _safeInit(() {
      _itemsFavoritos =
          prefs.getStringList('ff_itemsFavoritos') ?? _itemsFavoritos;
    });
    _safeInit(() {
      _itemsCarrito = prefs
              .getStringList('ff_itemsCarrito')
              ?.map((x) {
                try {
                  return CarritoStruct.fromSerializableMap(jsonDecode(x));
                } catch (e) {
                  print("Can't decode persisted data type. Error: $e.");
                  return null;
                }
              })
              .withoutNulls
              .toList() ??
          _itemsCarrito;
    });
    _safeInit(() {
      _itemsCarritoActual = prefs.getStringList('ff_itemsCarritoActual') ??
          _itemsCarritoActual;
    });
    _safeInit(() {
      _listaDirecciones = prefs
              .getStringList('ff_listaDirecciones')
              ?.map((x) {
                try {
                  return AddressStruct.fromSerializableMap(jsonDecode(x));
                } catch (e) {
                  print("Can't decode persisted data type. Error: $e.");
                  return null;
                }
              })
              .withoutNulls
              .toList() ??
          _listaDirecciones;
    });
  }

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  late SharedPreferences prefs;

  List<ShippingOptionsStruct> _shippingOptions = [];
  List<ShippingOptionsStruct> get shippingOptions => _shippingOptions;
  set shippingOptions(List<ShippingOptionsStruct> value) {
    _shippingOptions = value;
  }

  void addToShippingOptions(ShippingOptionsStruct value) {
    shippingOptions.add(value);
  }

  void removeFromShippingOptions(ShippingOptionsStruct value) {
    shippingOptions.remove(value);
  }

  void removeAtIndexFromShippingOptions(int index) {
    shippingOptions.removeAt(index);
  }

  void updateShippingOptionsAtIndex(
    int index,
    ShippingOptionsStruct Function(ShippingOptionsStruct) updateFn,
  ) {
    shippingOptions[index] = updateFn(_shippingOptions[index]);
  }

  void insertAtIndexInShippingOptions(int index, ShippingOptionsStruct value) {
    shippingOptions.insert(index, value);
  }

  String _activeStoreId = '';
  String get activeStoreId => _activeStoreId;
  set activeStoreId(String value) {
    _activeStoreId = value;
    prefs.setString('ff_activeStoreId', value);
  }

  String _activeStoreSlug = '';
  String get activeStoreSlug => _activeStoreSlug;
  set activeStoreSlug(String value) {
    _activeStoreSlug = value;
    prefs.setString('ff_activeStoreSlug', value);
  }

  bool _invitado = false;
  bool get invitado => _invitado;
  set invitado(bool value) {
    _invitado = value;
    prefs.setBool('ff_invitado', value);
  }

  bool _isAdmin = false;
  bool get isAdmin => _isAdmin;
  set isAdmin(bool value) {
    _isAdmin = value;
    prefs.setBool('ff_isAdmin', value);
  }

  bool _forceLocalDB = false;
  bool get forceLocalDB => _forceLocalDB;
  set forceLocalDB(bool value) {
    _forceLocalDB = value;
    prefs.setBool('ff_forceLocalDB', value);
  }

  String _returnPath = '';
  String get returnPath => _returnPath;
  set returnPath(String value) {
    _returnPath = value;
  }

  String _guestUuid = '';
  String get guestUuid {
    if (_guestUuid.isEmpty) {
      _guestUuid = generateRealUUID() ?? '';
      prefs.setString('ff_guestUuid', _guestUuid);
    }
    return _guestUuid;
  }
  set guestUuid(String value) {
    _guestUuid = value;
    prefs.setString('ff_guestUuid', value);
  }

  String _carritoActual = '';
  String get carritoActual => _carritoActual;
  set carritoActual(String value) {
    _carritoActual = value;
    prefs.setString('ff_carritoActual', value);
  }

  List<String> _itemsFavoritos = [];
  List<String> get itemsFavoritos => _itemsFavoritos;
  set itemsFavoritos(List<String> value) {
    _itemsFavoritos = value;
    prefs.setStringList('ff_itemsFavoritos', value);
  }

  void addToItemsFavoritos(String value) {
    itemsFavoritos.add(value);
    prefs.setStringList('ff_itemsFavoritos', _itemsFavoritos);
  }

  void removeFromItemsFavoritos(String value) {
    itemsFavoritos.remove(value);
    prefs.setStringList('ff_itemsFavoritos', _itemsFavoritos);
  }

  void removeAtIndexFromItemsFavoritos(int index) {
    itemsFavoritos.removeAt(index);
    prefs.setStringList('ff_itemsFavoritos', _itemsFavoritos);
  }

  void updateItemsFavoritosAtIndex(
    int index,
    String Function(String) updateFn,
  ) {
    itemsFavoritos[index] = updateFn(_itemsFavoritos[index]);
    prefs.setStringList('ff_itemsFavoritos', _itemsFavoritos);
  }

  void insertAtIndexInItemsFavoritos(int index, String value) {
    itemsFavoritos.insert(index, value);
    prefs.setStringList('ff_itemsFavoritos', _itemsFavoritos);
  }

  List<CarritoStruct> _itemsCarrito = [];
  List<CarritoStruct> get itemsCarrito => _itemsCarrito;
  set itemsCarrito(List<CarritoStruct> value) {
    _itemsCarrito = value;
    prefs.setStringList(
        'ff_itemsCarrito', value.map((x) => x.serialize()).toList());
  }

  void addToItemsCarrito(CarritoStruct value) {
    itemsCarrito.add(value);
    prefs.setStringList(
        'ff_itemsCarrito', _itemsCarrito.map((x) => x.serialize()).toList());
  }

  void removeFromItemsCarrito(CarritoStruct value) {
    itemsCarrito.remove(value);
    prefs.setStringList(
        'ff_itemsCarrito', _itemsCarrito.map((x) => x.serialize()).toList());
  }

  void removeAtIndexFromItemsCarrito(int index) {
    itemsCarrito.removeAt(index);
    prefs.setStringList(
        'ff_itemsCarrito', _itemsCarrito.map((x) => x.serialize()).toList());
  }

  void updateItemsCarritoAtIndex(
    int index,
    CarritoStruct Function(CarritoStruct) updateFn,
  ) {
    itemsCarrito[index] = updateFn(_itemsCarrito[index]);
    prefs.setStringList(
        'ff_itemsCarrito', _itemsCarrito.map((x) => x.serialize()).toList());
  }

  void insertAtIndexInItemsCarrito(int index, CarritoStruct value) {
    itemsCarrito.insert(index, value);
    prefs.setStringList(
        'ff_itemsCarrito', _itemsCarrito.map((x) => x.serialize()).toList());
  }

  List<String> _itemsCarritoActual = [];
  List<String> get itemsCarritoActual => _itemsCarritoActual;
  set itemsCarritoActual(List<String> value) {
    _itemsCarritoActual = value;
    prefs.setStringList('ff_itemsCarritoActual', value);
  }

  void addToItemsCarritoActual(String value) {
    itemsCarritoActual.add(value);
    prefs.setStringList('ff_itemsCarritoActual', _itemsCarritoActual);
  }

  void removeFromItemsCarritoActual(String value) {
    itemsCarritoActual.remove(value);
    prefs.setStringList('ff_itemsCarritoActual', _itemsCarritoActual);
  }

  void removeAtIndexFromItemsCarritoActual(int index) {
    itemsCarritoActual.removeAt(index);
    prefs.setStringList('ff_itemsCarritoActual', _itemsCarritoActual);
  }

  void updateItemsCarritoActualAtIndex(
    int index,
    String Function(String) updateFn,
  ) {
    itemsCarritoActual[index] = updateFn(_itemsCarritoActual[index]);
    prefs.setStringList('ff_itemsCarritoActual', _itemsCarritoActual);
  }

  void insertAtIndexInItemsCarritoActual(int index, String value) {
    itemsCarritoActual.insert(index, value);
    prefs.setStringList('ff_itemsCarritoActual', _itemsCarritoActual);
  }

  List<AddressStruct> _listaDirecciones = [];
  List<AddressStruct> get listaDirecciones => _listaDirecciones;
  set listaDirecciones(List<AddressStruct> value) {
    _listaDirecciones = value;
    prefs.setStringList(
        'ff_listaDirecciones', value.map((x) => x.serialize()).toList());
  }

  void addToListaDirecciones(AddressStruct value) {
    listaDirecciones.add(value);
    prefs.setStringList('ff_listaDirecciones',
        _listaDirecciones.map((x) => x.serialize()).toList());
  }

  void removeFromListaDirecciones(AddressStruct value) {
    listaDirecciones.remove(value);
    prefs.setStringList('ff_listaDirecciones',
        _listaDirecciones.map((x) => x.serialize()).toList());
  }

  void removeAtIndexFromListaDirecciones(int index) {
    listaDirecciones.removeAt(index);
    prefs.setStringList('ff_listaDirecciones',
        _listaDirecciones.map((x) => x.serialize()).toList());
  }

  void updateListaDireccionesAtIndex(
    int index,
    AddressStruct Function(AddressStruct) updateFn,
  ) {
    listaDirecciones[index] = updateFn(_listaDirecciones[index]);
    prefs.setStringList('ff_listaDirecciones',
        _listaDirecciones.map((x) => x.serialize()).toList());
  }

  void insertAtIndexInListaDirecciones(int index, AddressStruct value) {
    listaDirecciones.insert(index, value);
    prefs.setStringList('ff_listaDirecciones',
        _listaDirecciones.map((x) => x.serialize()).toList());
  }

  final _transactionsManager = FutureRequestManager<List<PedidosRow>>();
  Future<List<PedidosRow>> transactions({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<List<PedidosRow>> Function() requestFn,
  }) =>
      _transactionsManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearTransactionsCache() => _transactionsManager.clear();
  void clearTransactionsCacheKey(String? uniqueKey) =>
      _transactionsManager.clearRequest(uniqueKey);

  final _productListManager = FutureRequestManager<List<ProductosRow>>();
  Future<List<ProductosRow>> productList({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<List<ProductosRow>> Function() requestFn,
  }) =>
      _productListManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearProductListCache() => _productListManager.clear();
  void clearProductListCacheKey(String? uniqueKey) =>
      _productListManager.clearRequest(uniqueKey);

  void clearUserData() {
    itemsFavoritos = [];
    prefs.setStringList('ff_itemsFavoritos', []);

    listaDirecciones = [];
    prefs.setStringList('ff_listaDirecciones', []);

    itemsCarrito = [];
    prefs.setStringList('ff_itemsCarrito', []);

    carritoActual = '';
    prefs.setString('ff_carritoActual', '');

    itemsCarritoActual = [];
    prefs.setStringList('ff_itemsCarritoActual', []);

    invitado = false;
    prefs.setBool('ff_invitado', false);

    isAdmin = false;
    prefs.setBool('ff_isAdmin', false);

    guestUuid = '';
    prefs.setString('ff_guestUuid', '');

    notifyListeners();
  }
}

void _safeInit(Function() initializeField) {
  try {
    initializeField();
  } catch (_) {}
}

Future _safeInitAsync(Function() initializeField) async {
  try {
    await initializeField();
  } catch (_) {}
}