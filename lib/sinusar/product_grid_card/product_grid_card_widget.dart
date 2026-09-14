import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'product_grid_card_model.dart';
export 'product_grid_card_model.dart';

class ProductGridCardWidget extends StatefulWidget {
  const ProductGridCardWidget({super.key});

  @override
  State<ProductGridCardWidget> createState() => _ProductGridCardWidgetState();
}

class _ProductGridCardWidgetState extends State<ProductGridCardWidget> {
  late ProductGridCardModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProductGridCardModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
