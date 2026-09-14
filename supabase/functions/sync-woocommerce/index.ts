import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
}

serve(async (req: Request) => {
  // Manejo inmediato de preflight OPTIONS y health-checks HEAD (sin body según RFC) y GET
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
  const logs: string[] = []
  const log = (msg: string) => {
    console.log(msg)
    logs.push(`[${new Date().toISOString()}] ${msg}`)
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') || 'https://uzhfziprpmxnelwpczgo.supabase.co'
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
    const defaultAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV6aGZ6aXBycG14bmVsd3BjemdvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0MDQ0MDMsImV4cCI6MjA5Mjk4MDQwM30.SqQEt7uS96eTPJdO81aLz6KJPdDX9UCtlzBGRhXeNH8'
    
    // Si no hay service key en env, usamos el token provisto o la clave pública
    const authHeader = req.headers.get('Authorization')
    const supabase = createClient(
      supabaseUrl,
      supabaseServiceKey || (authHeader ? authHeader.replace('Bearer ', '') : defaultAnonKey)
    )

    const wooBaseUrl = Deno.env.get('WOO_URL') || 'https://elbauldepandora.com/wp-json/wc/v3'
    const wooKey = Deno.env.get('WOO_KEY') || 'ck_bec5b00c45d00acea2134de6c86b3393f61742e5'
    const wooSecret = Deno.env.get('WOO_SECRET') || 'cs_41cd506b9f9bfe86ea299bea01f1643756175bc8'
    const basicAuth = btoa(`${wooKey}:${wooSecret}`)

    const wooHeaders = {
      'Authorization': `Basic ${basicAuth}`,
      'Content-Type': 'application/json',
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

    const topic = req.headers.get('x-wc-webhook-topic') || ''
    const resource = req.headers.get('x-wc-webhook-resource') || ''

    let body: any = null
    try {
      if (req.method === 'POST') {
        body = await req.json()
      }
    } catch {
      // Body vacío
    }

    // =========================================================================
    // 0. WEBHOOK EN TIEMPO REAL DESDE WOOCOMMERCE
    // =========================================================================

    // 0.1 Ping de verificación de WooCommerce o cuerpo de handshake
    if (topic === 'action.woocommerce_webhook_payload_delivery' || !body || (body && (body.webhook_id || Object.keys(body).length === 0) && !body.id && !body.target)) {
      log('✅ Ping de verificación / Handshake de WooCommerce procesado en 0ms.')
      return new Response(
        JSON.stringify({ success: true, message: 'Webhook handshake OK' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      )
    }

    // 0.2 Webhook de Pedido en tiempo real (order.created / order.updated)
    if (topic.startsWith('order.') || resource === 'order' || (body && body.id && Array.isArray(body.line_items) && !body.target)) {
      const o = body
      log(`⚡ Procesando Webhook en Tiempo Real para Pedido #${o.id} (${o.status})...`)

      const clientEmail = o.billing?.email?.toLowerCase()?.trim() || ''
      const customerName = `${o.billing?.first_name || 'Cliente'} ${o.billing?.last_name || ''}`.trim()

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

      const mappedStatus = mapWooStatus(o.status)
      const totalPrice = parseFloat(o.total || '0') || 0
      const taxPrice = parseFloat(o.total_tax || '0') || 0
      const isPaid = mappedStatus === 'completado' || mappedStatus === 'procesando'
      const orderDate = parseWooDate(o.date_created_gmt, o.date_created)

      const shippingInfo = o.shipping?.address_1 
        ? `${o.shipping.first_name || ''} ${o.shipping.last_name || ''} - ${o.shipping.address_1}, ${o.shipping.city || ''} (${o.shipping.phone || o.billing?.phone || ''})`.trim()
        : (o.billing?.address_1 ? `${o.billing.first_name || ''} ${o.billing.last_name || ''} - ${o.billing.address_1}, ${o.billing.city || ''} (${o.billing.phone || ''})`.trim() : 'Entrega en tienda / Sin dirección')

      const paymentInfo = {
        tipo: o.payment_method_title || o.payment_method || 'WooCommerce',
        email: o.billing?.email || '',
        nombre: customerName,
        referencia: o.transaction_id || `WooCommerce #${o.id}`,
        fecha_registro: orderDate,
        numeroTelefono: o.billing?.phone || '',
        currency: o.currency || 'USD',
        payment_method: o.payment_method || '',
      }

      const orderPayload: any = {
        id_woo: o.id,
        pedido_nombre: `Order #${o.id}`,
        nombre_cliente: customerName,
        email_cliente: o.billing?.email || null,
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

      const { data: upsertedOrder, error: orderErr } = await supabase
        .from('pedidos')
        .upsert([orderPayload], { onConflict: 'id_woo' })
        .select('id')
        .maybeSingle()

      if (orderErr || !upsertedOrder) {
        throw new Error(`Error guardando pedido #${o.id}: ${orderErr?.message}`)
      }

      const dbOrderId = upsertedOrder.id
      const lineItems = o.line_items || []
      const isPaidOrActive = mappedStatus === 'completado' || mappedStatus === 'procesando' || mappedStatus === 'en_espera' || mappedStatus === 'pendiente'

      const { data: existingLogs } = await supabase
        .from('inventory_logs')
        .select('notas')
        .like('notas', `%Venta Woo #${o.id}%`)

      const existingLogNotes = new Set((existingLogs || []).map((l: any) => l.notas))
      let movementsCreated = 0

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

          const uniqueNoteKey = `Venta Woo #${o.id} - Item #${item.id}`
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

              log(`📉 Stock descontado en tiempo real para ${matchedProduct.nombre}: ${currentStock} -> ${newStock}`)
            } else {
              log(`⚠️ Error insertando inventory_log para item #${item.id}: ${logErr.message}`)
            }
          }
        }
      }

      const durationMs = Date.now() - startTime
      log(`🏁 Webhook procesado en ${durationMs}ms para Pedido #${o.id}`)
      return new Response(
        JSON.stringify({
          success: true,
          type: 'webhook_order',
          order_id: o.id,
          pedido_id: dbOrderId,
          status: mappedStatus,
          movements_created: movementsCreated,
          duration_ms: durationMs,
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      )
    }

    // 0.3 Webhook de Producto en tiempo real (product.created / product.updated)
    if (topic.startsWith('product.') || resource === 'product' || (body && body.id && body.name && body.price !== undefined && !body.target)) {
      const p = body
      log(`⚡ Procesando Webhook en Tiempo Real para Producto #${p.id} (${p.name})...`)

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

      const durationMs = Date.now() - startTime
      log(`🏁 Webhook procesado en ${durationMs}ms para Producto #${p.id}`)
      return new Response(
        JSON.stringify({
          success: true,
          type: 'webhook_product',
          product_id: p.id,
          duration_ms: durationMs,
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      )
    }

    let target = body?.target || 'all' // 'all', 'categories', 'products', 'orders'

    log(`🚀 Iniciando sincronización de WooCommerce (Target: ${target})...`)

    const resultSummary: Record<string, any> = {
      categories_synced: 0,
      products_synced: 0,
      variations_synced: 0,
      orders_synced: 0,
    }

    // ==========================================
    // 1. SINCRONIZACIÓN DE CATEGORÍAS
    // ==========================================
    if (target === 'all' || target === 'categories') {
      log('📂 Sincronizando categorías desde WooCommerce...')
      const catRes = await fetch(`${wooBaseUrl}/products/categories?per_page=100&hide_empty=false`, {
        headers: wooHeaders,
      })

      if (!catRes.ok) {
        log(`❌ Error al consultar categorías de WooCommerce: ${catRes.statusText}`)
      } else {
        const categories: any[] = await catRes.json()
        log(`Total categorías recibidas: ${categories.length}`)

        // 1.0 Obtener fotos y descripciones existentes en la base de datos para no sobreescribir con null
        const { data: existingCategories } = await supabase
          .from('categorias')
          .select('id_woo, photo_path, descripcion')

        const existingPhotoMap = new Map<number, string>()
        const existingDescMap = new Map<number, string>()
        if (existingCategories) {
          existingCategories.forEach((c: any) => {
            if (c.id_woo) {
              if (c.photo_path) existingPhotoMap.set(c.id_woo, c.photo_path)
              if (c.descripcion) existingDescMap.set(c.id_woo, c.descripcion)
            }
          })
        }

        // 1.1 Mapear categorías preservando fotos personalizadas si Woo no tiene
        const categoriesToUpsert = categories.map((cat) => {
          const wooPhoto = (cat.image?.src && typeof cat.image.src === 'string' && cat.image.src.trim() !== '') ? cat.image.src : null
          const photoToSave = wooPhoto || existingPhotoMap.get(cat.id) || null
          const descToSave = (cat.description && cat.description.trim() !== '') ? cat.description : (existingDescMap.get(cat.id) || null)

          return {
            id_woo: cat.id,
            nombre: cat.name,
            photo_path: photoToSave,
            slug: cat.slug || null,
            descripcion: descToSave,
          }
        })

        if (categoriesToUpsert.length > 0) {
          const { error: upsertCatErr } = await supabase
            .from('categorias')
            .upsert(categoriesToUpsert, { onConflict: 'id_woo' })

          if (upsertCatErr) {
            log(`⚠️ Error en upsert de categorías: ${upsertCatErr.message}`)
          } else {
            resultSummary.categories_synced = categoriesToUpsert.length
            log(`✅ ${categoriesToUpsert.length} categorías upserted correctamente (imágenes preservadas).`)
          }

          // 1.2 Resolver parent_id nativos de Supabase
          const { data: allDbCats } = await supabase
            .from('categorias')
            .select('id, id_woo, parent_id')

          if (allDbCats) {
            const wooToNativeMap = new Map<number, string>()
            allDbCats.forEach((c: any) => {
              if (c.id_woo) wooToNativeMap.set(c.id_woo, c.id)
            })

            const parentUpdates = []
            for (const cat of categories) {
              if (cat.parent && cat.parent > 0) {
                const nativeParentId = wooToNativeMap.get(cat.parent)
                if (nativeParentId) {
                  parentUpdates.push({
                    id_woo: cat.id,
                    parent_id: nativeParentId,
                  })
                }
              }
            }

            if (parentUpdates.length > 0) {
              await supabase
                .from('categorias')
                .upsert(parentUpdates, { onConflict: 'id_woo' })
              log(`✅ ${parentUpdates.length} jerarquías padre-hijo actualizadas.`)
            }
          }
        }
      }
    }

    // ==========================================
    // 2. SINCRONIZACIÓN DE PRODUCTOS Y VARIACIONES
    // ==========================================
    if (target === 'all' || target === 'products') {
      log('📦 Sincronizando productos desde WooCommerce...')
      
      // Obtener imágenes y descripciones existentes en la base de datos para preservarlas si Woo viene vacío
      const { data: existingProducts } = await supabase
        .from('productos')
        .select('id_woo, image_path, descripcion')

      const existingProdImgMap = new Map<number, string[]>()
      const existingProdDescMap = new Map<number, string>()
      if (existingProducts) {
        existingProducts.forEach((p: any) => {
          if (p.id_woo) {
            if (Array.isArray(p.image_path) && p.image_path.length > 0) {
              existingProdImgMap.set(p.id_woo, p.image_path)
            }
            if (p.descripcion) existingProdDescMap.set(p.id_woo, p.descripcion)
          }
        })
      }

      let page = 1
      let hasMore = true
      let totalProducts = 0
      let totalVariations = 0

      while (hasMore) {
        log(`Consultando página ${page} de productos...`)
        const prodRes = await fetch(`${wooBaseUrl}/products?per_page=100&page=${page}&status=publish`, {
          headers: wooHeaders,
        })

        if (!prodRes.ok) {
          log(`❌ Error al obtener productos en página ${page}: ${prodRes.statusText}`)
          break
        }

        const products: any[] = await prodRes.json()
        if (!products || products.length === 0) {
          log(`ℹ️ No hay más productos en página ${page}.`)
          break
        }

        const batchProductsToUpsert: any[] = []

        for (const p of products) {
          const catIds = (p.categories || []).map((c: any) => c.id)
          const wooImgUrls = (p.images || []).map((img: any) => img.src).filter((url: any) => Boolean(url))
          const existingImgs = existingProdImgMap.get(p.id) || []
          const finalImgUrls = wooImgUrls.length > 0 ? wooImgUrls : existingImgs
          
          const wooDesc = p.description || p.short_description || ''
          const finalDesc = (wooDesc && wooDesc.trim() !== '') ? wooDesc : (existingProdDescMap.get(p.id) || '')
          
          const price = parseFloat(p.price || p.regular_price || '0') || 0
          const stock = typeof p.stock_quantity === 'number' ? p.stock_quantity : (p.in_stock ? 10 : 0)

          batchProductsToUpsert.push({
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
          })
          totalProducts++

          // Si es producto variable, consultar sus variaciones
          if (p.type === 'variable') {
            try {
              const varRes = await fetch(`${wooBaseUrl}/products/${p.id}/variations?per_page=100`, {
                headers: wooHeaders,
              })
              if (varRes.ok) {
                const variations: any[] = await varRes.json()
                for (const v of variations) {
                  const varPrice = parseFloat(v.price || v.regular_price || p.price || '0') || 0
                  const varStock = typeof v.stock_quantity === 'number' ? v.stock_quantity : (v.in_stock ? 10 : 0)
                  
                  const wooVarImg = v.image?.src && typeof v.image.src === 'string' && v.image.src.trim() !== '' ? [v.image.src] : null
                  const existingVarImgs = existingProdImgMap.get(v.id) || []
                  const varImages = wooVarImg || (finalImgUrls.length > 0 ? finalImgUrls : existingVarImgs)

                  const varDesc = v.description || finalDesc

                  batchProductsToUpsert.push({
                    id_woo: v.id,
                    nombre: `${p.name} - ${(v.attributes || []).map((a: any) => a.option).join(' / ')}`.trim(),
                    descripcion: varDesc,
                    precio: varPrice,
                    stock: varStock,
                    image_path: varImages,
                    categoria_id_woo: catIds,
                    sku: v.sku || null,
                    parent_id_woo: p.id,
                    es_variacion: true,
                    es_variable: false,
                    atributos: v.attributes || [],
                  })
                  totalVariations++
                }
              }
            } catch (varErr: any) {
              log(`⚠️ Error descargando variaciones para producto ${p.id}: ${varErr.message}`)
            }
          }
        }

        // Upsert por lotes en Supabase
        if (batchProductsToUpsert.length > 0) {
          const chunkSize = 50
          for (let i = 0; i < batchProductsToUpsert.length; i += chunkSize) {
            const chunk = batchProductsToUpsert.slice(i, i + chunkSize)
            const { error: prodUpsertErr } = await supabase
              .from('productos')
              .upsert(chunk, { onConflict: 'id_woo' })

            if (prodUpsertErr) {
              log(`⚠️ Error en upsert de productos lote ${i}: ${prodUpsertErr.message}`)
            }
          }
        }

        const totalPagesHeader = prodRes.headers.get('x-wp-totalpages')
        const totalPages = totalPagesHeader ? parseInt(totalPagesHeader, 10) : 1

        if (page >= totalPages) {
          hasMore = false
        } else {
          page++
        }
      }

      resultSummary.products_synced = totalProducts
      resultSummary.variations_synced = totalVariations
      log(`✅ Total productos: ${totalProducts}, Variaciones: ${totalVariations}`)
    }

    // ==========================================
    // 3. SINCRONIZACIÓN DE PEDIDOS Y MOVIMIENTOS
    // ==========================================
    if (target === 'all' || target === 'orders') {
      log('🛒 Sincronizando pedidos desde WooCommerce...')
      
      const SYSTEM_USER_ID = 'eb76cd8e-3803-4727-86c1-a2dc921f199a'

      // 3.1 Cargar usuarios registrados para asociar pedidos por email
      const { data: dbUsers } = await supabase.from('usuarios').select('id, email')
      const userMap = new Map<string, string>()
      if (dbUsers) {
        dbUsers.forEach((u: any) => {
          if (u.email) userMap.set(u.email.toLowerCase().trim(), u.id)
        })
      }

      // 3.2 Cargar productos de la base de datos para mapear line_items y stock
      const { data: dbProducts } = await supabase.from('productos').select('id, id_woo, stock, nombre')
      const prodMap = new Map<number, { id: string; stock: number; nombre: string }>()
      if (dbProducts) {
        dbProducts.forEach((p: any) => {
          if (p.id_woo) {
            prodMap.set(p.id_woo, {
              id: p.id,
              stock: typeof p.stock === 'number' ? p.stock : 0,
              nombre: p.nombre || '',
            })
          }
        })
      }

      // 3.3 Cargar notas de inventory_logs para evitar duplicar movimientos
      const { data: existingLogs } = await supabase.from('inventory_logs').select('notas')
      const existingLogNotes = new Set<string>()
      if (existingLogs) {
        existingLogs.forEach((l: any) => {
          if (l.notas) existingLogNotes.add(l.notas)
        })
      }

      // 3.4 Cargar pedidos existentes para buscar por pedido_nombre
      const { data: existingDbOrders } = await supabase
        .from('pedidos')
        .select('id, pedido_nombre, status')

      const existingOrdersMap = new Map<string, { id: string; status: string }>()
      if (existingDbOrders) {
        existingDbOrders.forEach((o: any) => {
          if (o.pedido_nombre) {
            existingOrdersMap.set(o.pedido_nombre.trim(), { id: o.id, status: o.status })
          }
        })
      }

      // 3.5 Cargar items existentes para no duplicar en pedido_items
      const { data: allExistingItems } = await supabase
        .from('pedido_items')
        .select('pedido_id, product_id')

      const existingItemsSet = new Set<string>()
      if (allExistingItems) {
        allExistingItems.forEach((it: any) => {
          if (it.pedido_id && it.product_id) {
            existingItemsSet.add(`${it.pedido_id}_${it.product_id}`)
          }
        })
      }

      let orderPage = 1
      let hasMoreOrders = true
      let totalOrders = 0
      let movementsCreated = 0

      const itemsToInsert: any[] = []
      const logsToInsert: any[] = []
      const updatedStockMap = new Map<string, number>()

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

      while (hasMoreOrders) {
        log(`Consultando página ${orderPage} de pedidos en WooCommerce...`)
        const ordersRes = await fetch(`${wooBaseUrl}/orders?per_page=100&page=${orderPage}`, {
          headers: wooHeaders,
        })

        if (!ordersRes.ok) {
          log(`❌ Error al obtener pedidos en página ${orderPage}: ${ordersRes.statusText}`)
          break
        }

        const orders: any[] = await ordersRes.json()
        if (!orders || orders.length === 0) {
          log(`ℹ️ No hay más pedidos en página ${orderPage}.`)
          break
        }

        const pageOrderPayloads: any[] = []
        const orderMetaMap = new Map<number, { order: any, customerName: string, mappedStatus: string, orderDate: string, assignedUserId: string | null }>()

        for (const o of orders) {
          const clientEmail = o.billing?.email?.toLowerCase()?.trim() || ''
          const customerName = `${o.billing?.first_name || 'Cliente'} ${o.billing?.last_name || ''}`.trim()
          const assignedUserId = userMap.get(clientEmail) || null
          const mappedStatus = mapWooStatus(o.status)
          const totalPrice = parseFloat(o.total || '0') || 0
          const taxPrice = parseFloat(o.total_tax || '0') || 0
          const orderDate = parseWooDate(o.date_created_gmt, o.date_created)

          const shippingInfo = o.shipping?.address_1 
            ? `${o.shipping.first_name || ''} ${o.shipping.last_name || ''} - ${o.shipping.address_1}, ${o.shipping.city || ''} (${o.shipping.phone || o.billing?.phone || ''})`.trim()
            : (o.billing?.address_1 ? `${o.billing.first_name || ''} ${o.billing.last_name || ''} - ${o.billing.address_1}, ${o.billing.city || ''} (${o.billing.phone || ''})`.trim() : 'Entrega en tienda / Sin dirección')

          const paymentInfo = {
            tipo: o.payment_method_title || o.payment_method || 'WooCommerce',
            email: o.billing?.email || '',
            nombre: customerName,
            referencia: o.transaction_id || `WooCommerce #${o.id}`,
            fecha_registro: orderDate,
            numeroTelefono: o.billing?.phone || '',
            currency: o.currency || 'USD',
            payment_method: o.payment_method || '',
          }

          const isPaid = mappedStatus === 'completado' || mappedStatus === 'procesando'

          const orderPayload: any = {
            id_woo: o.id,
            pedido_nombre: `Order #${o.id}`,
            nombre_cliente: customerName,
            email_cliente: o.billing?.email || null,
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

          pageOrderPayloads.push(orderPayload)
          orderMetaMap.set(o.id, { order: o, customerName, mappedStatus, orderDate, assignedUserId })
        }

        // Batch upsert orders for this page
        const { data: upsertedOrders, error: upsertErr } = await supabase
          .from('pedidos')
          .upsert(pageOrderPayloads, { onConflict: 'id_woo' })
          .select('id, id_woo')

        if (upsertErr) {
          log(`⚠️ Error upserting orders page ${orderPage}: ${upsertErr.message}`)
          continue
        }

        const dbOrderMap = new Map<number, string>()
        for (const uo of (upsertedOrders || [])) {
          if (uo.id_woo && uo.id) {
            dbOrderMap.set(uo.id_woo, uo.id)
          }
        }
        totalOrders += (upsertedOrders || []).length

        for (const [wooId, meta] of orderMetaMap.entries()) {
          const dbOrderId = dbOrderMap.get(wooId)
          if (!dbOrderId) continue

          const { order: o, customerName, mappedStatus, orderDate, assignedUserId } = meta
          const lineItems = o.line_items || []
          const isPaidOrActive = mappedStatus === 'completado' || mappedStatus === 'procesando' || mappedStatus === 'en_espera' || mappedStatus === 'pendiente'

          // 3.6 Procesar line items y movimientos de inventario en lote
          for (const item of lineItems) {
            const targetWooId = (item.variation_id && item.variation_id > 0) ? item.variation_id : item.product_id
            const matchedProduct = prodMap.get(targetWooId) || (item.product_id ? prodMap.get(item.product_id) : undefined)

            if (matchedProduct) {
              const itemPrice = parseFloat(item.price || item.total || '0') || 0
              const itemQty = item.quantity || 1
              const itemKey = `${dbOrderId}_${matchedProduct.id}`

              if (!existingItemsSet.has(itemKey)) {
                itemsToInsert.push({
                  pedido_id: dbOrderId,
                  product_id: matchedProduct.id,
                  quantity: itemQty,
                  price_at_purchase: itemPrice,
                })
                existingItemsSet.add(itemKey)
              }

              // Registrar movimiento en inventory_logs y descontar stock
              const uniqueNoteKey = `Venta Woo #${o.id} - Item #${item.id}`
              if (isPaidOrActive && !existingLogNotes.has(uniqueNoteKey)) {
                const logEntry: any = {
                  producto_id: matchedProduct.id,
                  cantidad: -itemQty,
                  tipo_operacion: 'venta_woo',
                  notas: `${uniqueNoteKey} (${customerName} - ${matchedProduct.nombre})`,
                  created_at: orderDate,
                }

                if (assignedUserId) {
                  logEntry.usuario_id = assignedUserId
                }

                logsToInsert.push(logEntry)

                existingLogNotes.add(uniqueNoteKey)
                movementsCreated++

                const currentStock = updatedStockMap.has(matchedProduct.id) 
                  ? updatedStockMap.get(matchedProduct.id)! 
                  : matchedProduct.stock

                const newStock = Math.max(0, currentStock - itemQty)
                updatedStockMap.set(matchedProduct.id, newStock)
                matchedProduct.stock = newStock
              }
            }
          }
        }

        const totalPagesHeader = ordersRes.headers.get('x-wp-totalpages')
        const totalPages = totalPagesHeader ? parseInt(totalPagesHeader, 10) : 1

        if (orderPage >= totalPages || orders.length < 100) {
          hasMoreOrders = false
        } else {
          orderPage++
        }
      }

      // Guardar items de pedido en bloque
      if (itemsToInsert.length > 0) {
        log(`Guardando ${itemsToInsert.length} items de pedido...`)
        const chunkSize = 100
        for (let i = 0; i < itemsToInsert.length; i += chunkSize) {
          const chunk = itemsToInsert.slice(i, i + chunkSize)
          await supabase.from('pedido_items').insert(chunk)
        }
      }

      // Guardar logs de movimientos en bloque
      if (logsToInsert.length > 0) {
        log(`Registrando ${logsToInsert.length} movimientos de inventario...`)
        const chunkSize = 100
        for (let i = 0; i < logsToInsert.length; i += chunkSize) {
          const chunk = logsToInsert.slice(i, i + chunkSize)
          await supabase.from('inventory_logs').insert(chunk)
        }
      }

      // Actualizar stocks en productos
      if (updatedStockMap.size > 0) {
        log(`Actualizando stock de ${updatedStockMap.size} productos/variaciones afectados...`)
        for (const [prodId, newStock] of updatedStockMap.entries()) {
          await supabase.from('productos').update({ stock: newStock }).eq('id', prodId)
        }
      }

      resultSummary.orders_synced = totalOrders
      resultSummary.movements_created = movementsCreated
      log(`✅ Total pedidos: ${totalOrders}, Movimientos de inventario generados: ${movementsCreated}`)
    }

    const durationSecs = ((Date.now() - startTime) / 1000).toFixed(2)
    log(`🏁 Sincronización finalizada en ${durationSecs}s`)

    return new Response(
      JSON.stringify({
        success: true,
        duration_seconds: parseFloat(durationSecs),
        summary: resultSummary,
        logs: logs,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )
  } catch (err: any) {
    log(`🔥 Error fatal en sync-woocommerce: ${err.message}`)
    return new Response(
      JSON.stringify({
        success: false,
        error: err.message,
        logs: logs,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    )
  }
})
