import 'package:flutter/foundation.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';

class StoreData {
  final String id;
  final String duenoId;
  final String nombre;
  final String slug;
  final String? logoUrl;
  final String? bannerUrl;
  final String colorPrimario;
  final String colorSecundario;
  final String? telefonoContacto;
  final String? emailContacto;
  final String? direccionFisica;
  final String monedaPrincipal;
  final bool activa;
  final String plan;
  final bool permiteInvitados;
  final String? dominioPersonalizado;
  final String estadoDominio; // 'sin_configurar', 'pendiente', 'conectado'

  StoreData({
    required this.id,
    required this.duenoId,
    required this.nombre,
    required this.slug,
    this.logoUrl,
    this.bannerUrl,
    required this.colorPrimario,
    required this.colorSecundario,
    this.telefonoContacto,
    this.emailContacto,
    this.direccionFisica,
    required this.monedaPrincipal,
    required this.activa,
    required this.plan,
    this.permiteInvitados = true,
    this.dominioPersonalizado,
    this.estadoDominio = 'sin_configurar',
  });

  factory StoreData.fromMap(Map<String, dynamic> map) {
    return StoreData(
      id: map['id']?.toString() ?? '',
      duenoId: map['dueno_id']?.toString() ?? '',
      nombre: map['nombre']?.toString() ?? 'Sin nombre',
      slug: map['slug']?.toString() ?? '',
      logoUrl: map['logo_url']?.toString(),
      bannerUrl: map['banner_url']?.toString(),
      colorPrimario: map['color_primario']?.toString() ?? '#6366F1',
      colorSecundario: map['color_secundario']?.toString() ?? '#4F46E5',
      telefonoContacto: map['telefono_contacto']?.toString(),
      emailContacto: map['email_contacto']?.toString(),
      direccionFisica: map['direccion_fisica']?.toString(),
      monedaPrincipal: map['moneda_principal']?.toString() ?? 'USD',
      activa: map['activa'] == true,
      plan: map['plan']?.toString() ?? 'free',
      permiteInvitados: map['permite_invitados'] ?? true,
      dominioPersonalizado: map['dominio_personalizado']?.toString(),
      estadoDominio: map['estado_dominio']?.toString() ?? (map['dominio_personalizado'] != null ? 'conectado' : 'sin_configurar'),
    );
  }
}

class StoreService {
  static final StoreService instance = StoreService._internal();
  StoreService._internal();

  /// Sube un archivo de branding (Logo o Banner) a Supabase Storage bucket 'tiendas_branding'
  Future<String?> uploadBrandingFile({
    required Uint8List fileBytes,
    required String fileName,
    required String storeSlug,
    required String fileType, // 'logo' o 'banner'
  }) async {
    try {
      final path = '$storeSlug/${fileType}_${DateTime.now().millisecondsSinceEpoch}_$fileName';
      
      await SupaFlow.client.storage
          .from('tiendas_branding')
          .uploadBinary(path, fileBytes);

      final publicUrl = SupaFlow.client.storage
          .from('tiendas_branding')
          .getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      debugPrint('Error subiendo imagen de branding ($fileType): $e');
      return null;
    }
  }

  /// Crea una nueva tienda y actualiza el usuario como dueño de la misma
  Future<StoreData?> registerStore({
    required String nombreStore,
    required String slug,
    String? logoUrl,
    String? bannerUrl,
    required String colorPrimarioHex,
    required String colorSecundarioHex,
    String? telefonoContacto,
    String? emailContacto,
    String? direccionFisica,
    String monedaPrincipal = 'USD',
  }) async {
    final user = SupaFlow.client.auth.currentUser;
    if (user == null) {
      throw Exception('Debes iniciar sesión para registrar una tienda.');
    }

    final cleanSlug = slug.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\-]'), '').trim();

    final storePayload = {
      'dueno_id': user.id,
      'nombre': nombreStore.trim(),
      'slug': cleanSlug,
      'logo_url': logoUrl,
      'banner_url': bannerUrl,
      'color_primario': colorPrimarioHex,
      'color_secundario': colorSecundarioHex,
      'telefono_contacto': telefonoContacto?.trim(),
      'email_contacto': emailContacto?.trim() ?? user.email,
      'direccion_fisica': direccionFisica?.trim(),
      'moneda_principal': monedaPrincipal,
      'activa': true,
      'plan': 'free',
      'permite_invitados': true,
    };

    final res = await SupaFlow.client
        .from('tiendas')
        .insert(storePayload)
        .select()
        .single();

    final store = StoreData.fromMap(res);

