-- ========================================================================
-- BASE DE DATOS LIMPIA PARA SUPERMERCADO & POS (SUPABASE)
-- Baúl Pandora -> Supermercado POS System
-- ========================================================================

-- 1. TABLA DE USUARIOS (Con roles para cajeros, gerentes, supervisores y clientes)
CREATE TABLE IF NOT EXISTS usuarios (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    nombre_completo TEXT NOT NULL,
    rol TEXT NOT NULL DEFAULT 'cajero' CHECK (rol IN ('admin', 'gerente', 'cajero', 'supervisor', 'cliente')),
    cedula_rif TEXT,
    telefono TEXT,
    activo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. TABLA DE CATEGORÍAS (Pasillos y Departamentos del Supermercado)
CREATE TABLE IF NOT EXISTS categorias (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre TEXT NOT NULL UNIQUE,
    descripcion TEXT,
    parent_id UUID REFERENCES categorias(id) ON DELETE SET NULL,
    activo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. TABLA DE PRODUCTOS (Maestro de Inventario con soporte de barras, unidades y peso)
CREATE TABLE IF NOT EXISTS productos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    codigo_barras TEXT UNIQUE,
    sku TEXT UNIQUE,
    nombre TEXT NOT NULL,
    descripcion TEXT,
    precio_usd NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    precio_costo_usd NUMERIC(10, 2) DEFAULT 0.00,
    stock NUMERIC(10, 3) NOT NULL DEFAULT 0.000, -- Permite decimales para venta por kg (ej: 1.500 kg)
    stock_minimo NUMERIC(10, 3) DEFAULT 5.000,
    es_pesado BOOLEAN NOT NULL DEFAULT false, -- true = venta por kg/gr, false = unidad
    unidad_medida TEXT NOT NULL DEFAULT 'unidad' CHECK (unidad_medida IN ('unidad', 'kg', 'gr', 'lt')),
    impuesto_pct NUMERIC(5, 2) DEFAULT 16.00, -- IVA %
    categorias TEXT[] DEFAULT '{}',
    image_path TEXT[] DEFAULT '{}',
    activo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Índices de alto rendimiento para búsqueda inmediata en caja registradora
CREATE INDEX IF NOT EXISTS idx_productos_codigo_barras ON productos(codigo_barras);
CREATE INDEX IF NOT EXISTS idx_productos_nombre ON productos USING gin (to_tsvector('spanish', nombre));

-- 4. TABLA DE CAJAS REGISTRADORAS (Puntos de Venta Físicos)
CREATE TABLE IF NOT EXISTS cajas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    numero_caja INT NOT NULL UNIQUE,
    nombre TEXT NOT NULL,
    activa BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 5. TABLA DE TURNOS DE CAJA (Apertura y Cierre por Cajero)
CREATE TABLE IF NOT EXISTS turnos_caja (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    caja_id UUID NOT NULL REFERENCES cajas(id),
    cajero_id UUID NOT NULL REFERENCES usuarios(id),
    monto_apertura_usd NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    monto_apertura_bs NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    monto_cierre_usd NUMERIC(10, 2),
    monto_cierre_bs NUMERIC(12, 2),
    tasa_bcv_apertura NUMERIC(10, 4) NOT NULL,
    fecha_apertura TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    fecha_cierre TIMESTAMP WITH TIME ZONE,
    estado TEXT NOT NULL DEFAULT 'abierta' CHECK (estado IN ('abierta', 'cerrada', 'cuadrada', 'descuadrada'))
);

-- 6. TABLA DE VENTAS POS (Tickets de Compra procesados en Cajas)
CREATE TABLE IF NOT EXISTS ventas_pos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    numero_ticket SERIAL UNIQUE,
    turno_caja_id UUID REFERENCES turnos_caja(id),
    cajero_id UUID NOT NULL REFERENCES usuarios(id),
    cliente_id UUID REFERENCES usuarios(id),
    tasa_bcv NUMERIC(10, 4) NOT NULL,
    subtotal_usd NUMERIC(10, 2) NOT NULL,
    impuesto_usd NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    descuento_usd NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    total_usd NUMERIC(10, 2) NOT NULL,
    total_bs NUMERIC(12, 2) NOT NULL,
    metodo_pago TEXT NOT NULL CHECK (metodo_pago IN ('efectivo_usd', 'efectivo_bs', 'pago_movil', 'punto_de_venta', 'mixto')),
    monto_pagado_usd NUMERIC(10, 2) DEFAULT 0.00,
    monto_pagado_bs NUMERIC(12, 2) DEFAULT 0.00,
    vuelto_usd NUMERIC(10, 2) DEFAULT 0.00,
    vuelto_bs NUMERIC(12, 2) DEFAULT 0.00,
    estado TEXT NOT NULL DEFAULT 'completada' CHECK (estado IN ('completada', 'anulada')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 7. TABLA DE RENGLONES DE TICKET DE VENTA
CREATE TABLE IF NOT EXISTS venta_pos_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    venta_id UUID NOT NULL REFERENCES ventas_pos(id) ON DELETE CASCADE,
    producto_id UUID NOT NULL REFERENCES productos(id),
    cantidad NUMERIC(10, 3) NOT NULL, -- Permite cantidades decimales para kg (ej: 1.250 kg)
    precio_unitario_usd NUMERIC(10, 2) NOT NULL,
    subtotal_usd NUMERIC(10, 2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 8. TABLA DE KÁRDEX Y AUDITORÍA DE INVENTARIO
CREATE TABLE IF NOT EXISTS inventory_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    producto_id UUID NOT NULL REFERENCES productos(id),
    usuario_id UUID NOT NULL REFERENCES usuarios(id),
    tipo_movimiento TEXT NOT NULL CHECK (tipo_movimiento IN ('venta', 'entrada_proveedor', 'ajuste_manual', 'merma', 'devolucion')),
    cantidad_cambio NUMERIC(10, 3) NOT NULL,
    stock_resultante NUMERIC(10, 3) NOT NULL,
    nota TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 9. FUNCIÓN SQL PARA PROCESAR VENTA Y RESTAR STOCK ATÓMICAMENTE
CREATE OR REPLACE FUNCTION procesar_venta_caja(
    p_turno_caja_id UUID,
    p_cajero_id UUID,
    p_tasa_bcv NUMERIC,
    p_subtotal_usd NUMERIC,
    p_impuesto_usd NUMERIC,
    p_descuento_usd NUMERIC,
    p_total_usd NUMERIC,
    p_total_bs NUMERIC,
    p_metodo_pago TEXT,
    p_monto_pagado_usd NUMERIC,
    p_monto_pagado_bs NUMERIC,
    p_vuelto_usd NUMERIC,
    p_vuelto_bs NUMERIC,
    p_items JSONB
) RETURNS UUID AS $$
DECLARE
    v_venta_id UUID;
    v_item JSONB;
    v_producto_id UUID;
    v_cantidad NUMERIC;
    v_precio_unitario NUMERIC;
    v_subtotal NUMERIC;
    v_stock_actual NUMERIC;
BEGIN
    -- A) Registrar Venta
    INSERT INTO ventas_pos (
        turno_caja_id, cajero_id, tasa_bcv, subtotal_usd, impuesto_usd, descuento_usd,
        total_usd, total_bs, metodo_pago, monto_pagado_usd, monto_pagado_bs, vuelto_usd, vuelto_bs
    ) VALUES (
        p_turno_caja_id, p_cajero_id, p_tasa_bcv, p_subtotal_usd, p_impuesto_usd, p_descuento_usd,
        p_total_usd, p_total_bs, p_metodo_pago, p_monto_pagado_usd, p_monto_pagado_bs, p_vuelto_usd, p_vuelto_bs
    ) RETURNING id INTO v_venta_id;

    -- B) Iterar ítems y descontar stock atómicamente
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_producto_id := (v_item->>'producto_id')::UUID;
        v_cantidad := (v_item->>'cantidad')::NUMERIC;
        v_precio_unitario := (v_item->>'precio_unitario_usd')::NUMERIC;
        v_subtotal := (v_item->>'subtotal_usd')::NUMERIC;

        -- Validar y bloquear fila del producto para actualizar
        SELECT stock INTO v_stock_actual FROM productos WHERE id = v_producto_id FOR UPDATE;
        IF v_stock_actual IS NULL OR v_stock_actual < v_cantidad THEN
            RAISE EXCEPTION 'Stock insuficiente para el producto con ID: %', v_producto_id;
        END IF;

        -- Insertar renglón del ticket
        INSERT INTO venta_pos_items (venta_id, producto_id, cantidad, precio_unitario_usd, subtotal_usd)
        VALUES (v_venta_id, v_producto_id, v_cantidad, v_precio_unitario, v_subtotal);

        -- Restar stock
        UPDATE productos SET stock = stock - v_cantidad WHERE id = v_producto_id;

        -- Guardar log en el Kárdex de inventario
        INSERT INTO inventory_logs (producto_id, usuario_id, tipo_movimiento, cantidad_cambio, stock_resultante, nota)
        VALUES (v_producto_id, p_cajero_id, 'venta', -v_cantidad, v_stock_actual - v_cantidad, 'Venta ticket POS ID: ' || v_venta_id);
    END LOOP;

    RETURN v_venta_id;
END;
$$ LANGUAGE plpgsql;
