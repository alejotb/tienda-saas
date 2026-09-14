import 'package:baul_pandora/components/top_nav/top_nav_widget.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/pages/main_home_page/main_home_page_model.dart';
import 'package:flutter/material.dart';

class MainHeaderComponent extends StatelessWidget {
  const MainHeaderComponent({
    super.key,
    required this.model,
    required this.updateCallback,
    required this.onCategoryTap,
  });

  final MainHomePageModel model;
  final VoidCallback updateCallback;
  final Function(String) onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        wrapWithModel(
          model: model.topNavModel,
          updateCallback: updateCallback,
          child: const TopNavWidget(),
        ),
      ],
    );
  }
}
