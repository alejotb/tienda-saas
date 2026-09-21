import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/services/store_service.dart';
import 'package:baul_pandora/services/store_theme_service.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/auth/supabase_auth/auth_util.dart';
import 'package:baul_pandora/auth/supabase_auth/supabase_user_provider.dart';
import 'package:baul_pandora/components/otp_verification_dialog.dart';
import 'package:baul_pandora/pages/store_register/store_register_model.dart';
export 'package:baul_pandora/pages/store_register/store_register_model.dart';

class StoreRegisterWidget extends StatefulWidget {
  const StoreRegisterWidget({super.key});

  static String routeName = 'storeRegister';
  static String routePath = '/storeRegister';

  @override
  State<StoreRegisterWidget> createState() => _StoreRegisterWidgetState();
}

class _StoreRegisterWidgetState extends State<StoreRegisterWidget> {
  late StoreRegisterModel _model;
  int _currentStep = 0;
  bool _isLoading = false;
  bool _obscurePassword = true;
  Uint8List? _logoBytes;
  Uint8List? _bannerBytes;
  String? _logoFileName;
  String? _bannerFileName;

  final List<String> _presetColors = [
    '#6366F1', // Indigo
    '#3B82F6', // Blue
    '#10B981', // Emerald/Green
    '#F59E0B', // Amber
    '#EF4444', // Red
    '#8B5CF6', // Purple
    '#EC4899', // Pink
    '#0F172A', // Slate Dark
  ];

