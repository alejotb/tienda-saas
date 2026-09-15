import 'dart:typed_data';
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
    try {
      final user = SupaFlow.client.auth.currentUser;
      if (user == null) {
        throw Exception('El usuario debe estar autenticado para registrar una tienda');
      }

      // 1. Insertar la tienda en Supabase
      final response = await SupaFlow.client.from('tiendas').insert({
        'dueno_id': user.id,
        'nombre': nombreStore,
        'slug': slug.toLowerCase().trim(),
        'logo_url': logoUrl,
        'banner_url': bannerUrl,
        'color_primario': colorPrimarioHex,
        'color_secundario': colorSecundarioHex,
        'telefono_contacto': telefonoContacto,
        'email_contacto': emailContacto ?? user.email,
        'direccion_fisica': direccionFisica,
        'moneda_principal': monedaPrincipal,
        'activa': true,
        'plan': 'free',
      }).select().single();

      final store = StoreData.fromMap(response);

      // 2. Actualizar metadatos y perfil del usuario en la tabla 'usuarios'
      await SupaFlow.client.from('usuarios').upsert({
        'id': user.id,
        'email': user.email ?? '',
        'nombre_completo': user.userMetadata?['full_name'] ?? 'Dueño de Tienda',
        'rol': 'dueno_tienda',
        'tienda_id': store.id,
      });

      return store;
    } catch (e) {
      debugPrint('Error al registrar la tienda: $e');
      return null;
    }
  }

  /// Consulta si un slug ya existe para evitar duplicados
  Future<bool> checkSlugExists(String slug) async {
    try {
      final cleanSlug = slug.toLowerCase().trim();
      final res = await SupaFlow.client
          .from('tiendas')
          .select('id')
          .eq('slug', cleanSlug)
          .maybeSingle();

      return res != null;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene los datos de la tienda asociada al usuario actual
  Future<StoreData?> getMyStore() async {
    try {
      final user = SupaFlow.client.auth.currentUser;
      if (user == null) return null;

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
}
