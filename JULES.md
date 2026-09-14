# Guía de Desarrollo para Jules

## Contexto del Proyecto
- **App:** Baul Pandora (Flutter Web/Mobile + Supabase)
- **Entorno:** Conexión a internet inestable / banda ancha baja.

## Reglas de Codificación
1. **Manejo de Imágenes:** El campo `image_path` en Supabase entrega un arreglo `text[]`. Toma siempre el primer elemento con `.first`.
2. **Llamadas a IA / APIs:** Desactiva siempre el streaming (`--no-stream` o llamados HTTP sincrónicos) para evitar fallos de tiempo de espera (`timeout`).
3. **Estructura:** Mantén los cambios modulares. No modifiques la arquitectura base de los archivos grandes sin aislar las funciones.
4. **Pruebas:** Antes de enviar un Pull Request, asegura que los cambios no rompan la compatibilidad con Flutter Web.