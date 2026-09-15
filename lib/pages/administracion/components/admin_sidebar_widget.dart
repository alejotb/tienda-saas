import 'package:flutter/material.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import '../administracion_model.dart';

class AdminSidebarItem {
  final AdminView view;
  final String label;
  final IconData icon;

  AdminSidebarItem({
    required this.view,
    required this.label,
    required this.icon,
  });
}

class AdminSidebarWidget extends StatelessWidget {
  final AdminView currentView;
  final Function(AdminView) onViewChanged;

  const AdminSidebarWidget({
    super.key,
    required this.currentView,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    final List<AdminSidebarItem> items = [
      AdminSidebarItem(view: AdminView.general, label: 'General', icon: Icons.dashboard_rounded),
      AdminSidebarItem(view: AdminView.products, label: 'Productos', icon: Icons.inventory_2_rounded),
      AdminSidebarItem(view: AdminView.orders, label: 'Pedidos', icon: Icons.shopping_bag_rounded),
      AdminSidebarItem(view: AdminView.subscription, label: 'Mi Plan & Suscripción', icon: Icons.stars_rounded),
      AdminSidebarItem(view: AdminView.customDomain, label: 'Dominio Propio', icon: Icons.language_rounded),
      AdminSidebarItem(view: AdminView.users, label: 'Usuarios', icon: Icons.people_alt_rounded),
      AdminSidebarItem(view: AdminView.discounts, label: 'Descuentos', icon: Icons.local_offer_rounded),
    ];

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        border: Border(
          right: BorderSide(
            color: FlutterFlowTheme.of(context).alternate,
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'ADMIN PANEL',
              style: FlutterFlowTheme.of(context).titleSmall.override(
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                color: FlutterFlowTheme.of(context).secondaryText,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final bool isActive = currentView == item.view;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    onTap: () => onViewChanged(item.view),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: isActive 
                          ? FlutterFlowTheme.of(context).primary 
                          : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            color: isActive 
                              ? FlutterFlowTheme.of(context).primaryText 
                              : FlutterFlowTheme.of(context).secondaryText,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            item.label,
                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'Inter',
                              color: isActive 
                                ? FlutterFlowTheme.of(context).primaryText 
                                : FlutterFlowTheme.of(context).secondaryText,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
