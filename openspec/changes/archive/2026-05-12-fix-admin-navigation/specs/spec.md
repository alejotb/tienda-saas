# Specs: Fix Admin Navigation

## REQ-01: Resolve Navigation Error
The file `lib/pages/administracion/views/admin_products_view.dart` must correctly recognize `pushNamed` as a method of `BuildContext`.

### Scenario: Static Analysis
- Given: `admin_products_view.dart` is compiled.
- Then: `context.pushNamed(...)` should be a valid call.
