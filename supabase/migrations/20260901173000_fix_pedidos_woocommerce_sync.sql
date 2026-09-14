-- Agregar columnas compatibles para sincronización con WooCommerce
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS estado text;
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS id_woo bigint;
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS nombre_cliente text;
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS email_cliente text;
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS total numeric;
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS fecha_creacion text;

-- Sincronizar status y estado si alguno es null
UPDATE public.pedidos SET estado = status WHERE estado IS NULL AND status IS NOT NULL;
UPDATE public.pedidos SET status = estado WHERE status IS NULL AND estado IS NOT NULL;

-- Indice unico para id_woo
CREATE UNIQUE INDEX IF NOT EXISTS pedidos_id_woo_idx ON public.pedidos (id_woo) WHERE id_woo IS NOT NULL;
