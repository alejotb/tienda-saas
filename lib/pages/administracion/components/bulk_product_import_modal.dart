import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/services/bulk_import_service.dart';
import 'package:baul_pandora/services/store_service.dart';
import 'package:baul_pandora/services/store_theme_service.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';

class BulkProductImportModal extends StatefulWidget {
  final VoidCallback? onImportCompleted;

  const BulkProductImportModal({
    super.key,
    this.onImportCompleted,
  });

  @override
  State<BulkProductImportModal> createState() => _BulkProductImportModalState();
}

class _BulkProductImportModalState extends State<BulkProductImportModal> {
  int _currentStep = 1; // 1: Subir, 2: Mapeo, 3: Importar & Progreso
  bool _isLoadingFile = false;
  String? _errorMessage;

  ParsedFileData? _parsedData;
  Map<String, String?> _columnMapping = {};

  // Información de la tienda y cuota
  StoreData? _store;
  int _currentProductCount = 0;
  bool _isLoadingStore = true;

  // Estado de la importación
  bool _isImporting = false;
  double _importProgress = 0.0;
  String _importStatusText = '';
  BulkImportResult? _importResult;

  @override
  void initState() {
    super.initState();
    _loadStoreInfo();
  }

  Future<void> _loadStoreInfo() async {
    setState(() => _isLoadingStore = true);
    try {
      final store = await StoreService.instance.getMyStore();
      _store = store;

      if (store != null) {
        final countRes = await SupaFlow.client
            .from('productos')
            .select('id')
            .eq('tienda_id', store.id)
            .eq('es_variacion', false)
            .count(CountOption.exact);
        _currentProductCount = countRes.count;
      }
    } catch (e) {
      debugPrint('Error cargando información de la tienda para importación: $e');
    } finally {
      if (mounted) setState(() => _isLoadingStore = false);
    }
  }

  Future<void> _pickAndParseFile() async {
    setState(() {
      _isLoadingFile = true;
      _errorMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls', 'tsv', 'txt'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isLoadingFile = false);
        return;
      }

      final file = result.files.first;
      final bytes = file.bytes;

      if (bytes == null || bytes.isEmpty) {
        throw Exception('No se pudieron leer los datos del archivo seleccionado.');
      }

      final parsed = await BulkImportService.instance.parseFile(
        bytes: bytes,
        fileName: file.name,
      );

      if (parsed.headers.isEmpty || parsed.rows.isEmpty) {
        throw Exception('El archivo no contiene filas de datos para importar.');
      }

      final autoMapping = BulkImportService.instance.suggestColumnMapping(parsed.headers);

      setState(() {
        _parsedData = parsed;
        _columnMapping = autoMapping;
        _currentStep = 2; // Pasar automáticamente al mapeo
        _isLoadingFile = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoadingFile = false;
      });
    }
  }

