# Design: Fix Inventario Page

## Approach
The fix is purely structural at the import level. No logic changes are required.

## File Changes
| File | Change | Description |
|------|--------|-------------|
| `lib/pages/inventario/inventario_widget.dart` | [MODIFY] | Add imports for `auth_util.dart`, `usuarios.dart`, and `productos.dart`. |

## Technical Decisions
- Use `package:baul_pandora/auth/supabase_auth/auth_util.dart` for `currentUserUid`.
- Use `package:baul_pandora/backend/supabase/database/tables/usuarios.dart` for `UsuariosTable`.
- Use `package:baul_pandora/backend/supabase/database/tables/productos.dart` for `ProductosTable` and `ProductosRow`.
