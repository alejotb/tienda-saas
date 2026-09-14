import 'package:flutter/material.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';

class SearchSidebarFilters extends StatefulWidget {
  const SearchSidebarFilters({
    super.key,
    this.selectedCategoryId,
    this.minPrice,
    this.maxPrice,
    this.sortBy = 'created_at',
    this.inStockOnly = false,
    required this.onFiltersApplied,
  });

  final String? selectedCategoryId;
  final double? minPrice;
  final double? maxPrice;
  final String sortBy;
  final bool inStockOnly;
  final Function(String? categoryId, double? minPrice, double? maxPrice, String sortBy, bool inStockOnly) onFiltersApplied;

  @override
  State<SearchSidebarFilters> createState() => _SearchSidebarFiltersState();
}

class _SearchSidebarFiltersState extends State<SearchSidebarFilters> {
  String? localCategoryId;
  final TextEditingController minPriceController = TextEditingController();
  final TextEditingController maxPriceController = TextEditingController();
  String localSortBy = 'created_at';
  bool localInStockOnly = false;

  @override
  void initState() {
    super.initState();
    localCategoryId = widget.selectedCategoryId;
    if (widget.minPrice != null) minPriceController.text = widget.minPrice.toString();
    if (widget.maxPrice != null) maxPriceController.text = widget.maxPrice.toString();
    localSortBy = widget.sortBy;
    localInStockOnly = widget.inStockOnly;
  }

  @override
  void dispose() {
    minPriceController.dispose();
    maxPriceController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    double? minP = double.tryParse(minPriceController.text);
    double? maxP = double.tryParse(maxPriceController.text);
    widget.onFiltersApplied(localCategoryId, minP, maxP, localSortBy, localInStockOnly);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        border: Border(
          right: BorderSide(
            color: FlutterFlowTheme.of(context).alternate,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Filtros', style: FlutterFlowTheme.of(context).titleLarge),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                Text('Categorías', style: FlutterFlowTheme.of(context).titleMedium),
                const SizedBox(height: 8),
                FutureBuilder<List<CategoriasRow>>(
                  future: CategoriasTable().queryRows(queryFn: (q) => q.order('nombre', ascending: true)),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final cats = snapshot.data!;
                    final parents = cats.where((c) => c.parentId == null || c.parentId!.isEmpty || c.parentId == '0').toList();
                    return Column(
                      children: [
                        ListTile(
                          title: const Text('Todas las categorías', style: TextStyle(fontWeight: FontWeight.bold)),
                          selected: localCategoryId == null,
                          selectedTileColor: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.1),
                          onTap: () => setState(() => localCategoryId = null),
                        ),
                        ...parents.map((parent) {
                          final children = cats.where((c) => c.parentId == parent.id).toList();
                          final isParentSelected = parent.id == localCategoryId;
                          
                          if (children.isEmpty) {
                            return ListTile(
                              title: Text(parent.nombre ?? ''),
                              selected: isParentSelected,
                              selectedTileColor: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.1),
                              onTap: () => setState(() => localCategoryId = parent.id),
                            );
                          }
                          
                          return ExpansionTile(
                            title: Text(parent.nombre ?? ''),
                            initiallyExpanded: isParentSelected || children.any((c) => c.id == localCategoryId),
                            children: [
                              ListTile(
                                title: Text('Ver todo en ${parent.nombre}', style: const TextStyle(fontStyle: FontStyle.italic)),
                                selected: isParentSelected,
                                selectedTileColor: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.1),
                                onTap: () => setState(() => localCategoryId = parent.id),
                              ),
                              ...children.map((c) {
                                final isSelected = c.id == localCategoryId;
                                return ListTile(
                                  title: Text(c.nombre ?? ''),
                                  contentPadding: const EdgeInsets.only(left: 40.0, right: 16.0),
                                  selected: isSelected,
                                  selectedTileColor: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.1),
                                  onTap: () => setState(() => localCategoryId = c.id),
                                );
                              }),
                            ],
                          );
                        }),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                
                Text('Rango de Precio', style: FlutterFlowTheme.of(context).titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Min',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: maxPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Max',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Text('Ordenar por', style: FlutterFlowTheme.of(context).titleMedium),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: localSortBy,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                  items: const [
                    DropdownMenuItem(value: 'created_at', child: Text('Más recientes')),
                    DropdownMenuItem(value: 'precio_asc', child: Text('Precio: Menor a Mayor')),
                    DropdownMenuItem(value: 'precio_desc', child: Text('Precio: Mayor a Menor')),
                    DropdownMenuItem(value: 'nombre_asc', child: Text('Nombre: A - Z')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => localSortBy = val);
                  },
                ),
                const SizedBox(height: 16),
                
                SwitchListTile(
                  title: const Text('En stock solamente'),
                  value: localInStockOnly,
                  onChanged: (val) => setState(() => localInStockOnly = val),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _applyFilters,
                icon: const Icon(Icons.search),
                label: const Text('Buscar / Aplicar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FlutterFlowTheme.of(context).primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
