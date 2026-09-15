import 'package:flutter/material.dart';
import 'package:baul_pandora/backend/supabase/storage/storage.dart';

import 'package:baul_pandora/flutter_flow/upload_data.dart';

import 'package:image_picker/image_picker.dart';
import 'package:baul_pandora/services/ai/ai_product_service.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/index.dart';
import 'package:baul_pandora/components/stock_update_modal/stock_update_widget.dart';
import 'package:baul_pandora/components/barcode_scanner_modal.dart' as baul_pandora;
import 'package:baul_pandora/services/woocommerce_sync_service.dart';
import 'package:baul_pandora/pages/administracion/components/bulk_product_import_modal.dart';

class AdminProductsView extends StatefulWidget {
  const AdminProductsView({super.key});

  @override
  State<AdminProductsView> createState() => _AdminProductsViewState();
}

class _AdminProductsViewState extends State<AdminProductsView> {
  int _selectedTab = 0; // 0 for Products, 1 for Categories
  String _searchQuery = '';
  String? _selectedCategory;
  List<String> _categories = [];
  bool _isLoading = true;
  bool _isSyncing = false;

  int _currentProdPage = 1;
  int _prodPageSize = 25;
  int _totalProducts = 0;
  List<ProductosRow> _productsList = [];
  bool _isLoadingProducts = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _handleSync() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⏳ Sincronizando catálogo con la base de datos...'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      final result = await WooCommerceSyncService().syncAllProducts();
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message,
              style: const TextStyle(fontSize: 13, height: 1.3),
            ),
            backgroundColor: result.success ? const Color(0xFF16A34A) : Colors.red,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _loadInitialData();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en sincronización: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (context.mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  void _showSimpleCategoryDialog([CategoriasRow? categoryToEdit]) {
    final nombreController = TextEditingController(text: categoryToEdit?.nombre ?? '');
    final descripcionController = TextEditingController(text: categoryToEdit?.descripcion ?? '');
    String? selectedParentId = categoryToEdit?.parentId;
    bool isSaving = false;
    String? photoUrl = categoryToEdit?.photoPath;
    bool isUploadingImage = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(categoryToEdit == null ? 'Nueva Categoría' : 'Editar Categoría', style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de la categoría *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descripcionController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Descripción (opcional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<List<CategoriasRow>>(
                        future: CategoriasTable().queryRows(
                          queryFn: (q) => q,
                        ),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox.shrink();
                          final parents = snapshot.data!;
                          if (parents.isEmpty) return const SizedBox.shrink();
                          
                          // SAFEGUARD: Ensure selectedParentId exists in the filtered parents list
                          final validParents = parents.where((p) => p.id != categoryToEdit?.id).toList();
                          if (selectedParentId != null && !validParents.any((p) => p.id == selectedParentId)) {
                            selectedParentId = null; // Reset if parent is missing or invalid
                          }

                          return DropdownButtonFormField<String>(
                            value: selectedParentId,
                            decoration: const InputDecoration(
                              labelText: 'Categoría Padre (opcional)',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Ninguna (Categoría Principal)'),
                              ),
                              ...validParents.map((p) => DropdownMenuItem<String>(
                                value: p.id,
                                child: Text(p.nombre ?? 'Sin nombre'),
                              )),
                            ],
                            onChanged: (val) {
                              setModalState(() => selectedParentId = val);
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Text('Imagen de la categoría', style: FlutterFlowTheme.of(context).bodyMedium.override(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final selectedMedia = await selectMediaWithSourceBottomSheet(
                            context: context,
                            storageFolderPath: 'categorias/',
                            allowPhoto: true,
                            allowMultiple: false,
                          );
                          if (selectedMedia != null && selectedMedia.every((m) => validateFileFormat(m.storagePath, context))) {
                            setModalState(() => isUploadingImage = true);
                            try {
                              final downloadUrls = await uploadSupabaseStorageFiles(
                                bucketName: 'images',
                                selectedFiles: selectedMedia,
                              );
                              if (downloadUrls.isNotEmpty) {
                                setModalState(() => photoUrl = downloadUrls.first);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al subir imagen: $e')));
                              }
                            } finally {
                              setModalState(() => isUploadingImage = false);
                            }
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          height: 150,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).secondaryBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: FlutterFlowTheme.of(context).alternate),
                          ),
                          child: isUploadingImage
                              ? const Center(child: CircularProgressIndicator())
                              : (photoUrl != null && photoUrl!.isNotEmpty)
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(photoUrl!, fit: BoxFit.cover),
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_photo_alternate, size: 40, color: FlutterFlowTheme.of(context).secondaryText),
                                        const SizedBox(height: 8),
                                        Text('Toca para subir imagen', style: FlutterFlowTheme.of(context).bodyMedium),
                                      ],
                                    ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    final name = nombreController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Por favor, ingresa el nombre de la categoría')),
                      );
                      return;
                    }

                    setModalState(() => isSaving = true);
                    try {
                      if (categoryToEdit == null) {
                        await CategoriasTable().insert({
                          'nombre': name,
                          'descripcion': descripcionController.text.trim(),
                          'parent_id': selectedParentId,
                          'photo_path': photoUrl,
                        });
                      } else {
                        await CategoriasTable().update(
                          data: {
                            'nombre': name,
                            'descripcion': descripcionController.text.trim(),
                            'parent_id': selectedParentId,
                            'photo_path': photoUrl,
                          },
                          matchingRows: (q) => q.eq('id', categoryToEdit.id),
                        );
                      }
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(categoryToEdit == null ? 'Categoría creada exitosamente' : 'Categoría actualizada exitosamente'), backgroundColor: Colors.green),
                        );
                      }
                      setState(() {});
                    } catch (e) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text('Error al crear la categoría: $e'), backgroundColor: Colors.red),
                        );
                      }
                    } finally {
                      setModalState(() => isSaving = false);
                    }
                  },
                  child: isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final cats = await CategoriasTable().queryRows(queryFn: (q) => q);
      setState(() {
        _categories = cats.map((c) => c.nombre ?? 'Sin nombre').toList();
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
    } finally {
      setState(() => _isLoading = false);
    }
    await _loadProducts();
  }

  Future<void> _loadProducts({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentProdPage = 1;
    }
    setState(() => _isLoadingProducts = true);

    try {
      final from = (_currentProdPage - 1) * _prodPageSize;
      final to = from + _prodPageSize - 1;

      dynamic query = SupaFlow.client.from('productos').select('*').eq('es_variacion', false);
      dynamic countQuery = SupaFlow.client.from('productos').select('*').eq('es_variacion', false);

      if (FFAppState().activeStoreId.isNotEmpty) {
        query = query.eq('tienda_id', FFAppState().activeStoreId);
        countQuery = countQuery.eq('tienda_id', FFAppState().activeStoreId);
      }

      if (_searchQuery.isNotEmpty) {
        final isUuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false).hasMatch(_searchQuery);
        if (isUuid) {
          query = query.eq('id', _searchQuery);
          countQuery = countQuery.eq('id', _searchQuery);
        } else if (RegExp(r'^[0-9]+$').hasMatch(_searchQuery) && _searchQuery.length >= 8) {
          query = query.eq('codigo_barras', _searchQuery);
          countQuery = countQuery.eq('codigo_barras', _searchQuery);
        } else {
          query = query.ilike('nombre', '%$_searchQuery%');
          countQuery = countQuery.ilike('nombre', '%$_searchQuery%');
        }
      }

      final countRes = await countQuery.count(CountOption.exact);
      final int total = countRes.count ?? 0;

      final dataRes = await query
          .order('nombre', ascending: true)
          .range(from, to);

      final list = (dataRes as List).map((r) => ProductosRow(r)).toList();

      if (mounted) {
        setState(() {
          _productsList = list;
          _totalProducts = total;
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando productos: $e');
      if (mounted) {
        setState(() => _isLoadingProducts = false);
      }
    }
  }

  void _goToProdPage(int page) {
    final totalPages = (_totalProducts / _prodPageSize).ceil() == 0 ? 1 : (_totalProducts / _prodPageSize).ceil();
    if (page < 1 || page > totalPages || page == _currentProdPage) return;
    setState(() => _currentProdPage = page);
    _loadProducts();
  }

  void _changeProdPageSize(int newSize) {
    if (newSize == _prodPageSize) return;
    setState(() {
      _prodPageSize = newSize;
      _currentProdPage = 1;
    });
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading 
      ? const Center(child: CircularProgressIndicator())
      : Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: MediaQuery.of(context).size.width < 600
              ? PopupMenuButton<int>(
                  offset: const Offset(0, -100),
                  onSelected: (value) async {
                    if (value == 1) {
                      if (_selectedTab == 0) {
                        context.pushNamed(ProductCreateWidget.routeName);
                      } else {
                        _showSimpleCategoryDialog();
                      }
                    } else if (value == 2 && _selectedTab == 0) {
                      await showDialog(
                        context: context,
                        builder: (dialogContext) {
                          return Dialog(
                            elevation: 0,
                            insetPadding: EdgeInsets.zero,
                            backgroundColor: Colors.transparent,
                            alignment: const AlignmentDirectional(0.0, 0.0)
                                .resolve(Directionality.of(context)),
                            child: const StockUpdateWidget(),
                          );
                        },
                      );
                    } else if (value == 3) {
                      await _handleSync();
                    } else if (value == 4) {
                      await showDialog(
                        context: context,
                        builder: (dialogContext) => BulkProductImportModal(
                          onImportCompleted: () {
                            _loadProducts(isRefresh: true);
                          },
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 1,
                      child: Row(
                        children: [
                          const Icon(Icons.add, size: 20),
                          const SizedBox(width: 8),
                          Text(_selectedTab == 0 ? 'Nuevo Producto' : 'Nueva Categoría'),
                        ],
                      ),
                    ),
                    if (_selectedTab == 0)
                      PopupMenuItem(
                        value: 4,
                        child: Row(
                          children: [
                            const Icon(Icons.file_upload_outlined, size: 20, color: Color(0xFF0284C7)),
                            const SizedBox(width: 8),
                            const Text('Importar CSV / Excel'),
                          ],
                        ),
                      ),
                    if (_selectedTab == 0)
                      PopupMenuItem(
                        value: 2,
                        child: Row(
                          children: [
                            const Icon(Icons.inventory, size: 20),
                            const SizedBox(width: 8),
                            const Text('Actualizar Stock'),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 3,
                      child: Row(
                        children: [
                          const Icon(Icons.sync, size: 20, color: Color(0xFF16A34A)),
                          const SizedBox(width: 8),
                          const Text('Sincronizar Woo (BD)'),
                        ],
                      ),
                    ),
                  ],
                  child: FloatingActionButton(
                    onPressed: null, // Handled by PopupMenuButton
                    backgroundColor: FlutterFlowTheme.of(context).primary,
                    child: Icon(Icons.add, color: FlutterFlowTheme.of(context).primaryText),
                  ),
                )
              : null,
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              MediaQuery.of(context).size.width < 600
                  ? Text(
                      _selectedTab == 0 ? 'Gestión de Productos' : 'Gestión de Categorías',
                      style: FlutterFlowTheme.of(context).headlineMedium.override(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        fontSize: 20.0,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedTab == 0 ? 'Gestión de Productos' : 'Gestión de Categorías',
                          style: FlutterFlowTheme.of(context).headlineMedium.override(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.bold,
                            fontSize: 24.0,
                          ),
                        ),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _isSyncing ? null : _handleSync,
                              icon: _isSyncing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.sync),
                              label: Text(_isSyncing ? 'Sincronizando...' : 'Sincronizar Woo'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF16A34A),
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                if (_selectedTab == 0) {
                                  context.pushNamed(ProductCreateWidget.routeName);
                                } else {
                                  _showSimpleCategoryDialog();
                                }
                              },
                              icon: const Icon(Icons.add),
                              label: Text(_selectedTab == 0 ? 'Nuevo Producto' : 'Nueva Categoría'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: FlutterFlowTheme.of(context).primary,
                                foregroundColor: FlutterFlowTheme.of(context).primaryText,
                              ),
                            ),
                            if (_selectedTab == 0) ...[
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await showDialog(
                                    context: context,
                                    builder: (dialogContext) => BulkProductImportModal(
                                      onImportCompleted: () {
                                        _loadProducts(isRefresh: true);
                                      },
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.file_upload_outlined),
                                label: const Text('Importar CSV / Excel'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0284C7),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                            if (_selectedTab == 0) ...[
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await showDialog(
                                    context: context,
                                    builder: (dialogContext) {
                                      return Dialog(
                                        elevation: 0,
                                        insetPadding: EdgeInsets.zero,
                                        backgroundColor: Colors.transparent,
                                        alignment: const AlignmentDirectional(0.0, 0.0)
                                            .resolve(Directionality.of(context)),
                                        child: const StockUpdateWidget(),
                                      );
                                    },
                                  );
                                },
                                icon: const Icon(Icons.inventory),
                                label: const Text('Actualizar Stock'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: FlutterFlowTheme.of(context).secondary,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
              const SizedBox(height: 24),
              
              // Tab Switcher
              Container(
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: FlutterFlowTheme.of(context).alternate),
                ),
                child: Row(
                  children: [
                    _buildTabItem(0, 'Productos', Icons.inventory_2_rounded),
                    _buildTabItem(1, 'Categorías', Icons.category_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              if (_selectedTab == 0) ...[
                _buildProductFilters(),
                const SizedBox(height: 16),
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
                      child: _isLoadingProducts
                          ? const Center(child: CircularProgressIndicator())
                          : _buildProductTable(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildProdPaginationBar(FlutterFlowTheme.of(context), MediaQuery.of(context).size.width >= 900),
              ] else ...[
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
                      child: _buildCategoryTable(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
  }

  Widget _buildTabItem(int index, String label, IconData icon) {
    final bool isActive = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
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

  Widget _buildProductFilters() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            onSubmitted: (val) {
              setState(() {
                _searchQuery = val.trim();
                _currentProdPage = 1;
              });
              _loadProducts();
            },
            onChanged: (val) {
              if (val.trim() != _searchQuery) {
                _searchQuery = val.trim();
                _currentProdPage = 1;
                _loadProducts();
              }
            },
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
                        setState(() {
                          _searchQuery = code;
                          _currentProdPage = 1;
                        });
                        _loadProducts();
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
                            setState(() {
                              _searchQuery = keyword;
                              _currentProdPage = 1;
                            });
                            _loadProducts();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Buscando: $keyword')),
                              );
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('No se pudo identificar el producto')),
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
              fillColor: FlutterFlowTheme.of(context).secondaryBackground,
            ),
          ),
        ),
        const SizedBox(width: 8),
        MediaQuery.of(context).size.width < 600
            ? PopupMenuButton<String>(
                icon: Icon(
                  Icons.filter_list_alt,
                  color: _selectedCategory != null 
                      ? FlutterFlowTheme.of(context).primary 
                      : FlutterFlowTheme.of(context).secondaryText,
                ),
                tooltip: 'Filtrar por categoría',
                initialValue: _selectedCategory,
                onSelected: (val) {
                  setState(() {
                    if (val == 'clear_filter') {
                      _selectedCategory = null;
                    } else {
                      _selectedCategory = val;
                    }
                    _currentProdPage = 1;
                  });
                  _loadProducts();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'clear_filter',
                    child: Text('Todas las categorías'),
                  ),
                  const PopupMenuDivider(),
                  ..._categories.map((cat) => PopupMenuItem(
                    value: cat,
                    child: Text(cat, overflow: TextOverflow.ellipsis),
                  )),
                ],
              )
            : Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    hintText: 'Categoría',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Todas las categorías'),
                    ),
                    ..._categories.map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat, overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedCategory = val;
                      _currentProdPage = 1;
                    });
                    _loadProducts();
                  },
                ),
              ),
      ],
    );
  }

  Widget _buildProductTable() {
    if (_productsList.isEmpty) {
      return const Center(child: Text('No se encontraron productos'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        double nameWidth = constraints.maxWidth < 600 
            ? 120 
            : (constraints.maxWidth - 400 > 250 ? constraints.maxWidth - 400 : 250);

        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                columnSpacing: 20,
                headingRowColor: WidgetStateProperty.all(FlutterFlowTheme.of(context).secondaryBackground),
                showCheckboxColumn: false,
                columns: const [
                  DataColumn(label: Text('Imagen')),
                  DataColumn(label: Text('Nombre')),
                  DataColumn(label: Text('Stock')),
                  DataColumn(label: Text('Precio')),
                  DataColumn(label: Text('Acciones')),
                ],
                rows: _productsList.map((p) => DataRow(
                  onSelectChanged: (selected) {
                    if (selected == true) {
                      context.pushNamed(
                        ProductCreateWidget.routeName,
                        extra: <String, dynamic>{
                          'productRow': p,
                        },
                      );
                    }
                  },
                  cells: [
                    DataCell(CircleAvatar(backgroundImage: NetworkImage(((p.imagePath?.length ?? 0) > 0) ? p.imagePath?.firstOrNull ?? '' : ''))),
                    DataCell(
                      SizedBox(
                        width: nameWidth,
                        child: Text(
                          p.nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(Text(p.stock.toString())),
                    DataCell(Text('\$${p.precio?.toStringAsFixed(2) ?? '0.00'}')),
                    DataCell(Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () {
                            context.pushNamed(
                              ProductCreateWidget.routeName,
                              extra: <String, dynamic>{
                                'productRow': p,
                              },
                            );
                          },
                        ),
                        IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () {}),
                      ],
                    )),
                  ],
                )).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProdPaginationBar(FlutterFlowTheme theme, bool isDesktop) {
    final totalPages = (_totalProducts / _prodPageSize).ceil() == 0 ? 1 : (_totalProducts / _prodPageSize).ceil();
    final startItem = _totalProducts == 0 ? 0 : (_currentProdPage - 1) * _prodPageSize + 1;
    final endItem = ((_currentProdPage - 1) * _prodPageSize + _productsList.length).clamp(0, _totalProducts);

    final canGoPrev = _currentProdPage > 1;
    final canGoNext = _currentProdPage < totalPages;

    final infoWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Mostrar: ',
          style: TextStyle(fontSize: 12, color: theme.secondaryText),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: theme.alternate),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _prodPageSize,
              isDense: true,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.primaryText),
              items: const [
                DropdownMenuItem(value: 15, child: Text('15')),
                DropdownMenuItem(value: 25, child: Text('25')),
                DropdownMenuItem(value: 50, child: Text('50')),
                DropdownMenuItem(value: 100, child: Text('100')),
              ],
              onChanged: (val) {
                if (val != null) _changeProdPageSize(val);
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Mostrando $startItem-$endItem de $_totalProducts',
          style: TextStyle(fontSize: 12, color: theme.secondaryText, fontWeight: FontWeight.w500),
        ),
      ],
    );

    final navButtons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.first_page_rounded, size: 20),
          onPressed: canGoPrev ? () => _goToProdPage(1) : null,
          tooltip: 'Primera página',
          color: theme.primaryText,
          disabledColor: theme.secondaryText.withValues(alpha: 0.3),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 20),
          onPressed: canGoPrev ? () => _goToProdPage(_currentProdPage - 1) : null,
          tooltip: 'Página anterior',
          color: theme.primaryText,
          disabledColor: theme.secondaryText.withValues(alpha: 0.3),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: theme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$_currentProdPage / $totalPages',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.primary,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded, size: 20),
          onPressed: canGoNext ? () => _goToProdPage(_currentProdPage + 1) : null,
          tooltip: 'Página siguiente',
          color: theme.primaryText,
          disabledColor: theme.secondaryText.withValues(alpha: 0.3),
        ),
        IconButton(
          icon: const Icon(Icons.last_page_rounded, size: 20),
          onPressed: canGoNext ? () => _goToProdPage(totalPages) : null,
          tooltip: 'Última página',
          color: theme.primaryText,
          disabledColor: theme.secondaryText.withValues(alpha: 0.3),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.alternate),
      ),
      child: isDesktop
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                infoWidget,
                navButtons,
              ],
            )
          : Column(
              children: [
                infoWidget,
                const SizedBox(height: 4),
                navButtons,
              ],
            ),
    );
  }

  Widget _buildCategoryTable() {
    return FutureBuilder<List<CategoriasRow>>(
      future: CategoriasTable().queryRows(queryFn: (q) => q),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final categories = snapshot.data!;
        if (categories.isEmpty) return const Center(child: Text('No hay categorías creadas'));

        return Column(
          children: [
            // Custom Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: FlutterFlowTheme.of(context).secondaryBackground,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nombre',
                    style: FlutterFlowTheme.of(context).titleSmall.override(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Acciones',
                    style: FlutterFlowTheme.of(context).titleSmall.override(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: categories.length,
                separatorBuilder: (context, index) => Divider(color: FlutterFlowTheme.of(context).alternate),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: InkWell(
                      onTap: () => _showSimpleCategoryDialog(category),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: FlutterFlowTheme.of(context).alternate,
                                  backgroundImage: (category.photoPath != null && category.photoPath!.isNotEmpty)
                                      ? NetworkImage(category.photoPath!)
                                      : null,
                                  child: (category.photoPath == null || category.photoPath!.isEmpty)
                                      ? Icon(Icons.image, color: FlutterFlowTheme.of(context).secondaryText, size: 20)
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    category.nombre ?? 'Sin nombre',
                                    style: FlutterFlowTheme.of(context).bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () => _showSimpleCategoryDialog(category),
                              ),
                            IconButton(
                                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
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

}
