import 'package:flutter/material.dart';
import 'package:baul_pandora/components/barcode_scanner_modal.dart' as baul_pandora;
import 'package:image_picker/image_picker.dart';
import 'package:baul_pandora/services/ai/ai_product_service.dart';

import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/backend/supabase/database/tables/productos.dart';
import 'stock_update_model.dart';

class StockUpdateWidget extends StatefulWidget {
  const StockUpdateWidget({super.key});

  @override
  State<StockUpdateWidget> createState() => _StockUpdateWidgetState();
}

class _StockUpdateWidgetState extends State<StockUpdateWidget> {
  late StockUpdateModel _model;

  @override
  void initState() {
    super.initState();
    _model = StockUpdateModel();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void _handleSearch(String value) async {
    await _model.searchProducts(value);
    if (mounted) {
      setState(() {});
    }
  }

  void _handleQuickCreate() async {
    final newProduct = await _model.createQuickProduct();
    if (newProduct != null) {
      setState(() {
        _model.isCreatingNew = false;
        _model.newProductNameController.clear();
        _model.newProductPriceController.clear();
        // Add to batch with 0 first so user can set quantity, 
        // or just let them search for it now.
        _model.addToBatch(newProduct);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto creado exitosamente')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Nombre requerido')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.sizeOf(context).width * 0.9,
      constraints: const BoxConstraints(maxWidth: 600),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black.withValues(alpha: 0.2),
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 10),
            child: Text(
              'Carga de Inventario',
              style: FlutterFlowTheme.of(context).headlineSmall.override(
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Scrollable middle section
          // Scrollable middle section
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_model.currentStep == 1) ...[
                    // Search Section (Paso 1)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          TextField(
                            controller: _model.searchController,
                            onChanged: _handleSearch,
                            decoration: InputDecoration(
                              hintText: 'Buscar producto...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.qr_code_scanner),
                                    onPressed: () async {
                                      final code = await Navigator.push<String>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const baul_pandora.BarcodeScannerModal(),
                                        ),
                                      );
                                      if (code != null && code.isNotEmpty) {
                                        _model.searchController.text = code;
                                        _handleSearch(code);
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.image_search),
                                    onPressed: () async {
                                      final picker = ImagePicker();
                                      final xfile = await picker.pickImage(source: ImageSource.gallery);
                                      if (xfile != null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Analizando imagen para buscar...')),
                                        );
                                        final bytes = await xfile.readAsBytes();
                                        try {
                                          final keyword = await AIProductService.instance.identifyProductForSearch(bytes);
                                          if (keyword != null && keyword.isNotEmpty) {
                                            _model.searchController.text = keyword;
                                            _handleSearch(keyword);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Buscando: $keyword')),
                                              );
                                            }
                                          } else {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('No se pudo identificar el producto en la imagen')),
                                              );
                                            }
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Error de IA: ${e.toString().replaceAll('Exception:', '')}')),
                                            );
                                          }
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: FlutterFlowTheme.of(context).primaryBackground,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (!_model.isCreatingNew)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () => setState(() => _model.isCreatingNew = true),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Agregar Nuevo Producto'),
                                style: TextButton.styleFrom(
                                  foregroundColor: FlutterFlowTheme.of(context).primary,
                                ),
                              ),
                            ),
                          const SizedBox(height: 10),
                          if (_model.isCreatingNew)
                            _buildQuickCreateForm()
                          else if (_model.searchResults.isEmpty && _model.searchController.text.isNotEmpty)
                            _buildNoResults()
                          else if (_model.searchResults.isNotEmpty)
                            _buildSearchResults(),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Batch Queue Section (Paso 2)
                    if (_model.batchQueue.isNotEmpty)
                      _buildBatchQueue()
                    else
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No hay productos seleccionados.'),
                      ),
                  ],
                ],
              ),
            ),
          ),

          // Footer Actions
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_model.currentStep == 1) ...[
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _model.batchQueue.clear();
                        _model.searchController.clear();
                        _model.searchResults.clear();
                      });
                    },
                    child: const Text('Limpiar Búsqueda'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _model.batchQueue.isEmpty 
                      ? null 
                      : () => setState(() => _model.currentStep = 2),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FlutterFlowTheme.of(context).primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Siguiente: Configurar ${_model.batchQueue.length}'),
                  ),
                ] else ...[
                  TextButton(
                    onPressed: () => setState(() => _model.currentStep = 1),
                    child: const Text('Volver a Selección'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _model.isProcessing ? null : _processBatch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FlutterFlowTheme.of(context).primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _model.isProcessing 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Confirmar Actualización'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        children: [
          Text(
            'No se encontraron productos',
            style: FlutterFlowTheme.of(context).bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _model.searchResults.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final product = _model.searchResults[index];
          return _buildProductSearchResultItem(product);
        },
      ),
    );
  }

  // Correcting the search result item to handle its own product
  Widget _buildProductSearchResultItem(ProductosRow product) {
    final isSelected = _model.isSelected(product);
    return CheckboxListTile(
      title: Text(product.nombre),
      subtitle: Text('Stock actual: ${product.stock}'),
      value: isSelected,
      activeColor: FlutterFlowTheme.of(context).primary,
      onChanged: (bool? value) {
        setState(() {
          _model.toggleSelection(product);
        });
      },
    );
  }

  Widget _buildBatchQueue() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            'Cola de Carga',
            style: FlutterFlowTheme.of(context).titleMedium,
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _model.batchQueue.length,
          itemBuilder: (context, index) {
            final item = _model.batchQueue[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.product.nombre,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            setState(() => _model.batchQueue.removeAt(index));
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Cantidad
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: item.quantityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Cant.',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Tipo (Ingreso / Egreso)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<bool>(
                              value: item.isIngreso,
                              items: const [
                                DropdownMenuItem(value: true, child: Text('Ingreso', style: TextStyle(color: Colors.green))),
                                DropdownMenuItem(value: false, child: Text('Egreso', style: TextStyle(color: Colors.red))),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    item.isIngreso = val;
                                    // Cambiar motivo por defecto al cambiar el tipo
                                    item.reason = val ? 'Compra' : 'Venta';
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Razón
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: item.reason,
                                items: (item.isIngreso 
                                    ? ['Compra', 'Devolución', 'Ajuste'] 
                                    : ['Venta', 'Avería', 'Ajuste']
                                ).map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => item.reason = val);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _processBatch() async {
    setState(() => _model.isProcessing = true);
    final success = await _model.processBatch();
    setState(() => _model.isProcessing = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inventario actualizado correctamente')),
        );
      }
      setState(() => _model.batchQueue.clear());
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al procesar la carga')),
        );
      }
    }
  }

  // Integrating Quick Create Form
  Widget _buildQuickCreateForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FlutterFlowTheme.of(context).alternate),
      ),
      child: Column(
        children: [
          Text('Nuevo Producto', style: FlutterFlowTheme.of(context).titleSmall),
          const SizedBox(height: 10),
          TextField(
            controller: _model.newProductNameController,
            decoration: const InputDecoration(labelText: 'Nombre'),
          ),
          TextField(
            controller: _model.newProductPriceController,
            decoration: const InputDecoration(labelText: 'Precio'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => setState(() => _model.isCreatingNew = false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: _handleQuickCreate,
                child: const Text('Crear y Agregar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
