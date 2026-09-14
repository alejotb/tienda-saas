import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const SYSTEM_USER_ID = 'eb76cd8e-3803-4727-86c1-a2dc921f199a'; // <--- PONÉ ACÁ EL UUID

serve(async (req) => {
  try {
    // 1. Validar el request
    const { user_id } = await req.json();
    if (!user_id) throw new Error('Falta el user_id');

    // 2. Crear cliente con SERVICE_ROLE_KEY (la Llave Maestra)
    // Las variables de entorno ya están configuradas en Supabase por defecto
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    console.log(`Iniciando proceso de eliminación para: ${user_id}`);

    // 3. PRESERVAR: Mover pedidos pagados/apartados al Usuario Sistema
    const { error: updateError } = await supabaseAdmin
      .from('pedidos')
      .update({ user_id: SYSTEM_USER_ID })
      .eq('user_id', user_id)
      .neq('status', 'carrito');

    if (updateError) throw updateError;

    // 4. LIMPIAR: Borrar pedidos que sean solo carritos
    const { error: deleteCartError } = await supabaseAdmin
      .from('pedidos')
      .delete()
      .eq('user_id', user_id)
      .eq('status', 'carrito');

    if (deleteCartError) throw deleteCartError;

    // 5. BORRAR PERFIL: Eliminar de la tabla public.usuarios
    const { error: deleteProfileError } = await supabaseAdmin
      .from('usuarios')
      .delete()
      .eq('id', user_id);

    if (deleteProfileError) throw deleteProfileError;

    // 6. BORRAR CUENTA: Eliminar de auth.users (requiere admin)
    const { error: deleteAuthError } = await supabaseAdmin.auth.admin.deleteUser(user_id);

    if (deleteAuthError) throw deleteAuthError;

    return new Response(
      JSON.stringify({ message: 'Usuario eliminado y datos preservados correctamente' }),
      { headers: { 'Content-Type': 'application/json' }, status: 200 }
    );

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { 'Content-Type': 'application/json' }, status: 400 }
    );
  }
})