import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/services/store_service.dart';
import 'package:baul_pandora/services/store_theme_service.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/auth/supabase_auth/auth_util.dart';
import 'package:baul_pandora/auth/supabase_auth/supabase_user_provider.dart';
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
  bool _isAuthenticatingStep0 = false;
  bool _isExistingAccountMode = false;
  bool _obscurePassword = true;
  Uint8List? _logoBytes;
  Uint8List? _bannerBytes;
  String? _logoFileName;
  String? _bannerFileName;

  // Controlador y timer para el carrusel de imágenes/tiendas en desktop
  late PageController _sliderController;
  int _currentSlideIndex = 0;
  Timer? _sliderTimer;

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
      _currentStep = 1; // Si ya inició sesión, pasar directo a datos del negocio
      _model.emailController.text = currentUserEmail;
    }

    _sliderController = PageController();
    _startSliderTimer();
  }

  void _startSliderTimer() {
    _sliderTimer?.cancel();
    _sliderTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || !_sliderController.hasClients) return;
      final totalSlides = _getSlides(FlutterFlowTheme.of(context)).length;
      final nextIndex = (_currentSlideIndex + 1) % totalSlides;
      _sliderController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _sliderTimer?.cancel();
    _sliderController.dispose();
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

  void _showPlanLimitUpgradeDialog(String message) {
    final theme = FlutterFlowTheme.of(context);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.stars_rounded, color: Colors.purple, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Límite de Tiendas (Plan Free)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: theme.bodyMedium.override(fontFamily: 'Inter', fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.purple, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Plan Pro (\$14.99/mes): Tiendas múltiples ilimitadas, dominio propio y productos sin límite.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.purple),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('Cerrar', style: TextStyle(color: theme.secondaryText)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.goNamed('administracion');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Gestionar mis Tiendas'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleStep0Account() async {
    if (loggedIn) {
      final eligibility = await StoreService.instance.checkStoreCreationEligibility();
      if (!eligibility.canCreate) {
        if (mounted) {
          _showPlanLimitUpgradeDialog(eligibility.message ??
              'Las cuentas con Plan Free están limitadas a un máximo de 2 tiendas. Para crear más tiendas, actualiza al Plan Pro.');
        }
        return;
      }
      setState(() => _currentStep = 1);
      return;
    }

    final email = _model.emailController.text.trim();
    final password = _model.passwordController.text;
    final name = _model.nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa el correo y la contraseña')),
      );
      return;
    }

    if (!_isExistingAccountMode && password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres')),
      );
      return;
    }

    setState(() => _isAuthenticatingStep0 = true);

    try {
      if (_isExistingAccountMode) {
        GoRouter.of(context).prepareAuthEvent();
        final res = await SupaFlow.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        if (res.user != null) {
          final authUser = BaulPandoraSupabaseUser(res.user!);
          currentUser = authUser;
          await AppStateNotifier.instance.update(authUser);
        }
      } else {
        GoRouter.of(context).prepareAuthEvent();
        try {
          final res = await SupaFlow.client.auth.signUp(
            email: email,
            password: password,
            data: {
              'display_name': name,
              'full_name': name,
              'name': name,
              'nombre': name,
            },
          );
          if (res.user != null) {
            final authUser = BaulPandoraSupabaseUser(res.user!);
            currentUser = authUser;
            await AppStateNotifier.instance.update(authUser);
          }
        } on AuthException catch (e) {
          if (e.message.toLowerCase().contains('already registered') ||
              e.message.toLowerCase().contains('user already exists') ||
              e.statusCode == '422') {
            final signInRes = await SupaFlow.client.auth.signInWithPassword(
              email: email,
              password: password,
            );
            if (signInRes.user != null) {
              final authUser = BaulPandoraSupabaseUser(signInRes.user!);
              currentUser = authUser;
              await AppStateNotifier.instance.update(authUser);
            }
          } else if (e.statusCode == '429' || e.message.toLowerCase().contains('rate limit')) {
            throw Exception(
              'Límite de solicitudes de registro en Supabase (Error 429). Si ya creaste tu cuenta, cambia a "Ya tengo cuenta" para iniciar sesión, o espera unos minutos.',
            );
          } else {
            rethrow;
          }
        }
      }

      if (!loggedIn) {
        throw Exception('No se pudo autenticar la cuenta. Verifica que el correo y contraseña sean correctos.');
      }

      // Actualizar nombre en auth.users metadata y asegurar registro en tabla usuarios
      if (currentUserUid.isNotEmpty) {
        if (name.isNotEmpty) {
          try {
            await SupaFlow.client.auth.updateUser(
              UserAttributes(
                data: {
                  'display_name': name,
                  'full_name': name,
                  'name': name,
                  'nombre': name,
                },
              ),
            );
          } catch (e) {
            debugPrint('Error actualizando user metadata en auth: $e');
          }
        }

        try {
          final userPayload = <String, dynamic>{
            'id': currentUserUid,
            'email': email,
            'is_admin': true,
            'rol': 'dueno_tienda',
          };
          if (name.isNotEmpty) {
            userPayload['nombre_completo'] = name;
          }
          await SupaFlow.client.from('usuarios').upsert(userPayload);

          if (currentUser != null) {
            await AppStateNotifier.instance.update(currentUser!);
          }
        } catch (e) {
          debugPrint('Error haciendo upsert en tabla usuarios: $e');
        }
      }

      // Validar si el usuario tiene permitido crear una nueva tienda según su plan
      final eligibility = await StoreService.instance.checkStoreCreationEligibility();
      if (!eligibility.canCreate) {
        if (mounted) {
          _showPlanLimitUpgradeDialog(eligibility.message ??
              'Las cuentas con Plan Free están limitadas a un máximo de 2 tiendas. Para crear más tiendas, actualiza al Plan Pro.');
        }
        return;
      }

      if (mounted) {
        setState(() {
          _currentStep = 1;
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        String msg = e.message;
        if (e.message.toLowerCase().contains('invalid login credentials')) {
          msg = 'Credenciales incorrectas: Este correo ya existe con otra clave. Ingresa la contraseña correcta o inicia sesión.';
        } else if (e.statusCode == '429' || e.message.toLowerCase().contains('rate limit') || e.message.toLowerCase().contains('too many requests')) {
          msg = 'Límite de solicitudes de Supabase (Error 429). Espera unos minutos antes de volver a intentar.';
        } else if (e.message.toLowerCase().contains('email not confirmed')) {
          msg = 'Correo no confirmado: Revisa tu bandeja de entrada o desactiva "Confirm email" en Supabase Auth.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red, duration: const Duration(seconds: 5)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red, duration: const Duration(seconds: 5)),
        );
      }
    } finally {
      if (mounted) setState(() => _isAuthenticatingStep0 = false);
    }
  }

  Future<void> _submitRegistration() async {
    setState(() => _isLoading = true);

    try {
      // 1. Validar límite de tiendas por usuario
      final eligibility = await StoreService.instance.checkStoreCreationEligibility();
      if (!eligibility.canCreate) {
        if (mounted) {
          _showPlanLimitUpgradeDialog(eligibility.message ??
              'Las cuentas con Plan Free están limitadas a 2 tiendas. Para crear más tiendas, actualiza al Plan Pro.');
        }
        setState(() => _isLoading = false);
        return;
      }

      // 2. Validar si el slug ya está en uso
      final slug = _model.slugController.text.trim().toLowerCase();
      final slugExists = await StoreService.instance.checkSlugExists(slug);
      if (slugExists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El enlace (slug) ya está registrado por otra tienda. Elige otro.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
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

        if (currentUser != null) {
          try {
            await AppStateNotifier.instance.update(currentUser!);
          } catch (_) {}
        }

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
    final isDesktop = MediaQuery.sizeOf(context).width >= 992.0;

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.secondaryBackground,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver a Iniciar Sesión / Inicio',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed('loginPage');
            }
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.storefront_rounded, color: theme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'Crear Nueva Tienda',
              style: theme.titleMedium.override(
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          TextButton.icon(
            onPressed: () {
              context.goNamed('loginPage');
            },
            icon: const Icon(Icons.login_rounded, size: 18),
            label: const Text('Iniciar Sesión'),
            style: TextButton.styleFrom(
              foregroundColor: theme.primary,
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Columna Izquierda: Formulario compacto
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 28.0),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 500.0),
                          child: _buildFormCard(theme),
                        ),
                      ),
                    ),
                  ),
                  // Columna Derecha: Slider interactivo de tiendas / beneficios
                  Expanded(
                    flex: 6,
                    child: Container(
                      margin: const EdgeInsets.all(20.0),
                      child: _buildStoreShowcaseSlider(theme),
                    ),
                  ),
                ],
              )
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560.0),
                    child: _buildFormCard(theme),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildFormCard(FlutterFlowTheme theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: theme.alternate.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicador de Progreso
          _buildProgressHeader(theme),
          const SizedBox(height: 28),

          // Pasos del Wizard
          if (_currentStep == 0) _buildStepAccount(theme),
          if (_currentStep == 1) _buildStepStoreInfo(theme),
          if (_currentStep == 2) _buildStepBranding(theme),
          if (_currentStep == 3) _buildStepSuccess(theme),
        ],
      ),
    );
  }

  // --- Slider / Carrusel de Tiendas en Desktop ---
  Widget _buildStoreShowcaseSlider(FlutterFlowTheme theme) {
    final slides = _getSlides(theme);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.0),
        gradient: LinearGradient(
          colors: [
            theme.primary.withValues(alpha: 0.95),
            const Color(0xFF1E1B4B), // Deep Indigo Dark
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primary.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.0),
        child: Stack(
          children: [
            // Patrón de fondo decorativo
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -40,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),

            // PageView para los slides
            PageView.builder(
              controller: _sliderController,
              onPageChanged: (index) {
                setState(() => _currentSlideIndex = index);
              },
              itemCount: slides.length,
              itemBuilder: (context, index) {
                final slide = slides[index];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(40, 48, 40, 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Badge superior y Título
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(slide.icon, color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  slide.tag,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            slide.title,
                            style: GoogleFonts.interTight(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            slide.subtitle,
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.82),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),

                      // Vista previa visual / Card mockup
                      Center(
                        child: slide.previewWidget,
                      ),

                      // Bullets de características
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: slide.bulletPoints.map((point) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80), size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  point,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Controles inferiores (Indicador de puntos + Flechas)
            Positioned(
              bottom: 24,
              left: 36,
              right: 36,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Puntos indicadores
                  Row(
                    children: List.generate(slides.length, (i) {
                      final isActive = i == _currentSlideIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  // Botones Anterior / Siguiente
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          _sliderController.previousPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        },
                        icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 28),
                        splashRadius: 20,
                      ),
                      IconButton(
                        onPressed: () {
                          _sliderController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        },
                        icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 28),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_SlideItem> _getSlides(FlutterFlowTheme theme) {
    return [
      _SlideItem(
        tag: 'Catálogo Digital 24/7',
        icon: Icons.storefront_rounded,
        title: 'Tu tienda online activa y vendiendo siempre',
        subtitle: 'Publica tus productos con fotos, precios y variantes de forma ordenada para que tus clientes compren fácil.',
        bulletPoints: ['Sin comisiones por venta', 'Enlace directo a tu catálogo', 'Carga ultrarrápida'],
        previewWidget: _buildCatalogMockupCard(),
      ),
      _SlideItem(
        tag: 'Pedidos por WhatsApp',
        icon: Icons.chat_rounded,
        title: 'Recibe los pedidos listos en tu WhatsApp',
        subtitle: 'Tus clientes arman su carrito de compras y te envían el resumen detallado para concretar el pago al instante.',
        bulletPoints: ['Cálculo de totales automático', 'Notificación en tu teléfono', 'Atención directa'],
        previewWidget: _buildWhatsAppMockupCard(),
      ),
      _SlideItem(
        tag: 'Personalización Total',
        icon: Icons.palette_rounded,
        title: 'La identidad de tu marca en cada detalle',
        subtitle: 'Elige tu paleta de colores, sube tu logo, define tu banner y haz que tu tienda luzca 100% profesional.',
        bulletPoints: ['Paleta de colores', 'Logo y Banner propio', 'Dominio personalizado'],
        previewWidget: _buildBrandingMockupCard(),
      ),
      _SlideItem(
        tag: 'Control y Métricas',
        icon: Icons.trending_up_rounded,
        title: 'Administra inventario y monitorea tus ventas',
        subtitle: 'Carga masiva de productos desde Excel/CSV, gestión de stock y panel de control pensado para crecer.',
        bulletPoints: ['Importación Excel/CSV', 'Alertas de stock', 'Multi-tienda integrada'],
        previewWidget: _buildMetricsMockupCard(),
      ),
    ];
  }

  // --- Widgets visuales de Mockup para el slider ---
  Widget _buildCatalogMockupCard() {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(color: Color(0xFF6366F1), shape: BoxShape.circle),
                child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Modas Express', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('tuapp.com/modas-express', style: TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFF22C55E), borderRadius: BorderRadius.circular(6)),
                child: const Text('Abierto', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: const Row(
              children: [
                Icon(Icons.search, color: Colors.white70, size: 16),
                SizedBox(width: 6),
                Text('Buscar ropa, calzado...', style: TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildMiniProductCard('Camisa Casual', '\$25.00', Icons.checkroom_rounded),
              const SizedBox(width: 8),
              _buildMiniProductCard('Zapatillas Sport', '\$48.00', Icons.roller_skating_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniProductCard(String name, String price, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(child: Icon(icon, color: Colors.white, size: 24)),
            ),
            const SizedBox(height: 6),
            Text(name, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600), maxLines: 1),
            Text(price, style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsAppMockupCard() {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Color(0xFF25D366), shape: BoxShape.circle),
                child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              const Text('Pedido Recibido #1042', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              const Spacer(),
              const Text('Hace 2 min', style: TextStyle(color: Colors.white60, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF075E54).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🛒 *Nuevo Pedido Web*', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('• 2x Camisa Casual (\$50.00)\n• 1x Zapatillas Sport (\$48.00)', style: TextStyle(color: Colors.white70, fontSize: 10)),
                Divider(color: Colors.white24, height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total a Pagar:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                    Text('\$98.00 USD', style: TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandingMockupCard() {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildColorDot(const Color(0xFF6366F1), true),
              _buildColorDot(const Color(0xFF10B981), false),
              _buildColorDot(const Color(0xFFF59E0B), false),
              _buildColorDot(const Color(0xFFEF4444), false),
              _buildColorDot(const Color(0xFFEC4899), false),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Tema: Moderno & Vibrante\nAdaptado a tu marca', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorDot(Color color, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: isSelected ? Border.all(color: Colors.white, width: 2.5) : null,
      ),
      child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
    );
  }

  Widget _buildMetricsMockupCard() {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          _buildMetricPill('Ventas Hoy', '\$340.00', Icons.attach_money, const Color(0xFF4ADE80)),
          const SizedBox(width: 8),
          _buildMetricPill('Pedidos', '12', Icons.receipt_long, const Color(0xFF60A5FA)),
          const SizedBox(width: 8),
          _buildMetricPill('Productos', '48', Icons.inventory_2, const Color(0xFFFBBF24)),
        ],
      ),
    );
  }

  Widget _buildMetricPill(String title, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 9)),
            Text(val, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
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
          radius: 15,
          backgroundColor: isDone || isCurrent ? theme.primary : theme.alternate,
          child: isDone
              ? const Icon(Icons.check, size: 15, color: Colors.white)
              : Text(
                  '${stepIndex + 1}',
                  style: TextStyle(
                    color: isCurrent ? Colors.white : theme.secondaryText,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.bodySmall.override(
            fontFamily: 'Inter',
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            fontSize: 11,
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
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Crea tu cuenta de administrador para gestionar tus productos, pedidos y pagos.',
          style: theme.bodySmall.override(
            fontFamily: 'Inter',
            color: theme.secondaryText,
          ),
        ),
        const SizedBox(height: 20),

        if (loggedIn) ...[
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: theme.primary.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.account_circle, color: theme.primary, size: 32),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sesión activa como:',
                        style: TextStyle(fontSize: 11, color: theme.secondaryText),
                      ),
                      Text(
                        currentUserEmail,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await authManager.signOut();
                    setState(() {});
                  },
                  child: const Text('Cambiar', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ] else ...[
          // Selector de Modo (Nueva Cuenta vs Ya tengo cuenta)
          Container(
            decoration: BoxDecoration(
              color: theme.primaryBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.alternate),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isExistingAccountMode = false),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !_isExistingAccountMode ? theme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'Crear Cuenta',
                          style: TextStyle(
                            color: !_isExistingAccountMode ? Colors.white : theme.secondaryText,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isExistingAccountMode = true),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _isExistingAccountMode ? theme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'Ya tengo Cuenta',
                          style: TextStyle(
                            color: _isExistingAccountMode ? Colors.white : theme.secondaryText,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (!_isExistingAccountMode) ...[
            TextField(
              controller: _model.nameController,
              decoration: InputDecoration(
                labelText: 'Nombre Completo / Razón Social',
                hintText: 'Ej. Juan Pérez',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.person_outline, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _model.emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Correo Electrónico',
              hintText: 'tu@correo.com',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              prefixIcon: const Icon(Icons.email_outlined, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _model.passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: _isExistingAccountMode
                  ? 'Contraseña'
                  : 'Contraseña (mínimo 6 caracteres)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isAuthenticatingStep0 ? null : _handleStep0Account,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: theme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: _isAuthenticatingStep0
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    loggedIn
                        ? 'Continuar a Datos del Negocio ->'
                        : (_isExistingAccountMode
                            ? 'Iniciar Sesión y Continuar ->'
                            : 'Crear Cuenta y Continuar ->'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: TextButton.icon(
            onPressed: () {
              context.goNamed('loginPage');
            },
            icon: Icon(Icons.arrow_back_rounded, size: 16, color: theme.secondaryText),
            label: Text(
              'Salir y volver a Iniciar Sesión',
              style: TextStyle(
                color: theme.secondaryText,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
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
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Define el nombre comercial y el enlace de tu catálogo online.',
          style: theme.bodySmall.override(
            fontFamily: 'Inter',
            color: theme.secondaryText,
          ),
        ),
        const SizedBox(height: 20),

        TextField(
          controller: _model.storeNameController,
          onChanged: _onStoreNameChanged,
          decoration: InputDecoration(
            labelText: 'Nombre de la Tienda (ej. Modas Express)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            prefixIcon: const Icon(Icons.storefront_rounded, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _model.slugController,
          decoration: InputDecoration(
            labelText: 'Enlace de la Tienda (Slug / URL)',
            prefixText: 'tuapp.com/',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            prefixIcon: const Icon(Icons.link_rounded, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _model.phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Teléfono WhatsApp (para recibir pedidos)',
            hintText: '+58 412 1234567',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            prefixIcon: const Icon(Icons.phone_rounded, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep = 0),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Atrás', style: TextStyle(fontSize: 13)),
              ),
            ),
            const SizedBox(width: 12),
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
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: theme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text(
                  'Continuar ->',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- PASO 2: Branding e Identidad Visual (Logo, Colores) ---
  Widget _buildStepBranding(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paso 3: Identidad Visual & Colores',
          style: theme.headlineSmall.override(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Personaliza el logo y el color distintivo de tu tienda.',
          style: theme.bodySmall.override(
            fontFamily: 'Inter',
            color: theme.secondaryText,
          ),
        ),
        const SizedBox(height: 18),

        // Subida de Logo
        Text('Logo de la Tienda (Opcional)', style: theme.bodyMedium.override(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _pickImage(true),
          child: Container(
            height: 90,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.primaryBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.alternate),
            ),
            child: _logoBytes != null
                ? Image.memory(_logoBytes!, fit: BoxFit.contain)
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 30),
                      SizedBox(height: 4),
                      Text('Haz clic para subir el Logo', style: TextStyle(fontSize: 12)),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 18),

        // Selector de Color Primario
        Text('Color Principal de la Marca', style: theme.bodyMedium.override(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _presetColors.map((colorHex) {
            final isSelected = _model.primaryColorHex == colorHex;
            final color = Color(int.parse(colorHex.replaceFirst('#', 'ff'), radix: 16));
            return GestureDetector(
              onTap: () => setState(() => _model.primaryColorHex = colorHex),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected ? Border.all(color: Colors.black, width: 2.5) : null,
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep = 1),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Atrás', style: TextStyle(fontSize: 13)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRegistration,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: theme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        '¡Crear Mi Tienda!',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
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
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Icon(Icons.check_circle_rounded, size: 70, color: Color(0xFF16A34A)),
            const SizedBox(height: 14),
            Text(
              '¡Tu Tienda ha sido creada!',
              style: theme.headlineSmall.override(
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'La tienda "${_model.storeNameController.text}" está lista. Ya puedes comenzar a subir productos y recibir pedidos por WhatsApp.',
              textAlign: TextAlign.center,
              style: theme.bodySmall.override(
                fontFamily: 'Inter',
                color: theme.secondaryText,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                if (currentUser != null) {
                  try {
                    await AppStateNotifier.instance.update(currentUser!);
                  } catch (_) {}
                }
                if (context.mounted) {
                  context.goNamed('administracion');
                }
              },
              icon: const Icon(Icons.dashboard_rounded, size: 18),
              label: const Text('Ir a mi Panel de Control'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideItem {
  final String tag;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> bulletPoints;
  final Widget previewWidget;

  const _SlideItem({
    required this.tag,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.bulletPoints,
    required this.previewWidget,
  });
}
