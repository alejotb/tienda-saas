import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/components/add_office_address_base/add_office_address_base_model.dart';
import 'modal_add_office_address_widget.dart' show ModalAddOfficeAddressWidget;
import 'package:flutter/material.dart';

class ModalAddOfficeAddressModel extends FlutterFlowModel<ModalAddOfficeAddressWidget> {
  // Model for addOfficeAddress_Base component.
  late AddOfficeAddressBaseModel addOfficeAddressBaseModel;

  @override
  void initState(BuildContext context) {
    addOfficeAddressBaseModel = createModel(context, () => AddOfficeAddressBaseModel());
  }

  @override
  void dispose() {
    addOfficeAddressBaseModel.dispose();
  }
}
