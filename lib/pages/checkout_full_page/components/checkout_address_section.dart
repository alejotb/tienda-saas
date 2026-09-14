import 'package:baul_pandora/backend/schema/structs/index.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/auth/supabase_auth/auth_util.dart';
import 'package:baul_pandora/components/add_address_base/add_address_base_widget.dart';
import 'package:baul_pandora/components/u_i_marker/u_i_marker_widget.dart';
import 'package:baul_pandora/dropdowns/modal_add_address/modal_add_address_widget.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_icon_button.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/flutter_flow/custom_functions.dart' as functions;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../checkout_full_page_model.dart';
import 'checkout_saved_addresses_list.dart';

class CheckoutAddressSection extends StatelessWidget {
  const CheckoutAddressSection({
    super.key,
    required this.model,
    required this.onUpdate,
  });

  final CheckoutFullPageModel model;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0.0, 24.0, 0.0, 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (model.direccionesGuardadas.isEmpty || model.mostrarFormularioDireccion)
                          Text(
                            'Por favor, completa la siguiente información para continuar',
                            style: FlutterFlowTheme.of(context).labelMedium.override(
                                  font: GoogleFonts.inter(
                                    fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                  ),
                                  letterSpacing: 0.0,
                                  color: model.highlightErrors && (!model.isValidLocation || !model.isValidShipping)
                                      ? Colors.red
                                      : null,
                            ),
                          ),
                        if (model.direccionesGuardadas.isEmpty)
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 0.0),
                  child: wrapWithModel(
                    model: model.addAddressBaseModel,
                    updateCallback: () => onUpdate(),
                    child: AddAddressBaseWidget(
                      customDialog: true,
                       action: () async {
                         final newAddress = AddressStruct(
                           addressName: 'Dirección #${model.direccionesGuardadas.length + 1}',
                           address: model.addAddressBaseModel.addressTextController.text,
                           address2: model.addAddressBaseModel.clonableURLTextController.text,
                           city: model.addAddressBaseModel.cityTextController.text,
                           state: model.addAddressBaseModel.stateTextController.text,
                         );
                         model.address = newAddress;
                         model.addToDireccionesGuardadas(newAddress);
                         onUpdate();
                         FFAppState().listaDirecciones = model.direccionesGuardadas.toList().cast<AddressStruct>();
                                 onUpdate();
                                 if (loggedIn) {
                                   await UsuariosTable().update(
                             data: {
                               'datos_direccion': functions.addressesToJSONList(model.direccionesGuardadas),
                             },
                             matchingRows: (rows) => rows.eq(
                               'id',
                               currentUserUid,
                             ),
                           );
                         }
                       },
                    ),
                  ),
                ),
              if (model.direccionesGuardadas.isNotEmpty)
                Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tus direcciones guardadas',
                          style: FlutterFlowTheme.of(context).labelMedium,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Builder(
                              builder: (context) => FlutterFlowIconButton(
                                borderColor: FlutterFlowTheme.of(context).primary,
                                borderRadius: 12.0,
                                borderWidth: 1.0,
                                buttonSize: 40.0,
                                fillColor: FlutterFlowTheme.of(context).accent1,
                                icon: Icon(
                                  Icons.add_location_alt_rounded,
                                  color: FlutterFlowTheme.of(context).primaryText,
                                  size: 24.0,
                                ),
                                onPressed: () async {
                                  await showDialog(
                                    barrierColor: Colors.transparent,
                                    context: context,
                                    builder: (dialogContext) {
                                      return Dialog(
                                        elevation: 0,
                                        insetPadding: EdgeInsets.zero,
                                        backgroundColor: Colors.transparent,
                                        alignment: const AlignmentDirectional(0.0, 0.0).resolve(Directionality.of(context)),
                                        child: GestureDetector(
                                          onTap: () {
                                            FocusScope.of(dialogContext).unfocus();
                                            FocusManager.instance.primaryFocus?.unfocus();
                                          },
                                          child: ModalAddAddressWidget(
                                             guardar: (adress) async {
                                               final newAddress = AddressStruct(
                                                 addressName: 'Dirección #${model.direccionesGuardadas.length + 1}',
                                                 address: adress.address,
                                                 address2: adress.address2,
                                                 city: adress.city,
                                                 state: adress.state,
                                               );
                                               model.address = newAddress;
                                               model.addToDireccionesGuardadas(newAddress);
                                               onUpdate();
                                               FFAppState().listaDirecciones = model.direccionesGuardadas.toList().cast<AddressStruct>();
                                                onUpdate();
                                                if (loggedIn) {
                                                  await UsuariosTable().update(
                                                   data: {
                                                     'datos_direccion': functions.addressesToJSONList(model.direccionesGuardadas),
                                                   },
                                                   matchingRows: (rows) => rows.eq('id', currentUserUid),
                                                 );
                                               }
                                             },
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                model.agenciasGuardadas.clear();
                                model.selectedAgency = null;
                                model.featuredAgencyCode = null;
                                model.agencySearchController.clear();
                                onUpdate();
                              },
                              child: Text(
                                'Limpiar todo',
                                style: FlutterFlowTheme.of(context).bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    CheckoutSavedAddressesList(
                      addresses: model.direccionesGuardadas.toList(),
                      selectedAddress: model.address,
                      onAddressSelected: (address) {
                        model.address = address;
                        model.mostrarFormularioDireccion = false;
                        onUpdate();
                      },
                      onAddressDeleted: (address) async {
                        await model.deleteAddress(address);
                        if (model.direccionesGuardadas.isEmpty) {
                          model.mostrarFormularioDireccion = true;
                        }
                        onUpdate();
                      },
                    ),
                    const SizedBox(height: 12),
                    if (model.mostrarFormularioDireccion)
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 0.0),
                        child: wrapWithModel(
                          model: model.addAddressBaseModel,
                          updateCallback: () => onUpdate(),
                          child: AddAddressBaseWidget(
                            customDialog: true,
                             action: () async {
                               final newAddress = AddressStruct(
                                 addressName: 'Dirección #${model.direccionesGuardadas.length + 1}',
                                 address: model.addAddressBaseModel.addressTextController.text,
                                 address2: model.addAddressBaseModel.clonableURLTextController.text,
                                 city: model.addAddressBaseModel.cityTextController.text,
                                 state: model.addAddressBaseModel.stateTextController.text,
                                 tipoDireccion: 'casa',
                               );
                               bool isDuplicate = model.direccionesGuardadas.any((a) => 
                                 a.tipoDireccion == 'casa' &&
                                 a.address.trim().toLowerCase() == newAddress.address.trim().toLowerCase() && 
                                 a.city.trim().toLowerCase() == newAddress.city.trim().toLowerCase()
                               );

                               if (isDuplicate) {
                                 ScaffoldMessenger.of(context).showSnackBar(
                                   SnackBar(
                                     content: Text(
                                       'Esta dirección ya está en tu lista.',
                                       style: FlutterFlowTheme.of(context).bodyMedium.override(
                                             fontFamily: 'Inter',
                                             color: FlutterFlowTheme.of(context).primaryBackground,
                                           ),
                                     ),
                                     backgroundColor: FlutterFlowTheme.of(context).error,
                                   ),
                                 );
                                 return;
                               }

                               model.address = newAddress;
                               model.addToDireccionesGuardadas(newAddress);
                               model.mostrarFormularioDireccion = false;
                               onUpdate();
                               FFAppState().listaDirecciones = model.direccionesGuardadas.toList().cast<AddressStruct>();
                               onUpdate();
                               if (loggedIn) {
                                 await UsuariosTable().update(
                                   data: {
                                     'datos_direccion': functions.addressesToJSONList(model.direccionesGuardadas),
                                   },
                                   matchingRows: (rows) => rows.eq(
                                     'id',
                                     currentUserUid,
                                   ),
                                 );
                               }
                             },
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
        if (model.stepNumber >= 2)
          wrapWithModel(
            model: model.uIMarkerModel1,
            updateCallback: () => onUpdate(),
            child: const UIMarkerWidget(),
          ),
      ],
    );
  }
}