  @override
  void initState() {
    super.initState();
    _model = StoreRegisterModel();
    if (loggedIn) {
      _model.emailController.text = currentUserEmail;
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isLogo) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        if (isLogo) {
          _logoBytes = bytes;
          _logoFileName = image.name;
        } else {
          _bannerBytes = bytes;
          _bannerFileName = image.name;
        }
      });
    }
  }

  void _onStoreNameChanged(String val) {
    final slug = val
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-');
    _model.slugController.text = slug;
  }

  Future<void> _submitRegistration() async {
    setState(() => _isLoading = true);

    try {
      // 1. Validar si el slug ya está en uso
      final slug = _model.slugController.text.trim().toLowerCase();
      final slugExists = await StoreService.instance.checkSlugExists(slug);
      if (slugExists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El identificador (slug) ya está registrado por otra tienda. Elige otro.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // 2. Si el usuario no está autenticado, crear su cuenta de usuario en Supabase Auth
      if (!loggedIn) {
        final email = _model.emailController.text.trim();
        final password = _model.passwordController.text;
        final name = _model.nameController.text.trim();

        try {
          final res = await SupaFlow.client.auth.signUp(
            email: email,
            password: password,
            data: {
              if (name.isNotEmpty) 'display_name': name,
            },
          );

          if (res.session != null && res.user != null) {
            final authUser = BaulPandoraSupabaseUser(res.user!);
            currentUser = authUser;
            await AppStateNotifier.instance.update(authUser);
          } else {
            // Supabase requiere verificación de correo vía código OTP de 6 dígitos
            if (mounted) {
              final verified = await OtpVerificationDialog.show(
                context,
                email: email,
                title: 'Confirma tu correo',
                subtitle:
                    'Ingresa el código de 6 dígitos que enviamos a:\n$email para verificar tu cuenta y registrar tu tienda.',
              );

              if (!verified || !loggedIn) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Debes ingresar el código de verificación para completar el registro.'),
                      backgroundColor: Colors.amber,
                    ),
                  );
                }
                setState(() => _isLoading = false);
                return;
              }
            }
          }
        } on AuthException catch (e) {
          // Si el usuario ya está registrado, intentar iniciar sesión
          final isAlreadyRegistered =
              e.message.toLowerCase().contains('already registered') ||
                  e.message.toLowerCase().contains('ya registrado');

          if (isAlreadyRegistered) {
            try {
              final signInRes = await SupaFlow.client.auth.signInWithPassword(
                email: email,
                password: password,
              );
              if (signInRes.user != null) {
                final authUser = BaulPandoraSupabaseUser(signInRes.user!);
                currentUser = authUser;
                await AppStateNotifier.instance.update(authUser);
              }
            } on AuthException catch (signInErr) {
              final isUnconfirmed =
                  signInErr.message.toLowerCase().contains('not confirmed') ||
                      signInErr.message.toLowerCase().contains('no confirmado');

              if (isUnconfirmed) {
                try {
                  await SupaFlow.client.auth.resend(
                    type: OtpType.signup,
                    email: email,
                  );
                } catch (_) {}

                if (mounted) {
                  final verified = await OtpVerificationDialog.show(
                    context,
                    email: email,
                    title: 'Confirma tu correo',
                    subtitle:
                        'Tu cuenta aún no está confirmada. Ingresa el código de 6 dígitos enviado a:\n$email',
                  );

                  if (!verified || !loggedIn) {
                    setState(() => _isLoading = false);
                    return;
                  }
                }
              } else {
                rethrow;
              }
            }
          } else {
            rethrow;
          }
        }

        if (!loggedIn) {
          throw Exception('No se pudo verificar la cuenta. Intenta nuevamente.');
        }

        // Actualizar nombre en la tabla usuarios si está disponible
        if (name.isNotEmpty && currentUserUid.isNotEmpty) {
          try {
            await SupaFlow.client.from('usuarios').upsert({
              'id': currentUserUid,
              'email': email,
              'display_name': name,
              'is_admin': true,
            });
          } catch (_) {}
        }
      }

      // 3. Subir logo y banner a Supabase Storage si se seleccionaron
      String? logoUrl;
      String? bannerUrl;

      if (_logoBytes != null && _logoFileName != null) {
        logoUrl = await StoreService.instance.uploadBrandingFile(
          fileBytes: _logoBytes!,
          fileName: _logoFileName!,
          storeSlug: slug,
          fileType: 'logo',
        );
      }

      if (_bannerBytes != null && _bannerFileName != null) {
        bannerUrl = await StoreService.instance.uploadBrandingFile(
          fileBytes: _bannerBytes!,
          fileName: _bannerFileName!,
          storeSlug: slug,
          fileType: 'banner',
        );
      }

      // 4. Registrar la tienda en la base de datos de Supabase
      final store = await StoreService.instance.registerStore(
        nombreStore: _model.storeNameController.text.trim(),
        slug: slug,
        logoUrl: logoUrl,
        bannerUrl: bannerUrl,
        colorPrimarioHex: _model.primaryColorHex,
        colorSecundarioHex: _model.secondaryColorHex,
        telefonoContacto: _model.phoneController.text.trim(),
      );

      if (store != null) {
        StoreThemeService.instance.setStore(store);
        FFAppState().activeStoreId = store.id;
        FFAppState().activeStoreSlug = store.slug;
        FFAppState().isAdmin = true;

        if (mounted) {
          setState(() {
            _currentStep = 3; // Mostrar pantalla final de éxito
          });
        }
      } else {
        throw Exception('No se pudo guardar la tienda en la base de datos');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error registrando tienda: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.secondaryBackground,
        elevation: 1,
        title: Text(
          'Crear Nueva Tienda',
          style: theme.titleLarge.override(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Indicador de Progreso
                _buildProgressHeader(theme),
                const SizedBox(height: 32),

                // Pasos del Wizard
                if (_currentStep == 0) _buildStepAccount(theme),
                if (_currentStep == 1) _buildStepStoreInfo(theme),
                if (_currentStep == 2) _buildStepBranding(theme),
                if (_currentStep == 3) _buildStepSuccess(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader(FlutterFlowTheme theme) {
    return Row(
      children: [
        _buildStepDot(theme, 0, 'Cuenta'),
        _buildStepLine(theme, 0),
        _buildStepDot(theme, 1, 'Negocio'),
        _buildStepLine(theme, 1),
        _buildStepDot(theme, 2, 'Branding'),
        _buildStepLine(theme, 2),
        _buildStepDot(theme, 3, '¡Listo!'),
      ],
    );
  }

  Widget _buildStepDot(FlutterFlowTheme theme, int stepIndex, String label) {
    final isDone = _currentStep > stepIndex;
    final isCurrent = _currentStep == stepIndex;

    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: isDone || isCurrent ? theme.primary : theme.alternate,
          child: isDone
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Text(
                  '${stepIndex + 1}',
                  style: TextStyle(
                    color: isCurrent ? Colors.white : theme.secondaryText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.bodySmall.override(
            fontFamily: 'Inter',
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(FlutterFlowTheme theme, int stepIndex) {
    return Expanded(
      child: Container(
        height: 2,
        color: _currentStep > stepIndex ? theme.primary : theme.alternate,
      ),
    );
  }

  // --- PASO 0: Crear Cuenta de Usuario / Iniciar Sesión ---
  Widget _buildStepAccount(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paso 1: Datos de tu Cuenta',
          style: theme.headlineSmall.override(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Crea tu cuenta de administrador para gestionar tus productos, pedidos y pagos.',
          style: theme.bodyMedium,
        ),
        const SizedBox(height: 24),

        if (loggedIn) ...[
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: theme.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.account_circle, color: theme.primary, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sesión activa como:',
                        style: TextStyle(fontSize: 12, color: theme.secondaryText),
                      ),
                      Text(
                        currentUserEmail,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await authManager.signOut();
                    setState(() {});
                  },
                  child: const Text('Cambiar cuenta'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ] else ...[
          TextField(
            controller: _model.nameController,
            decoration: InputDecoration(
              labelText: 'Nombre Completo / Razón Social',
              hintText: 'Ej. Juan Pérez',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _model.emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Correo Electrónico',
              hintText: 'tu@correo.com',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _model.passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Contraseña de Acceso (mínimo 6 caracteres)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (!loggedIn) {
                final name = _model.nameController.text.trim();
                final email = _model.emailController.text.trim();
                final password = _model.passwordController.text;

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor ingresa tu nombre completo')),
                  );
                  return;
                }
                if (email.isEmpty || !email.contains('@')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor ingresa un correo electrónico válido')),
                  );
                  return;
                }
                if (password.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres')),
                  );
                  return;
                }
              }
              setState(() => _currentStep = 1);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: theme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Continuar a Datos del Negocio ->',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  // --- PASO 1: Datos del Negocio / Tienda ---
  Widget _buildStepStoreInfo(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paso 2: Información del Negocio',
          style: theme.headlineSmall.override(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Define el nombre comercial y el enlace personalizado de tu catálogo online.',
          style: theme.bodyMedium,
        ),
        const SizedBox(height: 24),

        TextField(
          controller: _model.storeNameController,
          onChanged: _onStoreNameChanged,
          decoration: InputDecoration(
            labelText: 'Nombre de la Tienda (ej. Modas Express)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.storefront_rounded),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _model.slugController,
          decoration: InputDecoration(
            labelText: 'Enlace de la Tienda (Slug / URL)',
            prefixText: 'tuapp.com/',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.link_rounded),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _model.phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Teléfono de Contacto (WhatsApp para pedidos)',
            hintText: '+58 412 1234567',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.phone_rounded),
          ),
        ),
        const SizedBox(height: 32),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep = 0),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Atrás'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (_model.storeNameController.text.trim().isEmpty ||
                      _model.slugController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ingresa el nombre y enlace de tu tienda')),
                    );
                    return;
                  }
                  setState(() => _currentStep = 2);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Continuar a Branding ->',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- PASO 2: Branding e Identidad Visual (Logo, Banner, Colores) ---
  Widget _buildStepBranding(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paso 3: Identidad Visual & Colores',
          style: theme.headlineSmall.override(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Personaliza el logo y los colores distintivos de tu tienda.',
          style: theme.bodyMedium,
        ),
        const SizedBox(height: 24),

        // Subida de Logo
        Text('Logo de la Tienda (Opcional)', style: theme.bodyMedium.override(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickImage(true),
          child: Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.alternate),
            ),
            child: _logoBytes != null
                ? Image.memory(_logoBytes!, fit: BoxFit.contain)
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 36),
                      SizedBox(height: 4),
                      Text('Haz clic para subir el Logo'),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 24),

        // Selector de Color Primario
        Text('Color Principal de la Marca', style: theme.bodyMedium.override(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _presetColors.map((colorHex) {
            final isSelected = _model.primaryColorHex == colorHex;
            final color = Color(int.parse(colorHex.replaceFirst('#', 'ff'), radix: 16));
            return GestureDetector(
              onTap: () => setState(() => _model.primaryColorHex = colorHex),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected ? Border.all(color: Colors.black, width: 3) : null,
                ),
                child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 32),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep = 1),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Atrás'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRegistration,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        '¡Crear Mi Tienda!',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- PASO 3: Éxito y Confirmación ---
  Widget _buildStepSuccess(FlutterFlowTheme theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.check_circle_rounded, size: 80, color: Color(0xFF16A34A)),
            const SizedBox(height: 16),
            Text(
              '¡Tu Tienda ha sido creada!',
              style: theme.headlineMedium.override(
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'La tienda "${_model.storeNameController.text}" está lista. Ya puedes comenzar a subir productos y gestionar pedidos.',
              textAlign: TextAlign.center,
              style: theme.bodyMedium,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                context.goNamed('adminStore');
              },
              icon: const Icon(Icons.dashboard_rounded),
              label: const Text('Ir a mi Panel de Administración'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