    // Actualizar usuario en tabla usuarios asignando rol y tienda_id si aplica
    try {
      await SupaFlow.client.from('usuarios').update({
        'tienda_id': store.id,
        'rol': 'dueno_tienda',
      }).eq('id', user.id);
    } catch (e) {
      debugPrint('Nota: Actualizando rol de usuario en tabla usuarios: $e');
    }

    return store;
  }

  /// Verifica si un slug de tienda ya está en uso
  Future<bool> isSlugAvailable(String slug) async {
    try {
      final cleanSlug = slug.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\-]'), '').trim();
      final res = await SupaFlow.client
          .from('tiendas')
          .select('id')
          .eq('slug', cleanSlug)
          .maybeSingle();

      return res == null;
    } catch (e) {
      debugPrint('Error verificando disponibilidad de slug: $e');
      return false;
    }
  }

  /// Alias para verificar si un slug ya existe (devuelve true si ya existe)
  Future<bool> checkSlugExists(String slug) async {
    final available = await isSlugAvailable(slug);
    return !available;
  }

  /// Obtiene la tienda asociada al usuario actual
  Future<StoreData?> getMyStore() async {
    final user = SupaFlow.client.auth.currentUser;
    if (user == null) return null;

    try {
      final res = await SupaFlow.client
          .from('tiendas')
          .select()
          .eq('dueno_id', user.id)
          .maybeSingle();

      if (res != null) {
        return StoreData.fromMap(res);
      }
      return null;
    } catch (e) {
      debugPrint('Error obteniendo la tienda del usuario: $e');
      return null;
    }
  }

  /// Obtiene una tienda por su slug
  Future<StoreData?> getStoreBySlug(String slug) async {
    try {
      final cleanSlug = slug.toLowerCase().trim();
      final res = await SupaFlow.client
          .from('tiendas')
          .select()
          .eq('slug', cleanSlug)
          .maybeSingle();

      if (res != null) {
        return StoreData.fromMap(res);
      }
      return null;
    } catch (e) {
      debugPrint('Error obteniendo tienda por slug: $e');
      return null;
    }
  }

  /// Obtiene una tienda por su dominio personalizado
  Future<StoreData?> getStoreByDomain(String domain) async {
    try {
      final cleanDomain = domain.toLowerCase().trim();
      final res = await SupaFlow.client
          .from('tiendas')
          .select()
          .eq('dominio_personalizado', cleanDomain)
          .maybeSingle();

      if (res != null) {
        return StoreData.fromMap(res);
      }
      return null;
    } catch (e) {
      debugPrint('Error obteniendo tienda por dominio: $e');
      return null;
    }
  }

  /// Obtiene una tienda por su ID
  Future<StoreData?> getStoreById(String storeId) async {
    try {
      final res = await SupaFlow.client
          .from('tiendas')
          .select()
          .eq('id', storeId)
          .maybeSingle();

      if (res != null) {
        return StoreData.fromMap(res);
      }
      return null;
    } catch (e) {
      debugPrint('Error obteniendo tienda por ID: $e');
      return null;
    }
  }

  /// Actualiza la preferencia del comerciante para permitir o no compras como invitado
  Future<bool> updateGuestSetting(String storeId, bool allowGuests) async {
    try {
      await SupaFlow.client
          .from('tiendas')
          .update({'permite_invitados': allowGuests})
          .eq('id', storeId);
      return true;
    } catch (e) {
      debugPrint('Error al actualizar preferencia de invitados: $e');
      return false;
    }
  }

  /// Actualiza el plan de suscripción de la tienda (Free vs Pro)
  Future<bool> updateStorePlan(String storeId, String newPlan) async {
    try {
      final cleanPlan = newPlan.toLowerCase().trim();
      await SupaFlow.client
          .from('tiendas')
          .update({'plan': cleanPlan})
          .eq('id', storeId);
      return true;
    } catch (e) {
      debugPrint('Error al actualizar plan de la tienda: $e');
      return false;
    }
  }

  /// Configura o elimina el dominio personalizado de una tienda
  Future<bool> updateCustomDomain(
    String storeId,
    String? domain, {
    String status = 'conectado',
  }) async {
    try {
      final cleanDomain = domain?.toLowerCase().replaceAll('https://', '').replaceAll('http://', '').trim();
      final payload = {
        'dominio_personalizado': (cleanDomain != null && cleanDomain.isNotEmpty) ? cleanDomain : null,
        'estado_dominio': (cleanDomain != null && cleanDomain.isNotEmpty) ? status : 'sin_configurar',
      };

      await SupaFlow.client
          .from('tiendas')
          .update(payload)
          .eq('id', storeId);
      return true;
    } catch (e) {
      debugPrint('Error al actualizar dominio personalizado: $e');
      return false;
    }
  }
}
