import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/components/empty_categoria/empty_categoria_widget.dart';
import 'package:baul_pandora/dropdowns/dropdown_categorias_destacadas/dropdown_categorias_destacadas_widget.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/flutter_flow/custom_functions.dart' as functions;
import 'package:flutter/material.dart';
import '../main_home_page_model.dart';

class FeaturedCategoriesWidget extends StatelessWidget {
  const FeaturedCategoriesWidget({
    super.key,
    required this.model,
    required this.updateCallback,
  });

  final MainHomePageModel model;
  final Future<void> Function() updateCallback;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return FutureBuilder<List<CategoriasRow>>(
      future: CategoriasTable().queryRows(
        queryFn: (q) => q.eq('destacada', true),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 80.0,
            child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }
        final listViewCategoriasRowList = snapshot.data!;
        if (listViewCategoriasRowList.isEmpty && !model.isAdmin) {
          return const SizedBox.shrink();
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Header compacto
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Categorías destacadas',
                    style: theme.titleMedium.override(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.0,
                    ),
                  ),
                  if (model.isAdmin)
                    InkWell(
                      onTap: () async {
                        await showDialog(
                          context: context,
                          builder: (dialogContext) {
                            return Dialog(
                              elevation: 0,
                              insetPadding: EdgeInsets.zero,
                              backgroundColor: Colors.transparent,
                              alignment: const AlignmentDirectional(0.0, 0.0).resolve(
                                Directionality.of(context),
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  FocusScope.of(dialogContext).unfocus();
                                  FocusManager.instance.primaryFocus?.unfocus();
                                },
                                child: const DropdownCategoriasDestacadasWidget(),
                              ),
                            );
                          },
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 16.0, color: theme.secondaryText),
                            const SizedBox(width: 4),
                            Text('Editar', style: theme.bodySmall.override(fontFamily: 'Inter', color: theme.secondaryText)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Carrusel horizontal compacto
            SizedBox(
              height: 75.0,
              child: listViewCategoriasRowList.isEmpty
                  ? EmptyCategoriaWidget(
                      icon: Icon(
                        Icons.apps_outage,
                        color: theme.primary,
                        size: 36.0,
                      ),
                      title: 'No hay categorías destacadas',
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      primary: false,
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: listViewCategoriasRowList.length,
                      itemBuilder: (context, listViewIndex) {
                        final cat = listViewCategoriasRowList[listViewIndex];

                        return Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 10.0, 0.0),
                          child: InkWell(
                            splashColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            borderRadius: BorderRadius.circular(10.0),
                            onTap: () {
                              context.pushNamed(
                                'searchResults',
                                queryParameters: {
                                  'category': cat.id,
                                }.withoutNulls,
                              );
                            },
                            child: Container(
                              width: 125.0,
                              height: 75.0,
                              decoration: BoxDecoration(
                                color: theme.secondaryBackground,
                                image: cat.photoPath != null && cat.photoPath!.isNotEmpty
                                    ? DecorationImage(
                                        fit: BoxFit.cover,
                                        image: NetworkImage(
                                          functions.getProxyUrl(cat.photoPath),
                                        ),
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(10.0),
                                border: Border.all(
                                  color: theme.alternate,
                                  width: 1.0,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    blurRadius: 2.0,
                                    color: Color(0x1A000000),
                                    offset: Offset(0.0, 2.0),
                                  ),
                                ],
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8.0),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.75),
                                    ],
                                    stops: const [0.1, 1.0],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                                alignment: Alignment.bottomLeft,
                                child: Text(
                                  valueOrDefault<String>(cat.nombre, 'Categoría'),
                                  style: theme.bodySmall.override(
                                    fontFamily: 'Inter',
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.0,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
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
