import 'package:flutter/material.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/backend/supabase/database/tables/cupones.dart';
import 'package:intl/intl.dart';

class AdminDiscountsView extends StatefulWidget {
  const AdminDiscountsView({super.key});

  @override
  State<AdminDiscountsView> createState() => _AdminDiscountsViewState();
}

class _AdminDiscountsViewState extends State<AdminDiscountsView> {
  bool _isLoading = true;
  String _filter = 'todos'; // 'todos', 'activos', 'expirados'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    // FutureBuilder handles the actual fetch
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading 
      ? const Center(child: CircularProgressIndicator())
      : Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Motor de Descuentos',
                    style: FlutterFlowTheme.of(context).headlineMedium.override(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateCouponDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Crear Cupón'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FlutterFlowTheme.of(context).primary,
                      foregroundColor: FlutterFlowTheme.of(context).primaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Vigency Filter
              Container(
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: FlutterFlowTheme.of(context).alternate),
                ),
                child: Row(
                  children: [
                    _buildFilterItem('todos', 'Todos', Icons.list),
                    _buildFilterItem('activos', 'Activos', Icons.check_circle_outline),
                    _buildFilterItem('expirados', 'Expirados', Icons.timer_off_outlined),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Coupons Table
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: FlutterFlowTheme.of(context).alternate),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildCouponsTable(),
                  ),
                ),
              ),
            ],
          ),
        );
  }

  Widget _buildFilterItem(String value, String label, IconData icon) {
    final bool isActive = _filter == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _filter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? FlutterFlowTheme.of(context).primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? FlutterFlowTheme.of(context).primaryText : FlutterFlowTheme.of(context).secondaryText,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                  fontFamily: 'Inter',
                  color: isActive ? FlutterFlowTheme.of(context).primaryText : FlutterFlowTheme.of(context).secondaryText,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCouponsTable() {
    return FutureBuilder<List<CuponesRow>>(
      future: CuponesTable().queryRows(
        queryFn: (q) {
          if (_filter == 'activos') {
            q = q.eq('activo', true).gte('fecha_expiracion', DateTime.now().toIso8601String());
          } else if (_filter == 'expirados') {
            q = q.or('activo.eq.false,fecha_expiracion.lt.${DateTime.now().toIso8601String()}');
          }
          return q;
        },
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final coupons = snapshot.data!;
        if (coupons.isEmpty) return const Center(child: Text('No hay cupones disponibles'));

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: FlutterFlowTheme.of(context).primaryBackground,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Código', style: FlutterFlowTheme.of(context).titleSmall.override(fontWeight: FontWeight.bold)),
                  Text('Descuento', style: FlutterFlowTheme.of(context).titleSmall.override(fontWeight: FontWeight.bold)),
                  Text('Expira', style: FlutterFlowTheme.of(context).titleSmall.override(fontWeight: FontWeight.bold)),
                  Text('Uso', style: FlutterFlowTheme.of(context).titleSmall.override(fontWeight: FontWeight.bold)),
                  Text('Acciones', style: FlutterFlowTheme.of(context).titleSmall.override(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: coupons.length,
                separatorBuilder: (context, index) => Divider(color: FlutterFlowTheme.of(context).alternate),
                itemBuilder: (context, index) {
                  final coupon = coupons[index];
                  final bool isExpired = coupon.fechaExpiracion.isBefore(DateTime.now());
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            coupon.codigo,
                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontWeight: FontWeight.bold,
                              color: isExpired ? Colors.red : FlutterFlowTheme.of(context).primaryText,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '${coupon.descuentoPorcentaje}%',
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context).bodyMedium,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            DateFormat('dd/MM/yyyy').format(coupon.fechaExpiracion),
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context).bodySmall,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '${coupon.usosActuales}/${coupon.limiteUsos}',
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context).bodySmall,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCreateCouponDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Implementando Modal de Creación de Cupón...')),
    );
  }
}
