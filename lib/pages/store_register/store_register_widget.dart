import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_widgets.dart';
import 'package:baul_pandora/services/store_service.dart';
import 'package:baul_pandora/services/store_theme_service.dart';
import 'package:baul_pandora/auth/supabase_auth/auth_util.dart';
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
    // If logged in, skip account creation step or prefill
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
    // Generar slug automático si el usuario no lo ha personalizado manualmente
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
      // 1. Verificar si el slug ya está en uso
      final slugExists = await StoreService.instance.checkSlugExists(_model.slugController.text);
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

      final slug = _model.slugController.text.trim().toLowerCase();

      // 2. Subir logo y banner a Supabase Storage si se seleccionaron
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

      // 3. Registrar la tienda en la base de datos de Supabase
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
        if (mounted) {
          setState(() {
            _currentStep = 3; // Mostrar pantalla final de éxito
          });
        }
      } else {
        throw Exception('No se pudo guardar la tienda');
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
          'Registro de Nueva Tienda',
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
        Text('Paso 1: Datos del Dueño', style: theme.headlineSmall.override(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Crea la cuenta de usuario con la que administrarás tu tienda.', style: theme.bodyMedium),
        const SizedBox(height: 24),

        TextField(
          controller: _model.nameController,
          decoration: InputDecoration(
            labelText: 'Nombre Completo',
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _model.passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Contraseña de Acceso',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.lock_outline),
          ),
        ),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (_model.emailController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa tu correo electrónico')));
                return;
              }
              setState(() => _currentStep = 1);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: theme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Continuar a Datos del Negocio ->', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        Text('Paso 2: Información del Negocio', style: theme.headlineSmall.override(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Define el nombre comercial y el enlace personalizado de tu tienda.', style: theme.bodyMedium),
        const SizedBox(height: 24),

        TextField(
          controller: _model.storeNameController,
          onChanged: _onStoreNameChanged,
          decoration: InputDecoration(
            labelText: 'Nombre de la Tienda (ej. Modas Pandora)',
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
            labelText: 'Teléfono de Contacto (WhatsApp)',
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
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Atrás'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (_model.storeNameController.text.trim().isEmpty || _model.slugController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa el nombre y enlace de tu tienda')));
                    return;
                  }
                  setState(() => _currentStep = 2);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.primary,
                ),
                child: const Text('Continuar a Branding ->', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        Text('Paso 3: Identidad Visual & Colores', style: theme.headlineSmall.override(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Personaliza el logo y la paleta de colores distintiva de tu marca.', style: theme.bodyMedium),
        const SizedBox(height: 24),

        // Subida de Logo
        Text('Logo de la Tienda', style: theme.bodyMedium.override(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickImage(true),
          child: Container(
            height: 100,
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
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
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
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('¡Crear Mi Tienda!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            Text('¡Tu Tienda ha sido creada!', style: theme.headlineMedium.override(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'La tienda "${_model.storeNameController.text}" está lista. Ya puedes subir tus productos y personalizar tus catálogo.',
              textAlign: TextAlign.center,
              style: theme.bodyMedium,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              icon: const Icon(Icons.dashboard_rounded),
              label: const Text('Ir a mi Panel de Administración'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
