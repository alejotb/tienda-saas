import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/components/gradient_button/gradient_button_widget.dart';
import 'package:baul_pandora/components/top_nav/top_nav_widget.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/index.dart';
import 'product_details_widget.dart' show ProductDetailsWidget;
import 'package:flutter/material.dart';

class ProductDetailsModel extends FlutterFlowModel<ProductDetailsWidget> {
  ///  Local state fields for this page.

  int index = 0;

  ///  State fields for stateful widgets in this page.

  // Model for topNav component.
  late TopNavModel topNavModel;
  // Model for gradientButton component.
  late GradientButtonModel gradientButtonModel;
  // State field(s) for CountController widget.
  int? countControllerValue;
  // Stores action output result for [Backend Call - Insert Row] action in Button widget.
  PedidosRow? nuevoPedido;
  // Lista de productos relacionados
  List<ProductosRow>? relatedProducts;
  
  // --- Lógica de Variaciones ---
  List<ProductosRow> variaciones = [];
  List<String> combinedImages = [];
  Map<String, String> selectedAttributes = {};
  Map<String, Set<String>> availableAttributes = {};
  ProductosRow? currentActiveProduct;

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
