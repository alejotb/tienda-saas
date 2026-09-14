import 'package:flutter/material.dart';
import 'package:baul_pandora/backend/schema/structs/index.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:google_fonts/google_fonts.dart';

class ShippingAddress extends StatelessWidget {
  final AddressStruct? shippingAdress;

  const ShippingAddress({super.key, required this.shippingAdress});

  @override
  Widget build(BuildContext context) {
    if (shippingAdress == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Tu Dirección de Envío',
            style: FlutterFlowTheme.of(context).labelMedium,
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: FlutterFlowTheme.of(context).secondaryBackground,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  valueOrDefault<String>(shippingAdress?.addressName, 'Unknown'),
                  style: FlutterFlowTheme.of(context).bodyLarge,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(text: valueOrDefault<String>(shippingAdress?.address, '--')),
                        const TextSpan(text: ', '),
                        TextSpan(text: valueOrDefault<String>(shippingAdress?.address2, '--')),
                        const TextSpan(text: ' '),
                        TextSpan(text: valueOrDefault<String>(shippingAdress?.city, '--')),
                        const TextSpan(text: ', '),
                        TextSpan(text: valueOrDefault<String>(shippingAdress?.state, '--')),
                        const TextSpan(text: ' '),
                        TextSpan(text: valueOrDefault<String>(shippingAdress?.postalCode?.toString(), '--')),
                      ],
                      style: FlutterFlowTheme.of(context).labelMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
