import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/backend/schema/structs/index.dart';

class CheckoutSavedAddressesList extends StatelessWidget {
  const CheckoutSavedAddressesList({
    super.key,
    required this.addresses,
    required this.selectedAddress,
    required this.onAddressSelected,
    required this.onAddressDeleted,
  });

  final List<AddressStruct> addresses;
  final AddressStruct? selectedAddress;
  final Function(AddressStruct) onAddressSelected;
  final Function(AddressStruct) onAddressDeleted;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(0, 12.0, 0, 16.0),
      shrinkWrap: true,
      scrollDirection: Axis.vertical,
      itemCount: addresses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4.0),
      itemBuilder: (context, index) {
        final item = addresses[index];
        final isSelected = item.address == selectedAddress?.address;

        return InkWell(
          splashColor: Colors.transparent,
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: () => onAddressSelected(item),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isSelected 
                  ? FlutterFlowTheme.of(context).accent2 
                  : FlutterFlowTheme.of(context).secondaryBackground,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: isSelected 
                    ? FlutterFlowTheme.of(context).secondary 
                    : FlutterFlowTheme.of(context).secondaryBackground,
                width: 2.0,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          valueOrDefault<String>(item.addressName, '--'),
                          style: FlutterFlowTheme.of(context).bodyLarge.override(
                                 font: GoogleFonts.inter(
                                   fontWeight: FlutterFlowTheme.of(context).bodyLarge.fontWeight,
                                   fontStyle: FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                                 ),
                                 letterSpacing: 0.0,
                                 fontWeight: FlutterFlowTheme.of(context).bodyLarge.fontWeight,
                                 fontStyle: FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                               ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 0.0),
                          child: RichText(
                            textScaler: MediaQuery.of(context).textScaler,
                            text: TextSpan(
                              children: [
                                TextSpan(text: item.address, style: const TextStyle()),
                                const TextSpan(text: ', ', style: TextStyle()),
                                TextSpan(text: item.address2, style: const TextStyle()),
                                const TextSpan(text: ' ', style: TextStyle()),
                                TextSpan(
                                  text: valueOrDefault<String>(item.city, '--'),
                                  style: const TextStyle(),
                                ),
                                const TextSpan(text: ', ', style: TextStyle()),
                                TextSpan(
                                  text: valueOrDefault<String>(item.state, '--'),
                                  style: const TextStyle(),
                                ),
                                const TextSpan(text: ' ', style: TextStyle()),
                                TextSpan(
                                  text: valueOrDefault<String>(item.postalCode.toString(), '--'),
                                  style: const TextStyle(),
                                ),
                              ],
                              style: FlutterFlowTheme.of(context).labelMedium.override(
                                  font: GoogleFonts.inter(
                                    fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                  ),
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.close, size: 20, color: FlutterFlowTheme.of(context).secondaryText),
                        onPressed: () => onAddressDeleted(item),
                      ),
                      Align(
                        alignment: const AlignmentDirectional(1.0, -1.0),
                        child: Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 8.0, 16.0),
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: isSelected 
                                ? FlutterFlowTheme.of(context).secondary 
                                : FlutterFlowTheme.of(context).secondaryBackground,
                            size: 24.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
