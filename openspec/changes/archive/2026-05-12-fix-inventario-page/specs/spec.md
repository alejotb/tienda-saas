# Specs: Fix Inventario Page

## REQ-01: Resolve Type Errors
The file `lib/pages/inventario/inventario_widget.dart` must correctly recognize `ProductosRow` and `UsuariosRow` (if used).

### Scenario: Static Analysis
- Given: `inventario_widget.dart` is compiled.
- Then: `ProductosRow` should be recognized as a valid type.

## REQ-02: Resolve Method/Getter Errors
The file `lib/pages/inventario/inventario_widget.dart` must correctly recognize `UsuariosTable`, `ProductosTable`, and `currentUserUid`.

### Scenario: Static Analysis
- Given: `inventario_widget.dart` is compiled.
- Then: `UsuariosTable().queryRows` and `ProductosTable().queryRows` should be valid calls.
- And: `currentUserUid` should be a valid getter.
