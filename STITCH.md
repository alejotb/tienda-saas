# Contexto de Proyecto: Baul Pandora

## Stack Tecnológico
- **Frontend:** Flutter (Web/Mobile)
- **Backend:** Supabase (Database & Storage)
- **Gestión de estado:** Provider / StatefulWidgets

## Estructura de Datos Clave
- `image_path`: Array de Strings (`text[]`) en Supabase. Al renderizar, tomar siempre `.first`.
- **Envíos:** Selección informativa de agencia (Zoom/MRW/Domesa). El costo no modifica el total del carrito.

## Reglas de Codificación
1. Deshabilitar streaming en llamadas LLM para tolerancia a conexiones lentas.
2. Usar `const` en widgets estáticos para optimización.
3. No alterar la lógica de rutas de cobro ni estructuras base en refactorizaciones.