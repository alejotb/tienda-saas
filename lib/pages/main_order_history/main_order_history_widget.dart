import 'package:baul_pandora/components/top_nav/top_nav_widget.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'main_order_history_model.dart';
import 'components/order_history_header.dart';
import 'components/order_history_filters.dart';
import 'components/order_history_list.dart';

export 'main_order_history_model.dart';

class MainOrderHistoryWidget extends StatefulWidget {
  const MainOrderHistoryWidget({super.key});

  static String routeName = 'mainOrderHistory';
  static String routePath = '/mainOrderHistory';

  @override
  State<MainOrderHistoryWidget> createState() => _MainOrderHistoryWidgetState();
}

class _MainOrderHistoryWidgetState extends State<MainOrderHistoryWidget>
    with TickerProviderStateMixin {
  late MainOrderHistoryModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MainOrderHistoryModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                if (responsiveVisibility(context: context, phone: false, tablet: false))
                  wrapWithModel(
                    model: _model.topNavModel,
                    updateCallback: () => safeSetState(() {}),
                    child: const TopNavWidget(),
                  ),
                Align(
                  alignment: const AlignmentDirectional(0.0, 0.0),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 1170.0),
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).primaryBackground,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const OrderHistoryHeader(),
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 0.0, 0.0),
                          child: OrderHistoryFilters(
                            model: _model,
                            onUpdate: () => safeSetState(() {}),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              20.0, 24.0, 20.0, 0.0),
                          child: OrderHistoryList(model: _model),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