  void _downloadSampleTemplate() {
    final csvContent = BulkImportService.instance.generateSampleCsv();
    Clipboard.setData(ClipboardData(text: csvContent));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Plantilla CSV de ejemplo copiada al portapapeles. ¡Pégala en Excel o Bloc de Notas!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _startImport() async {
    if (_parsedData == null || _store == null) return;

    setState(() {
      _isImporting = true;
      _importProgress = 0.0;
      _importStatusText = 'Iniciando importación masiva...';
      _currentStep = 3;
      _errorMessage = null;
    });

    try {
      final result = await BulkImportService.instance.executeBulkImport(
        storeId: _store!.id,
        storePlan: _store!.plan,
        fileData: _parsedData!,
        columnMapping: _columnMapping,
        onProgress: (processed, total, status) {
          if (mounted) {
            setState(() {
              _importProgress = total > 0 ? (processed / total) : 0.0;
              _importStatusText = status;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _importResult = result;
          _isImporting = false;
        });

        if (result.success) {
          widget.onImportCompleted?.call();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isImporting = false;
          _errorMessage = 'Error durante la importación: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final primaryColor = StoreThemeService.instance.primaryColor;
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 32,
        vertical: isMobile ? 16 : 32,
      ),
      child: Container(
        width: 850,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            _buildHeader(theme, primaryColor),

            // Stepper
            _buildStepIndicator(theme, primaryColor),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildCurrentStepContent(theme, primaryColor),
              ),
            ),

            // Footer
            _buildFooter(theme, primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(FlutterFlowTheme theme, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(bottom: BorderSide(color: theme.alternate)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.file_upload_outlined, color: primaryColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Importador Masivo de Productos',
                  style: theme.titleMedium.override(fontFamily: 'Inter', fontWeight: FontWeight.bold),
                ),
                Text(
                  'Sube tu catálogo en CSV o Excel con mapeo inteligente de columnas',
                  style: theme.bodySmall.override(color: theme.secondaryText, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
            color: theme.secondaryText,
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(FlutterFlowTheme theme, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        border: Border(bottom: BorderSide(color: theme.alternate.withValues(alpha: 0.5))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepItem(1, '1. Archivo', theme, primaryColor),
          _buildStepSeparator(theme, primaryColor, 1),
          _buildStepItem(2, '2. Mapeo', theme, primaryColor),
          _buildStepSeparator(theme, primaryColor, 2),
          _buildStepItem(3, '3. Importación', theme, primaryColor),
        ],
      ),
    );
  }

  Widget _buildStepItem(int step, String label, FlutterFlowTheme theme, Color primaryColor) {
    final isActive = _currentStep == step;
    final isDone = _currentStep > step;

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isDone
                ? Colors.green
                : isActive
                    ? primaryColor
                    : theme.alternate,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '$step',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : theme.secondaryText,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive || isDone ? FontWeight.bold : FontWeight.normal,
            color: isActive ? primaryColor : (isDone ? Colors.green : theme.secondaryText),
          ),
        ),
      ],
    );
  }

  Widget _buildStepSeparator(FlutterFlowTheme theme, Color primaryColor, int step) {
    final isDone = _currentStep > step;
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: isDone ? Colors.green : theme.alternate,
    );
  }

  Widget _buildCurrentStepContent(FlutterFlowTheme theme, Color primaryColor) {
    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    switch (_currentStep) {
      case 1:
        return _buildStep1Upload(theme, primaryColor);
      case 2:
        return _buildStep2Mapping(theme, primaryColor);
      case 3:
        return _buildStep3ProgressAndResult(theme, primaryColor);
      default:
        return const SizedBox.shrink();
    }
  }

  // --- STEP 1: SUBIDA DE ARCHIVO ---
  Widget _buildStep1Upload(FlutterFlowTheme theme, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Quota Info Banner
        if (!_isLoadingStore && _store != null) _buildPlanQuotaBanner(theme, primaryColor),
        const SizedBox(height: 16),

        // Dropzone / File Picker Container
        InkWell(
          onTap: _isLoadingFile ? null : _pickAndParseFile,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: theme.primaryBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                _isLoadingFile
                    ? CircularProgressIndicator(color: primaryColor)
                    : Icon(Icons.cloud_upload_outlined, size: 54, color: primaryColor),
                const SizedBox(height: 16),
                Text(
                  _isLoadingFile ? 'Analizando archivo...' : 'Haz clic para seleccionar tu archivo CSV o Excel',
                  style: theme.titleMedium.override(fontFamily: 'Inter', fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Formatos compatibles: .csv, .xlsx, .xls, .tsv\nTamaño recomendado: hasta 5,000 filas por archivo',
                  style: theme.bodySmall.override(color: theme.secondaryText),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _isLoadingFile ? null : _pickAndParseFile,
                  icon: const Icon(Icons.folder_open_rounded, size: 18),
                  label: const Text('Explorar Archivos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Descargar Plantilla
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.primaryBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.alternate),
          ),
          child: Row(
            children: [
              const Icon(Icons.help_outline_rounded, color: Colors.blue, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('¿No tienes un archivo listo?', style: theme.bodyMedium.override(fontWeight: FontWeight.bold)),
                    Text(
                      'Copia nuestra plantilla CSV con columnas estándar (Nombre, Precio, Stock, Código, etc.) para llenarla en Excel.',
                      style: theme.bodySmall.override(color: theme.secondaryText, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _downloadSampleTemplate,
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copiar Plantilla'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlanQuotaBanner(FlutterFlowTheme theme, Color primaryColor) {
    final isFree = _store!.plan.toLowerCase() != 'pro' && _store!.plan.toLowerCase() != 'premium';
    const maxFree = 100;
    final available = isFree ? (maxFree - _currentProductCount) : 999999;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isFree ? Colors.blue.withValues(alpha: 0.08) : Colors.purple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isFree ? Colors.blue.withValues(alpha: 0.2) : Colors.purple.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            isFree ? Icons.info_outline_rounded : Icons.star_rounded,
            color: isFree ? Colors.blue : Colors.purple,
            size: 26,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan Actual: ${_store!.plan.toUpperCase()}',
                  style: theme.bodyMedium.override(fontWeight: FontWeight.bold),
                ),
                Text(
                  isFree
                      ? 'Tienes $_currentProductCount de $maxFree productos usados ($available disponibles en el Plan Free).'
                      : '¡Tienes productos ilimitados habilitados con tu Plan Pro!',
                  style: theme.bodySmall.override(color: theme.secondaryText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- STEP 2: MAPEO DE COLUMNAS ---
  Widget _buildStep2Mapping(FlutterFlowTheme theme, Color primaryColor) {
    if (_parsedData == null) return const SizedBox.shrink();

    final previewRow = _parsedData!.rows.isNotEmpty ? _parsedData!.rows.first : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary of parsed file
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Archivo "${_parsedData!.fileName}" leído: ${_parsedData!.totalRows} productos detectados con ${_parsedData!.headers.length} columnas.',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.green),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _currentStep = 1),
                child: const Text('Cambiar Archivo'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Asigna las columnas de tu archivo a los campos de la tienda:',
          style: theme.bodyMedium.override(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Hemos asociado automáticamente los nombres parecidos. Puedes cambiarlos si es necesario.',
          style: theme.bodySmall.override(color: theme.secondaryText),
        ),
        const SizedBox(height: 16),

        // Mapping table
        Container(
          decoration: BoxDecoration(
            color: theme.primaryBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.alternate),
          ),
          child: Column(
            children: BulkImportService.standardColumns.map((col) {
              return _buildMappingRow(col, theme, primaryColor);
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),

        // Live Preview of Row 1
        Text('Vista previa del primer producto según tu mapeo:', style: theme.bodyMedium.override(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _buildMappedPreviewCard(previewRow, theme, primaryColor),
      ],
    );
  }

  Widget _buildMappingRow(ImportColumnDefinition col, FlutterFlowTheme theme, Color primaryColor) {
    final selectedHeader = _columnMapping[col.key];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.alternate.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          // Campo destino
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      col.label,
                      style: theme.bodyMedium.override(fontWeight: FontWeight.w600),
                    ),
                    if (col.isRequired) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Requerido', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                Text(
                  col.description,
                  style: theme.bodySmall.override(color: theme.secondaryText, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Selector de columna
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: theme.secondaryBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selectedHeader != null ? primaryColor.withValues(alpha: 0.5) : theme.alternate,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _parsedData!.headers.contains(selectedHeader) ? selectedHeader : null,
                  isExpanded: true,
                  hint: const Text('--- No importar / Dejar vacío ---', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('--- No importar / Dejar vacío ---', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ),
                    ..._parsedData!.headers.map((h) => DropdownMenuItem<String?>(
                          value: h,
                          child: Text(h, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        )),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _columnMapping[col.key] = val;
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMappedPreviewCard(List<dynamic> row, FlutterFlowTheme theme, Color primaryColor) {
    if (row.isEmpty) return const SizedBox.shrink();

    String getValue(String key) {
      final header = _columnMapping[key];
      if (header == null) return '(Sin asignar)';
      final idx = _parsedData!.headers.indexOf(header);
      if (idx >= 0 && idx < row.length) {
        final val = row[idx]?.toString().trim() ?? '';
        return val.isEmpty ? '(Vacío)' : val;
      }
      return '(Vacío)';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.alternate),
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 12,
        children: [
          _buildPreviewItem('Nombre', getValue('nombre'), theme),
          _buildPreviewItem('Precio', '\$${getValue('precio')}', theme),
          _buildPreviewItem('Stock', getValue('stock'), theme),
          _buildPreviewItem('Código / SKU', getValue('codigo_barras'), theme),
          _buildPreviewItem('Categoría', getValue('categoria'), theme),
        ],
      ),
    );
  }

  Widget _buildPreviewItem(String label, String value, FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.bodySmall.override(color: theme.secondaryText, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.bodyMedium.override(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // --- STEP 3: PROGRESO Y RESULTADO FINAL ---
  Widget _buildStep3ProgressAndResult(FlutterFlowTheme theme, Color primaryColor) {
    if (_isImporting) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          children: [
            CircularProgressIndicator(
              value: _importProgress > 0 ? _importProgress : null,
              color: primaryColor,
              strokeWidth: 5,
            ),
            const SizedBox(height: 24),
            Text(
              'Importando productos a tu tienda...',
              style: theme.titleMedium.override(fontFamily: 'Inter', fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _importStatusText,
              style: theme.bodySmall.override(color: theme.secondaryText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _importProgress > 0 ? _importProgress : null,
                backgroundColor: theme.alternate,
                color: primaryColor,
                minHeight: 8,
              ),
            ),
          ],
        ),
      );
    }

    if (_importResult != null) {
      final res = _importResult!;
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: res.success ? Colors.green.withValues(alpha: 0.1) : Colors.amber.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              res.success ? Icons.check_circle_rounded : Icons.warning_rounded,
              color: res.success ? Colors.green : Colors.amber.shade800,
              size: 56,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            res.success ? '¡Importación Finalizada!' : 'Importación con Observaciones',
            style: theme.headlineSmall.override(fontFamily: 'Inter', fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            res.message,
            style: theme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Resumen Stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.primaryBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.alternate),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Total en Archivo', '${res.totalRows}', Colors.blue, theme),
                _buildStatColumn('Importados', '${res.importedCount}', Colors.green, theme),
                _buildStatColumn('Omitidos', '${res.skippedCount}', Colors.grey, theme),
              ],
            ),
          ),

          if (res.errors.isNotEmpty) ...[
            const SizedBox(height: 16),
            ExpansionTile(
              title: Text('Ver errores (${res.errors.length})', style: const TextStyle(color: Colors.red, fontSize: 13)),
              children: res.errors.map((e) => ListTile(
                dense: true,
                leading: const Icon(Icons.error_outline, size: 16, color: Colors.red),
                title: Text(e, style: const TextStyle(fontSize: 12)),
              )).toList(),
            ),
          ],
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildStatColumn(String label, String value, Color color, FlutterFlowTheme theme) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: theme.bodySmall.override(color: theme.secondaryText, fontSize: 11)),
      ],
    );
  }

  // --- FOOTER ---
  Widget _buildFooter(FlutterFlowTheme theme, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(top: BorderSide(color: theme.alternate)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botón Izquierdo (Atrás / Cancelar)
          if (_currentStep == 2 && !_isImporting)
            OutlinedButton(
              onPressed: () => setState(() => _currentStep = 1),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('⬅ Cambiar Archivo'),
            )
          else
            TextButton(
              onPressed: _isImporting ? null : () => Navigator.of(context).pop(),
              child: Text(_importResult != null ? 'Cerrar' : 'Cancelar'),
            ),

          // Botón Derecho (Continuar / Importar / Finalizar)
          if (_currentStep == 1)
            ElevatedButton(
              onPressed: _parsedData != null ? () => setState(() => _currentStep = 2) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Continuar al Mapeo ➜'),
            )
          else if (_currentStep == 2)
            ElevatedButton.icon(
              onPressed: _columnMapping['nombre'] != null ? _startImport : null,
              icon: const Icon(Icons.flash_on_rounded, size: 18),
              label: Text('Importar ${_parsedData?.totalRows ?? 0} Productos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            )
          else if (_currentStep == 3 && _importResult != null)
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Listo - Ver Catálogo'),
            ),
        ],
      ),
    );
  }
}
