import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/services/store_theme_service.dart';
import 'package:baul_pandora/index.dart';
import 'main_logo_model.dart';
export 'main_logo_model.dart';

class MainLogoWidget extends StatefulWidget {
  const MainLogoWidget({
    super.key,
    this.forceGeneralLogo = false,
  });

  final bool forceGeneralLogo;

  @override
  State<MainLogoWidget> createState() => _MainLogoWidgetState();
}

class _MainLogoWidgetState extends State<MainLogoWidget> {
  late MainLogoModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MainLogoModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.forceGeneralLogo) {
      return InkWell(
        splashColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: () async {
          context.pushNamed(MainHomePageWidget.routeName);
        },
        child: _buildDefaultLogo(context),
      );
    }

    return ListenableBuilder(
      listenable: StoreThemeService.instance,
      builder: (context, _) {
        final store = StoreThemeService.instance.currentStore;

        return InkWell(
          splashColor: Colors.transparent,
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: () async {
            context.pushNamed(MainHomePageWidget.routeName);
          },
          child: store != null
              ? _buildStoreBranding(context, store)
              : _buildDefaultLogo(context),
        );
      },
    );
  }

  Widget _buildStoreBranding(BuildContext context, dynamic store) {
    final primaryColor = StoreThemeService.instance.primaryColor;
    final theme = FlutterFlowTheme.of(context);

    if (store.logoUrl != null && store.logoUrl!.trim().isNotEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 38.0,
            constraints: const BoxConstraints(maxWidth: 140.0),
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.25),
                width: 1.0,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6.0),
              child: Image.network(
                store.logoUrl!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _buildStoreFallbackText(theme, primaryColor, store.nombre),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          Flexible(
            child: Text(
              store.nombre,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
                color: theme.primaryText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return _buildStoreFallbackText(theme, primaryColor, store.nombre);
  }

  Widget _buildStoreFallbackText(FlutterFlowTheme theme, Color primaryColor, String nombre) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6.0),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.storefront_rounded,
            color: primaryColor,
            size: 20.0,
          ),
        ),
        const SizedBox(width: 8.0),
        Flexible(
          child: Text(
            nombre,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 17.0,
              color: theme.primaryText,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultLogo(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: Image.asset(
        Theme.of(context).brightness == Brightness.dark
            ? 'assets/images/shop_logo_light@4x.png'
            : 'assets/images/shop_logo_dark@4x.png',
        width: 170.0,
        height: 40.0,
        fit: BoxFit.fitWidth,
      ),
    );
  }
}
