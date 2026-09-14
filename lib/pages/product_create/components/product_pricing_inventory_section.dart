import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '../product_create_model.dart';
import '/components/barcode_scanner_modal.dart' as baul_pandora;


class ProductPricingInventorySection extends StatelessWidget {
  final ProductCreateModel model;
  final VoidCallback onStateChanged;

  const ProductPricingInventorySection({
    super.key,
    required this.model,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Precios e Inventario',
          style: FlutterFlowTheme.of(context).headlineSmall,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: model.textController3,
          focusNode: model.textFieldFocusNode3,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Precio Regular',
            prefixText: '\$ ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: FlutterFlowTheme.of(context).secondaryBackground,
          ),
          style: FlutterFlowTheme.of(context).bodyLarge,
          validator: model.textController3Validator.asValidator(context),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: model.textController5,
                focusNode: model.textFieldFocusNode5,
                decoration: InputDecoration(
                  labelText: 'SKU / Código de Barras',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                ),
                style: FlutterFlowTheme.of(context).bodyMedium,
                validator: model.textController5Validator.asValidator(context),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                onPressed: () async {
                  final code = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const baul_pandora.BarcodeScannerModal(),
                    ),
                  );
                  if (code != null && code.isNotEmpty) {
                    model.textController5?.text = code;
                    onStateChanged();
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: Text('Gestionar Inventario', style: FlutterFlowTheme.of(context).bodyLarge),
          value: model.switchValue1 ?? true,
          onChanged: (val) {
            model.switchValue1 = val;
            onStateChanged();
          },
          activeTrackColor: FlutterFlowTheme.of(context).primary,
        ),
        if (model.switchValue1 == true)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: TextFormField(
              controller: model.textController6,
              focusNode: model.textFieldFocusNode6,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Cantidad en Stock',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: FlutterFlowTheme.of(context).secondaryBackground,
              ),
              style: FlutterFlowTheme.of(context).bodyLarge,
              validator: model.textController6Validator.asValidator(context),
            ),
          ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: Text('Publicar en WooCommerce', style: FlutterFlowTheme.of(context).bodyLarge),
          subtitle: Text('Sincronizar este producto con la tienda online', style: FlutterFlowTheme.of(context).bodySmall),
          value: model.switchValue2 ?? true,
          onChanged: (val) {
            model.switchValue2 = val;
            onStateChanged();
          },
          activeTrackColor: FlutterFlowTheme.of(context).primary,
        ),
      ],
    );
  }
}
