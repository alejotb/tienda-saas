import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/backend/supabase/database/tables/pedidos.dart';
import 'package:baul_pandora/backend/supabase/database/tables/pedido_items.dart';
import 'package:baul_pandora/dropdowns/dropdown_menu/dropdown_menu_widget.dart';
import 'package:aligned_dialog/aligned_dialog.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_icon_button.dart';

class OrderHistoryCard extends StatelessWidget {
  const OrderHistoryCard({
    super.key,
    required this.order,
  });

  final PedidosRow order;

  Color _getStatusColor(BuildContext context) {
    switch (order.status) {
      case 'carrito': return Colors.grey;
      case 'pendiente_pago': return Colors.orange.withOpacity(0.2);
      case 'confirmado': return Colors.blue;
      case 'pagado': return Colors.green;
      case 'enviado': return Colors.purple;
      case 'entregado': return Colors.purpleAccent;
      case 'cancelado': return Colors.red;
      default: return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 12.0),
      child: InkWell(
        splashColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: () async {
          // The navigation logic is kept in the parent for now, but could be moved here
        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            boxShadow: const [
              BoxShadow(
                blurRadius: 4.0,
                color: Color(0x520E151B),
                offset: Offset(0.0, 2.0),
              )
            ],
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        (order.status == 'apartado')
                            ? 'Apartado'
                            : (order.status == 'expirado')
                                ? 'Expirado'
                                : valueOrDefault<String>(order.pedidoNombre, 'Unknown'),
                        style: FlutterFlowTheme.of(context).headlineMedium.override(
                          font: GoogleFonts.interTight(
                            fontWeight: FlutterFlowTheme.of(context).headlineMedium.fontWeight,
                            fontStyle: FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                          ),
                          letterSpacing: 0.0,
                          fontWeight: FlutterFlowTheme.of(context).headlineMedium.fontWeight,
                          fontStyle: FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                        ),
                      ),
                    ),
                    Text(
                      formatNumber(order.totalPrice ?? 0.0, 
                        formatType: FormatType.decimal, 
                        decimalType: DecimalType.automatic),
                      style: FlutterFlowTheme.of(context).headlineSmall.override(
                        font: GoogleFonts.interTight(
                          fontWeight: FlutterFlowTheme.of(context).headlineSmall.fontWeight,
                          fontStyle: FlutterFlowTheme.of(context).headlineSmall.fontStyle,
                        ),
                        letterSpacing: 0.0,
                        fontWeight: FlutterFlowTheme.of(context).headlineSmall.fontWeight,
                        fontStyle: FlutterFlowTheme.of(context).headlineSmall.fontStyle,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 0.0, 0.0),
                      child: FlutterFlowIconButton(
                        borderColor: FlutterFlowTheme.of(context).alternate,
                        borderRadius: 20.0,
                        borderWidth: 1.0,
                        buttonSize: 40.0,
                        fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                        hoverColor: FlutterFlowTheme.of(context).alternate,
                        hoverIconColor: FlutterFlowTheme.of(context).primaryText,
                        icon: Icon(Icons.more_vert, color: FlutterFlowTheme.of(context).secondaryText, size: 24.0),
                        onPressed: () async {
                          await showAlignedDialog(
                            barrierColor: Colors.transparent,
                            context: context,
                            isGlobal: false,
                            avoidOverflow: true,
                            targetAnchor: const AlignmentDirectional(-1.0, 1.0).resolve(Directionality.of(context)),
                            followerAnchor: const AlignmentDirectional(-1.0, -1.0).resolve(Directionality.of(context)),
                            builder: (dialogContext) {
                              return Material(
                                color: Colors.transparent,
                                child: GestureDetector(
                                  onTap: () {
                                    FocusScope.of(dialogContext).unfocus();
                                    FocusManager.instance.primaryFocus?.unfocus();
                                  },
                                  child: DropdownMenuWidget(orderRef: order),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 8.0),
                  child: Text(
                    'Ordenado el: ${dateTimeFormat("yMMMd", order.createdAt)}',
                    style: FlutterFlowTheme.of(context).labelMedium.override(
                      font: GoogleFonts.inter(
                        fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                        fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                      ),
                      letterSpacing: 0.0,
                      fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                      fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                    ),
                  ),
                ),
                Divider(thickness: 1.0, color: FlutterFlowTheme.of(context).alternate),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 8.0),
                      child: FutureBuilder<List<PedidoItemsRow>>(
                        future: PedidoItemsTable().queryRows(queryFn: (q) => q.eq('pedido_id', order.id)),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return SizedBox(
                              width: 20, height: 20, 
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(FlutterFlowTheme.of(context).primary),
                              ),
                            );
                          }
                          return Text(
                            'Número de items: ${snapshot.data!.length}',
                            style: FlutterFlowTheme.of(context).labelMedium.override(
                              font: GoogleFonts.inter(
                                fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                              ),
                              letterSpacing: 0.0,
                              fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                              fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      height: 32.0,
                      decoration: BoxDecoration(
                        color: _getStatusColor(context),
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: (order.status == 'pendiente_pago') 
                              ? FlutterFlowTheme.of(context).tertiary 
                              : (order.status == 'confirmado' ? FlutterFlowTheme.of(context).secondary : FlutterFlowTheme.of(context).primary),
                          width: 2.0,
                        ),
                      ),
                      alignment: const AlignmentDirectional(0.0, 0.0),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                        child: Text(
                          order.status == 'pendiente_pago' ? 'Sin pagar' : valueOrDefault<String>(order.status, 'Unknown'),
                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.inter(
                              fontWeight: FontWeight.w500,
                              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                            ),
                            color: (order.status == 'pendiente_pago') 
                                ? FlutterFlowTheme.of(context).tertiary 
                                : (order.status == 'confirmado' ? FlutterFlowTheme.of(context).secondary : FlutterFlowTheme.of(context).primary),
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w500,
                            fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
