import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/full_cart_view/full_cart_view_model.dart';
import '/services/cart_service.dart';
import '/services/exchange_rate_service.dart';
import 'package:baul_pandora/backend/schema/structs/pago_struct.dart';

class ApartadoPaymentSheet extends StatefulWidget {
  final String pedidoId;
  final double saldoPendiente;

  const ApartadoPaymentSheet({
    super.key,
    required this.pedidoId,
    required this.saldoPendiente,
  });

  @override
  State<ApartadoPaymentSheet> createState() => _ApartadoPaymentSheetState();
}

class _ApartadoPaymentSheetState extends State<ApartadoPaymentSheet> {
  final _montoController = TextEditingController();
  String _moneda = 'USD';
  File? _imageFile;
  bool _isUploading = false;
  double _bcvRate = 0.0;

  @override
  void initState() {
    super.initState();
    _loadRate();
  }

  Future<void> _loadRate() async {
    try {
      final rate = await ExchangeRateService.instance.getBcvRate();
      setState(() => _bcvRate = rate);
    } catch (e) {
      print('Error loading rate: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _confirmPayment() async {
    final monto = double.tryParse(_montoController.text);
    if (monto == null || monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresá un monto válido')),
      );
      return;
    }

    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, subí el comprobante de pago')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final publicUrl = await CartService.instance.uploadPaymentProof(_imageFile!, widget.pedidoId);
      if (publicUrl == null) throw Exception('Error al subir el comprobante');

      final model = context.read<FullCartViewModel>();
      final pago = PagoStruct(
        montoVes: _moneda == 'VES' ? monto : 0.0,
        montoUsd: _moneda == 'USD' ? monto : monto / model.bcvRate,
        tasaAplicada: model.bcvRate,
        referencia: 'Pago Manual', // O obtener de un controlador
      );

      final result = await model.pagarApartado(
        pedidoId: widget.pedidoId,
        pago: pago,
        comprobante: publicUrl,
      );

      if (result['success']) {
        Navigator.pop(context, true);
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  String get _conversionText {
    if (_bcvRate == 0) return 'Cargando tasa...';
    if (_moneda == 'USD') {
      final vesAmount = double.parse(_montoController.text != '' ? _montoController.text : '0') * _bcvRate;
      return 'Aproximadamente ${formatNumber(vesAmount, formatType: FormatType.decimal, decimalType: DecimalType.automatic, currency: 'Bs.')}';
    }
    return 'Monto en Bolívares';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).alternate,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Completar Abono',
              style: FlutterFlowTheme.of(context).titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Saldo pendiente: \$${widget.saldoPendiente}',
              style: FlutterFlowTheme.of(context).bodyMedium,
            ),
            if (_bcvRate > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Text(
                      '${formatNumber(widget.saldoPendiente * _bcvRate, formatType: FormatType.decimal, decimalType: DecimalType.automatic, currency: 'Bs.')}',
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.content_copy, size: 16),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(
                            text: (widget.saldoPendiente * _bcvRate)
                                .toStringAsFixed(2)));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Monto en Bs. copiado')),
                        );
                      },
                    )
                  ],
                ),
              ),
            const SizedBox(height: 24),
            
            Text('Monto del abono', style: FlutterFlowTheme.of(context).labelMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _montoController,
              keyboardType: TextInputType.number,
              onChanged: (val) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Ej: 10.00',
                prefixText: '\$ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _conversionText,
              style: FlutterFlowTheme.of(context).bodySmall.override(fontFamily: 'Inter', color: FlutterFlowTheme.of(context).secondaryText),
            ),
            const SizedBox(height: 16),

            Text('Moneda', style: FlutterFlowTheme.of(context).labelMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _moneda,
              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: ['USD', 'VES'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => _moneda = val!),
            ),
            const SizedBox(height: 16),

            Text('Comprobante de pago', style: FlutterFlowTheme.of(context).labelMedium),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: FlutterFlowTheme.of(context).alternate),
                ),
                child: _imageFile == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload, color: FlutterFlowTheme.of(context).secondaryText),
                          Text('Tocar para subir imagen', style: FlutterFlowTheme.of(context).bodySmall),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: FlutterFlowTheme.of(context).primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isUploading ? null : _confirmPayment,
                child: _isUploading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Confirmar Abono', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
