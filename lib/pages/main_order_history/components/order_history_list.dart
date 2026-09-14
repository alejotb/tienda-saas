import 'package:flutter/material.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/auth/supabase_auth/auth_util.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/components/empty_orders/empty_orders_widget.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'order_history_card.dart';
import '../main_order_history_model.dart';

class OrderHistoryList extends StatelessWidget {
  const OrderHistoryList({
    super.key,
    required this.model,
  });

  final MainOrderHistoryModel model;

  @override
  Widget build(BuildContext context) {
    // We only show orders for the current user.
    // If user is not logged in, we show the guest message.
    if (!loggedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_circle_outlined, size: 64, color: FlutterFlowTheme.of(context).secondaryText),
              const SizedBox(height: 16),
              Text(
                'Crea una cuenta para ver todos los pedidos que has realizado',
                textAlign: TextAlign.center,
                style: FlutterFlowTheme.of(context).bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  context.pushNamed('login');
                },
                child: const Text('Iniciar Sesión / Registrarse'),
              ),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<List<PedidosRow>>(
      future: PedidosTable().queryRows(
        queryFn: (q) => q
            .eq('user_id', currentUserUid)
            .neq('status', 'carrito'),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: SizedBox(
              width: 50.0, height: 50.0,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(FlutterFlowTheme.of(context).primary),
              ),
            ),
          );
        }

        final orders = snapshot.data!;
        
        // Apply local filters from model
        final filteredOrders = orders.where((order) {
          if (model.filtro.isEmpty) return true;
          return model.filtro.contains(order.status);
        }).toList();

        if (filteredOrders.isEmpty) {
          return const Center(
            child: SizedBox(
              width: 300.0, height: 350.0,
              child: EmptyOrdersWidget(),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.zero,
          primary: false,
          shrinkWrap: true,
          scrollDirection: Axis.vertical,
          itemCount: filteredOrders.length,
          itemBuilder: (context, index) {
            final order = filteredOrders[index];
            return GestureDetector(
              onTap: () {
                context.pushNamed(
                  'OrderHistoryDetailsWidget',
                  queryParameters: {
                    'orderRef': serializeParam(order, ParamType.SupabaseRow),
                  }.withoutNulls,
                );
              },
              child: OrderHistoryCard(order: order),
            );
          },
        );
      },
    );
  }
}
