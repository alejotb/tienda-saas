import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '../product_create_model.dart';

class ProductBasicInfoSection extends StatelessWidget {
  final ProductCreateModel model;

  const ProductBasicInfoSection({
    super.key,
    required this.model,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información Básica',
          style: FlutterFlowTheme.of(context).headlineSmall,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: model.textController1,
          focusNode: model.textFieldFocusNode1,
          decoration: InputDecoration(
            labelText: 'Nombre del Producto',
            labelStyle: FlutterFlowTheme.of(context).bodyMedium,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: FlutterFlowTheme.of(context).secondaryBackground,
          ),
          style: FlutterFlowTheme.of(context).bodyLarge,
          validator: model.textController1Validator.asValidator(context),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: model.textController2,
          focusNode: model.textFieldFocusNode2,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: 'Descripción Corta',
            labelStyle: FlutterFlowTheme.of(context).bodyMedium,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: FlutterFlowTheme.of(context).secondaryBackground,
          ),
          style: FlutterFlowTheme.of(context).bodyMedium,
          validator: model.textController2Validator.asValidator(context),
        ),
      ],
    );
  }
}
