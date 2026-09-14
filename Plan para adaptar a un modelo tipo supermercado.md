# Plan para Adaptar a un Modelo Tipo Supermercado (POS & Inventario)

Este documento guarda la propuesta de arquitectura, modelo relacional e integración para adaptar la aplicación a una solución de Punto de Venta (POS) y Gestión de Inventario para Supermercados Locales.

---

## 1. Visión General del Sistema
* **Modelo**: Punto de Venta (POS) para cajas registradoras físicas en supermercados locales, con posibilidad futura de kioscos de auto-despacho (Self-checkout).
* **Multimoneda**: Moneda principal en Dólares ($ USD) con cobro equivalente en Bolívares (Bs.) calculados según la tasa del día (BCV).
* **Venta por Peso y Unidades**: Productos vendidos por unidad o por peso (Kg/gr con ingreso manual de peso inicialmente).
* **Sin Envíos Nacionales**: Las ventas se procesan directamente en tienda física.

---

## 2. Modelo Relacional en Supabase (Tablas & Estructura)

### Tablas Principales:
1. `usuarios`: Roles (`admin`, `gerente`, `cajero`, `supervisor`, `cliente`).
2. `categorias`: Departamentos y pasillos del supermercado.
3. `productos`: Maestro de inventario con `codigo_barras`, `precio_usd`, `precio_costo_usd`, `stock` (decimal), `es_pesado` (bool), `unidad_medida`, `impuesto_pct`.
4. `cajas`: Registro de cajas registradoras físicas.
5. `turnos_caja`: Control de aperturas y cierres de turno por cajero con balance inicial/final en USD y Bs.
6. `ventas_pos`: Tickets de compra con tasa BCV, montos recibidos, vuelto y método de pago (`efectivo_usd`, `efectivo_bs`, `pago_movil`, `punto_de_venta`, `mixto`).
7. `venta_pos_items`: Detalle y renglones de productos vendidos por ticket.
8. `inventory_logs`: Kárdex y auditoría de inventario (ventas, entradas de mercancía, mermas).

---

## 3. Función SQL para Resta Atómica de Stock
El script SQL completo para inicializar esta base de datos se encuentra preservado en `schema.sql` en la raíz del proyecto, incluyendo la función almacenada `procesar_venta_caja(...)` que actualiza el inventario dentro de una única transacción PostgreSQL.
