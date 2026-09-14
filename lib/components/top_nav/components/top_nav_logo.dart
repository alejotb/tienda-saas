import 'package:flutter/material.dart';
import 'package:baul_pandora/components/main_logo/main_logo_widget.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';

class TopNavLogo extends StatelessWidget {
  final dynamic model; // Ajustar según el tipo real del modelo
  final VoidCallback updateCallback;

  const TopNavLogo({super.key, required this.model, required this.updateCallback});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
        child: wrapWithModel(
          model: model.mainLogoModel,
          updateCallback: updateCallback,
          child: const MainLogoWidget(),
        ),
      ),
    );
  }
}
