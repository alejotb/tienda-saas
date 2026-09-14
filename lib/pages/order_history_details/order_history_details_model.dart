import 'package:baul_pandora/backend/schema/structs/index.dart';
import 'package:baul_pandora/components/gradient_button/gradient_button_widget.dart';
import 'package:baul_pandora/components/top_nav/top_nav_widget.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'order_history_details_widget.dart' show OrderHistoryDetailsWidget;
import 'package:flutter/material.dart';

class OrderHistoryDetailsModel
    extends FlutterFlowModel<OrderHistoryDetailsWidget> {
  ///  Local state fields for this page.

  AddressStruct? shippingAdress;
  void updateShippingAdressStruct(Function(AddressStruct) updateFn) {
    updateFn(shippingAdress ??= AddressStruct());
  }

  ///  State fields for stateful widgets in this page.

  // Model for topNav component.
  late TopNavModel topNavModel;
  // Model for gradientButton component.
  late GradientButtonModel gradientButtonModel;

  @override
  void initState(BuildContext context) {
    topNavModel = createModel(context, () => TopNavModel());
    gradientButtonModel = createModel(context, () => GradientButtonModel());
  }

  @override
  void dispose() {
    topNavModel.dispose();
    gradientButtonModel.dispose();
  }
}
