import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-wc-webhook-topic, x-wc-webhook-resource, x-wc-webhook-event, x-wc-webhook-signature, x-wc-webhook-id, x-wc-webhook-delivery-id',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders, status: 204 })
  }
  if (req.method === 'HEAD') {
    return new Response(null, { headers: corsHeaders, status: 200 })
  }
  if (req.method === 'GET') {
    return new Response('OK', { headers: { ...corsHeaders, 'Content-Type': 'text/plain' }, status: 200 })
  }

  const startTime = Date.now()
  const topic = req.headers.get('x-wc-webhook-topic') || ''
  const resource = req.headers.get('x-wc-webhook-resource') || ''
  const event = req.headers.get('x-wc-webhook-event') || ''
  const deliveryId = req.headers.get('x-wc-webhook-delivery-id') || ''

  console.log(`📡 Webhook recibido de WooCommerce: Topic=${topic}, Resource=${resource}, Event=${event}, DeliveryId=${deliveryId}`)

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') || 'https://uzhfziprpmxnelwpczgo.supabase.co'
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
    const defaultAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV6aGZ6aXBycG14bmVsd3BjemdvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0MDQ0MDMsImV4cCI6MjA5Mjk4MDQwM30.SqQEt7uS96eTPJdO81aLz6KJPdDX9UCtlzBGRhXeNH8'
    
    const authHeader = req.headers.get('Authorization')
    const supabase = createClient(
      supabaseUrl,
      supabaseServiceKey || (authHeader ? authHeader.replace('Bearer ', '') : defaultAnonKey)
    )

    let body: any = null
    try {
      body = await req.json()
    } catch {
      // Body vacío o no parseable
    }

    // 1. PING DE VERIFICACIÓN DE WOOCOMMERCE
    if (topic === 'action.woocommerce_webhook_payload_delivery' || (body && body.webhook_id && !body.id)) {
      console.log('✅ Ping de verificación de WooCommerce procesado con éxito.')
      return new Response(
        JSON.stringify({ success: true, message: 'Webhook handshake OK' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      )
    }

    if (!body) {
      return new Response(
        JSON.stringify({ success: false, error: 'Cuerpo de solicitud vacío' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
      )
    }

    const SYSTEM_USER_ID = 'eb76cd8e-3803-4727-86c1-a2dc921f199a'

    const mapWooStatus = (status: string) => {
      switch (status?.toLowerCase()) {
        case 'completed': return 'completado'
        case 'processing': return 'procesando'
        case 'pending': return 'pendiente'
        case 'on-hold': return 'en_espera'
        case 'cancelled': return 'cancelado'
        case 'refunded': return 'reembolsado'
        case 'failed': return 'fallido'
        default: return status || 'pendiente'
      }
    }

    const parseWooDate = (dateGmt?: string, dateLocal?: string) => {
      if (dateGmt && typeof dateGmt === 'string' && dateGmt.trim()) {
        const clean = dateGmt.trim()
        return clean.endsWith('Z') ? clean : `${clean}Z`
      }
      if (dateLocal && typeof dateLocal === 'string' && dateLocal.trim()) {
        const parsed = new Date(dateLocal.trim())
        if (!isNaN(parsed.getTime())) {
          return parsed.toISOString()
        }
      }
      return new Date().toISOString()
    }

    // =========================================================================
    // 2. EVENTO: PEDIDO CREADO O ACTUALIZADO (order.created / order.updated)
    // =========================================================================
    if (topic.startsWith('order.') || resource === 'order' || (body.id && Array.isArray(body.line_items))) {
      const order = body
      console.log(`🛒 Procesando Webhook de Pedido #${order.id} (${order.status})...`)

      const clientEmail = order.billing?.email?.toLowerCase()?.trim() || ''
      const customerName = `${order.billing?.first_name || 'Cliente'} ${order.billing?.last_name || ''}`.trim()

      // 2.1 Buscar usuario por email de forma segura
      let assignedUserId: string | null = null
      if (clientEmail) {
        const { data: matchedUser } = await supabase
          .from('usuarios')
          .select('id')
          .eq('email', clientEmail)
          .limit(1)
          .maybeSingle()

        if (matchedUser && matchedUser.id) {
          assignedUserId = matchedUser.id
        }
      }

      const mappedStatus = mapWooStatus(order.status)
      const totalPrice = parseFloat(order.total || '0') || 0
      const taxPrice = parseFloat(order.total_tax || '0') || 0
      const isPaid = mappedStatus === 'completado' || mappedStatus === 'procesando'
      const orderDate = parseWooDate(order.date_created_gmt, order.date_created)

      const shippingInfo = order.shipping?.address_1 
        ? `${order.shipping.first_name || ''} ${order.shipping.last_name || ''} - ${order.shipping.address_1}, ${order.shipping.city || ''} (${order.shipping.phone || order.billing?.phone || ''})`.trim()
        : (order.billing?.address_1 ? `${order.billing.first_name || ''} ${order.billing.last_name || ''} - ${order.billing.address_1}, ${order.billing.city || ''} (${order.billing.phone || ''})`.trim() : 'Entrega en tienda / Sin dirección')

      const paymentInfo = {
        tipo: order.payment_method_title || order.payment_method || 'WooCommerce',
        email: order.billing?.email || '',
        nombre: customerName,
        referencia: order.transaction_id || `WooCommerce #${order.id}`,
        fecha_registro: orderDate,
        numeroTelefono: order.billing?.phone || '',
        currency: order.currency || 'USD',
        payment_method: order.payment_method || '',
      }

      const orderPayload: any = {
        id_woo: order.id,
        pedido_nombre: `Order #${order.id}`,
        nombre_cliente: customerName,
        email_cliente: order.billing?.email || null,
        total: totalPrice,
        total_price: totalPrice,
        tax: taxPrice,
        status: mappedStatus,
        estado: mappedStatus,
        created_at: orderDate,
        fecha_creacion: orderDate,
        shipping_address: shippingInfo,
        datos_pago: paymentInfo,
        saldo_pendiente: isPaid ? 0.0 : totalPrice,
        paid_amount_usd: isPaid ? totalPrice : 0.0,
      }

      if (assignedUserId) {
        orderPayload.user_id = assignedUserId
      }

      // 2.2 Upsert del pedido
      const { data: dbOrder, error: orderErr } = await supabase
        .from('pedidos')
        .upsert([orderPayload], { onConflict: 'id_woo' })
        .select('id')
        .maybeSingle()

      if (orderErr || !dbOrder) {
        throw new Error(`Error guardando pedido #${order.id}: ${orderErr?.message}`)
      }

      const dbOrderId = dbOrder.id
      const lineItems = order.line_items || []
      const isPaidOrActive = mappedStatus === 'completado' || mappedStatus === 'procesando' || mappedStatus === 'en_espera' || mappedStatus === 'pendiente'

      // 2.3 Cargar notas de logs existentes para este pedido
      const { data: existingLogs } = await supabase
        .from('inventory_logs')
        .select('notas')
        .like('notas', `%Venta Woo #${order.id}%`)

      const existingLogNotes = new Set((existingLogs || []).map((l: any) => l.notas))

      let movementsCreated = 0

      // 2.4 Procesar line_items
      for (const item of lineItems) {
        const targetWooId = (item.variation_id && item.variation_id > 0) ? item.variation_id : item.product_id

        let { data: matchedProduct } = await supabase
          .from('productos')
          .select('id, stock, nombre')
          .eq('id_woo', targetWooId)
          .limit(1)
          .maybeSingle()

        if (!matchedProduct && item.product_id && item.product_id !== targetWooId) {
          const { data: fallbackProd } = await supabase
            .from('productos')
            .select('id, stock, nombre')
            .eq('id_woo', item.product_id)
            .limit(1)
            .maybeSingle()
          matchedProduct = fallbackProd
        }

        if (matchedProduct) {
          const itemPrice = parseFloat(item.price || item.total || '0') || 0
          const itemQty = item.quantity || 1

          // Guardar item en pedido_items
          const { data: existingItem } = await supabase
            .from('pedido_items')
            .select('id')
            .eq('pedido_id', dbOrderId)
            .eq('product_id', matchedProduct.id)
            .limit(1)

          if (!existingItem || existingItem.length === 0) {
            await supabase
              .from('pedido_items')
              .insert([
                {
                  pedido_id: dbOrderId,
                  product_id: matchedProduct.id,
                  quantity: itemQty,
                  price_at_purchase: itemPrice,
                }
              ])
          }

          // Registrar movimiento de inventario y descontar stock
          const uniqueNoteKey = `Venta Woo #${order.id} - Item #${item.id}`
          if (isPaidOrActive && !existingLogNotes.has(uniqueNoteKey)) {
            const logPayload: any = {
              producto_id: matchedProduct.id,
              cantidad: -itemQty,
              tipo_operacion: 'venta_woo',
              notas: `${uniqueNoteKey} (${customerName} - ${matchedProduct.nombre})`,
              created_at: orderDate,
            }

            if (assignedUserId) {
              logPayload.usuario_id = assignedUserId
            }

            const { error: logErr } = await supabase
              .from('inventory_logs')
              .insert([logPayload])

            if (!logErr) {
              existingLogNotes.add(uniqueNoteKey)
              movementsCreated++

              const currentStock = typeof matchedProduct.stock === 'number' ? matchedProduct.stock : 0
              const newStock = Math.max(0, currentStock - itemQty)
              await supabase
                .from('productos')
                .update({ stock: newStock })
                .eq('id', matchedProduct.id)

              console.log(`📉 Stock actualizado para ${matchedProduct.nombre}: ${currentStock} -> ${newStock}`)
            } else {
              console.error(`⚠️ Error insertando inventory_log para item #${item.id}:`, logErr.message)
            }
          }
        }
      }

      console.log(`✅ Webhook: Pedido #${order.id} procesado con éxito. Movimientos creados: ${movementsCreated}`)
      return new Response(
        JSON.stringify({
          success: true,
          order_id: order.id,
          pedido_id: dbOrderId,
          status: mappedStatus,
          movements_created: movementsCreated,
          duration_ms: Date.now() - startTime,
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      )
    }

    // =========================================================================
    // 3. EVENTO: PRODUCTO CREADO O ACTUALIZADO (product.created / product.updated)
    // =========================================================================
    if (topic.startsWith('product.') || resource === 'product') {
      const p = body
      console.log(`📦 Procesando Webhook de Producto #${p.id} (${p.name})...`)

      // Preservar fotos existentes si Woo viene vacío
      const { data: existingProd } = await supabase
        .from('productos')
        .select('image_path, descripcion')
        .eq('id_woo', p.id)
        .limit(1)
        .single()

      const wooImgUrls = (p.images || []).map((img: any) => img.src).filter((url: any) => Boolean(url))
      const finalImgUrls = wooImgUrls.length > 0 ? wooImgUrls : (existingProd?.image_path || [])
      
      const wooDesc = p.description || p.short_description || ''
      const finalDesc = (wooDesc && wooDesc.trim() !== '') ? wooDesc : (existingProd?.descripcion || '')

      const catIds = (p.categories || []).map((c: any) => c.id)
      const price = parseFloat(p.price || p.regular_price || '0') || 0
      const stock = typeof p.stock_quantity === 'number' ? p.stock_quantity : (p.in_stock ? 10 : 0)

      const productPayload = {
        id_woo: p.id,
        nombre: p.name,
        descripcion: finalDesc,
        precio: price,
        stock: stock,
        image_path: finalImgUrls,
        categoria_id_woo: catIds,
        sku: p.sku || null,
        parent_id_woo: null,
        es_variacion: false,
        es_variable: p.type === 'variable',
        atributos: p.attributes || [],
      }

      await supabase
        .from('productos')
        .upsert([productPayload], { onConflict: 'id_woo' })

      console.log(`✅ Webhook: Producto #${p.id} (${p.name}) actualizado.`)
      return new Response(
        JSON.stringify({
          success: true,
          product_id: p.id,
          duration_ms: Date.now() - startTime,
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      )
    }

    return new Response(
      JSON.stringify({ success: true, message: 'Evento ignorado o no reconocido', topic }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (err: any) {
    console.error(`🔥 Error procesando Webhook de WooCommerce: ${err.message}`)
    return new Response(
      JSON.stringify({ success: false, error: err.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
    )
  }
})
