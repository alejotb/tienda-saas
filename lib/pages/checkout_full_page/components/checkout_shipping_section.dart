import 'package:baul_pandora/backend/schema/structs/address_struct.dart';
import 'package:flutter/material.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/services/venezuela_location_service.dart';
import 'package:baul_pandora/services/agency_service.dart';
import '../checkout_full_page_model.dart';

class CheckoutShippingSection extends StatefulWidget {
  const CheckoutShippingSection({
    super.key,
    required this.model,
    required this.onUpdate,
  });

  final CheckoutFullPageModel model;
  final VoidCallback onUpdate;

  @override
  State<CheckoutShippingSection> createState() => _CheckoutShippingSectionState();
}

class _CheckoutShippingSectionState extends State<CheckoutShippingSection> {
  final TextEditingController _stateTextController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  List<String> _stateSuggestions = [];
  bool _showStateSuggestions = false;
  List<Agency> _agencySuggestions = [];
  bool _showAgencySuggestions = false;
  String _searchMode = 'Nombre/Dirección';

  @override
  void initState() {
    super.initState();
    _phoneFocusNode.addListener(() {
      if (!_phoneFocusNode.hasFocus) {
        setState(() {});
      }
    });
    AgencyService().loadAgencies();
    VenezuelaLocationService().init().then((_) {
      _stateTextController.addListener(() {
        final query = _stateTextController.text;
        setState(() {
          _stateSuggestions = VenezuelaLocationService().getStates(query);
          _showStateSuggestions = query.isNotEmpty && _stateSuggestions.isNotEmpty;
        });
      });
    });

    // Listener para búsqueda de agencias
    widget.model.agencySearchController.addListener(() {
      if (!mounted) return;
      final query = widget.model.agencySearchController.text;
      final state = _stateTextController.text;
      
      if (state.isEmpty) {
        setState(() {
          _agencySuggestions = [];
          _showAgencySuggestions = false;
        });
        return;
      }

      setState(() {
        _agencySuggestions = AgencyService().searchAgencies(
          state, 
          query, 
          searchMode: _searchMode, 
          courier: widget.model.selectedCourier,
        );
        _showAgencySuggestions = query.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _stateTextController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0.0, 16.0, 0.0, 12.0),
          child: Text(
            'Método de Envío',
            style: FlutterFlowTheme.of(context).titleMedium,
          ),
        ),
            // 1. SELECTOR DE TIPO DE ENTREGA
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                _buildDeliveryTypeOption(
                  label: 'A domicilio',
                  icon: Icons.home_rounded,
                  value: 'Casa',
                ),
                const SizedBox(width: 12),
                _buildDeliveryTypeOption(
                  label: 'Retiro en agencia',
                  icon: Icons.business_rounded,
                  value: 'Oficina',
                ),
                const SizedBox(width: 12),
                _buildDeliveryTypeOption(
                  label: 'Encuentro en Persona',
                  icon: Icons.person_rounded,
                  value: 'Persona',
                ),
                ],
                ),
                const SizedBox(height: 20),
                // 2. SELECTOR DE EMPRESA DE ENVÍO O DATOS DE PERSONA
                if (widget.model.deliveryType != null) ...[
                if (widget.model.deliveryType == 'Persona') ...[
                Row(
                  children: [
                    Checkbox(
                      value: widget.model.useProfileData,
                      onChanged: (val) {
                        setState(() {
                          widget.model.useProfileData = val ?? false;
                          if (widget.model.useProfileData && widget.model.usuarioRow != null && widget.model.usuarioRow!.isNotEmpty) {
                             final user = widget.model.usuarioRow!.first;
                             // Asumimos nombres de campos 'nombre' y 'telefono'
                             widget.model.personNameController.text = user.nombre ?? '';
                             widget.model.personPhoneController.text = user.telefono ?? '';
                             widget.onUpdate();
                          }
                        });
                      },
                    ),
                    Text(
                      'Completar con los datos del perfil',
                      style: FlutterFlowTheme.of(context).labelMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Datos de contacto para entrega',
                  style: FlutterFlowTheme.of(context).labelMedium,
                ),
                const SizedBox(height: 12),
                Column(
                  children: [
                    TextFormField(
                      controller: widget.model.personNameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre Completo',
                        labelStyle: FlutterFlowTheme.of(context).labelLarge,
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: (widget.model.highlightErrors && 
                                      widget.model.personNameController.text.trim().isEmpty) 
                                  ? Colors.red 
                                  : FlutterFlowTheme.of(context).alternate,
                              width: 2.0),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: (widget.model.highlightErrors && 
                                      widget.model.personNameController.text.trim().isEmpty) 
                                  ? Colors.red 
                                  : FlutterFlowTheme.of(context).primary,
                              width: 2.0),
                        ),
                      ),
                      style: FlutterFlowTheme.of(context).bodyLarge,
                      onChanged: (val) {
                        widget.onUpdate();
                        if (widget.model.highlightErrors) {
                          setState(() {});
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: widget.model.personPhoneController,
                      focusNode: _phoneFocusNode,
                      decoration: InputDecoration(
                        labelText: 'Número de Teléfono',
                        labelStyle: FlutterFlowTheme.of(context).labelLarge,
                        errorText: (widget.model.highlightErrors &&
                                (widget.model.personPhoneController.text.trim().isEmpty || 
                                 !RegExp(r'^\+?[\d\s\-()]{5,15}$').hasMatch(widget.model.personPhoneController.text.trim())))
                            ? 'Formato incorrecto'
                            : null,
                        errorStyle: const TextStyle(color: Colors.red),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: (widget.model.highlightErrors && 
                                      (widget.model.personPhoneController.text.trim().isEmpty || 
                                       !RegExp(r'^\+?[\d\s\-()]{5,15}$').hasMatch(widget.model.personPhoneController.text.trim()))) 
                                  ? Colors.red 
                                  : FlutterFlowTheme.of(context).alternate,
                              width: 2.0),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: (widget.model.highlightErrors && 
                                      (widget.model.personPhoneController.text.trim().isEmpty || 
                                       !RegExp(r'^\+?[\d\s\-()]{5,15}$').hasMatch(widget.model.personPhoneController.text.trim()))) 
                                  ? Colors.red 
                                  : FlutterFlowTheme.of(context).primary,
                              width: 2.0),
                        ),
                      ),
                      style: FlutterFlowTheme.of(context).bodyLarge,
                      keyboardType: TextInputType.phone,
                      onChanged: (val) {
                        widget.onUpdate();
                        if (widget.model.highlightErrors) {
                          setState(() {});
                        }
                      },
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  'Seleccione la empresa de envío',
                  style: FlutterFlowTheme.of(context).labelMedium,
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCourierOption('Zoom', 'assets/images/zoom.png'),
                      const SizedBox(width: 12),
                      _buildCourierOption('MRW', 'assets/images/logoMrw.webp'),
                      const SizedBox(width: 12),
                      _buildCourierOption('Tealca', 'assets/images/Tealca.png'),
                      const SizedBox(width: 12),
                      _buildCourierOption('Domesa', 'assets/images/domesa.jpeg'),
                    ],
                  ),
                ),
                if (widget.model.highlightErrors && widget.model.selectedCourier == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Por favor, selecciona una empresa de envío',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                if (widget.model.deliveryType == 'Casa') ...[
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'Consulta si el servicio está disponible en la empresa de tu elección',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'No disponible para los envíos gratis',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
                if (widget.model.deliveryType == 'Oficina' && widget.model.selectedCourier != null && widget.model.selectedCourier != 'MRW')
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'Envío gratis solo disponible por MRW',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
            ],
        // 3. DETALLES DE AGENCIA (Solo para Oficina)
        Builder(builder: (context) {
          debugPrint('DEBUG: deliveryType: ${widget.model.deliveryType}, selectedCourier: ${widget.model.selectedCourier}, mostrarFormulario: ${widget.model.mostrarFormularioDireccion}');
          if (widget.model.deliveryType == 'Oficina' && widget.model.selectedCourier != null) {

            final direccionesEmpresa = widget.model.direccionesGuardadas
                .where((d) => d.addressName?.toLowerCase().contains(widget.model.selectedCourier!.toLowerCase()) == true)
                .toList();

            // Si hay direcciones y no estamos forzando el formulario, mostrar lista
            if (direccionesEmpresa.isNotEmpty && !widget.model.mostrarFormularioDireccion) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Direcciones guardadas para ${widget.model.selectedCourier}', style: FlutterFlowTheme.of(context).labelMedium),
                  const SizedBox(height: 12),
                  ...direccionesEmpresa.map((addr) {
                    final isSelected = widget.model.address == addr;
                    return GestureDetector(
                      onTap: () async {
                        setState(() {
                          widget.model.address = addr;
                          widget.model.selectedAgency = addr.addressName;
                          widget.model.featuredAgencyCode = addr.agencia;
                        });
                        widget.onUpdate();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? FlutterFlowTheme.of(context).primary.withOpacity(0.1)
                              : FlutterFlowTheme.of(context).secondaryBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? FlutterFlowTheme.of(context).primary
                                : FlutterFlowTheme.of(context).alternate,
                            width: isSelected ? 2.0 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                addr.addressName ?? '',
                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                  fontFamily: 'Inter',
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, size: 18, color: FlutterFlowTheme.of(context).secondaryText),
                              onPressed: () async {
                                await widget.model.deleteAddress(addr);
                                setState(() {
                                  widget.model.mostrarFormularioDireccion = true;
                                });
                                widget.onUpdate();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Agencia eliminada. Podés seleccionar o buscar una nueva.'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  ElevatedButton(
                    onPressed: () => setState(() => widget.model.mostrarFormularioDireccion = true), 
                    child: const Text('Agregar otra dirección'),
                  ),
                ],
              );
            }

            // Si no hay direcciones o se forzó el formulario, mostrar búsqueda
            return _buildAgencySearchForm();
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildAgencySearchForm() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).primaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FlutterFlowTheme.of(context).alternate),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                Text(
                  'Seleccionar Agencia',
                  style: FlutterFlowTheme.of(context).bodyLarge,
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _stateTextController,
                      decoration: InputDecoration(
                        labelText: 'Estado',
                        labelStyle: FlutterFlowTheme.of(context).labelLarge,
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: FlutterFlowTheme.of(context).alternate,
                              width: 2.0),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: FlutterFlowTheme.of(context).primary,
                              width: 2.0),
                        ),
                      ),
                      style: FlutterFlowTheme.of(context).bodyLarge,
                    ),
                    if (_showStateSuggestions)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).secondaryBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: FlutterFlowTheme.of(context).alternate),
                          boxShadow: const [
                            BoxShadow(
                                blurRadius: 4,
                                color: Colors.black12,
                                offset: Offset(0, 2))
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: ListView(
                            shrinkWrap: true,
                            children: _stateSuggestions
                                .map((state) => ListTile(
                                      title: Text(state,
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium),
                                      onTap: () {
                                        _stateTextController.text = state;
                                        setState(() {
                                          _showStateSuggestions = false;
                                        });
                                        widget.onUpdate();
                                      },
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Buscar por...',
                  style: FlutterFlowTheme.of(context).bodyMedium,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => setState(() {
                        _searchMode = 'Nombre/Dirección';
                      }),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Nombre/Dirección',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'Inter',
                              color: _searchMode == 'Nombre/Dirección' 
                                  ? FlutterFlowTheme.of(context).primary 
                                  : FlutterFlowTheme.of(context).secondaryText,
                            ),
                      ),
                    ),
                    Text(
                      ' o ',
                      style: FlutterFlowTheme.of(context).bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _searchMode = 'Código de Agencia';
                      }),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Código de Agencia',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'Inter',
                              color: _searchMode == 'Código de Agencia' 
                                  ? FlutterFlowTheme.of(context).primary 
                                  : FlutterFlowTheme.of(context).secondaryText,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: widget.model.agencySearchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar Agencia',
                    hintStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Inter',
                      fontSize: 12.0,
                    ),
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                  maxLines: null,
                  onChanged: (val) {
                    widget.onUpdate();
                  },
                ),
                 if (_showAgencySuggestions)
                   Container(
                     constraints: const BoxConstraints(maxHeight: 250),
                     margin: const EdgeInsets.only(top: 4),
                     decoration: BoxDecoration(
                       color: FlutterFlowTheme.of(context).secondaryBackground,
                       borderRadius: BorderRadius.circular(12),
                       border: Border.all(
                           color: FlutterFlowTheme.of(context).alternate),
                       boxShadow: const [
                         BoxShadow(
                             blurRadius: 4,
                             color: Colors.black12,
                             offset: Offset(0, 2))
                       ],
                     ),
                     child: _agencySuggestions.isEmpty
                         ? Padding(
                             padding: const EdgeInsets.all(16.0),
                             child: Text(
                               _searchMode == 'Código de Agencia'
                                   ? 'No encontramos una agencia con ese código'
                                   : 'No encontramos una agencia en esa locación',
                                style: FlutterFlowTheme.of(context).bodyMedium,
                                textAlign: TextAlign.center,
                             ),
                           )
                         : Material(
                              color: Colors.transparent,
                              child: ListView(
                                shrinkWrap: true,
                                children: _agencySuggestions
                                    .map((Agency agency) => ListTile(
                                          title: Text(
                                            '${agency.codigo} - ${agency.nombre}, ${agency.direccion}',
                                            style: FlutterFlowTheme.of(context).bodyMedium,
                                          ),
                                          onTap: () async { // Cambiado a async
                                            String displayValue = agency.nombre.isNotEmpty 
                                                ? '${agency.codigo} - ${agency.nombre}' 
                                                : '${agency.codigo} - ${agency.direccion}';

                                            if (displayValue == '${agency.codigo} - ') {
                                              displayValue = agency.codigo;
                                            }
                                            widget.model.agencySearchController.clear();
                                            widget.model.selectedAgency = displayValue;
                                            widget.model.featuredAgencyCode = agency.codigo;
                                            widget.model.addAgencyToGuardadas(agency);

                                            // Crear y guardar la dirección
                                            final newAddress = AddressStruct();
                                            newAddress.addressName = '${widget.model.selectedCourier} - ${agency.nombre}';
                                            newAddress.address = agency.direccion;
                                            newAddress.city = _stateTextController.text;
                                            newAddress.tipoDireccion = 'agencia';
                                            newAddress.agencia = agency.codigo;

                                            widget.model.address = newAddress;

                                            bool isDuplicateAgency = widget.model.direccionesGuardadas.any((a) => 
                                              a.tipoDireccion == 'agencia' && (
                                                (a.agencia.isNotEmpty && a.agencia == newAddress.agencia) ||
                                                (a.addressName.trim().toLowerCase() == newAddress.addressName.trim().toLowerCase())
                                              )
                                            );

                                            if (isDuplicateAgency) {
                                               ScaffoldMessenger.of(context).showSnackBar(
                                                 SnackBar(
                                                   content: Text(
                                                     'Esta agencia ya está en tu lista.',
                                                     style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                           fontFamily: 'Inter',
                                                           color: FlutterFlowTheme.of(context).primaryBackground,
                                                         ),
                                                   ),
                                                   backgroundColor: FlutterFlowTheme.of(context).error,
                                                 ),
                                               );
                                            } else {
                                              widget.model.addToDireccionesGuardadas(newAddress);
                                              // Persistir
                                              await widget.model.saveUserPreferences();
                                            }

                                            setState(() {
                                              _showAgencySuggestions = false;
                                              widget.model.mostrarFormularioDireccion = false;
                                            });
                                            widget.onUpdate();
                                          },
                                        ))
                                    .toList(),
                              ),
                            ),
                   ),
                ],
              ),
            ),
          );
  }

  Widget _buildDeliveryTypeOption({required String label, required IconData icon, required String value}) {
    bool isSelected = widget.model.deliveryType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          print('DEBUG CheckoutShippingSection: Cambio de tipo a: $value');
          print('DEBUG CheckoutShippingSection: totalPagado=${widget.model.totalPagado}');
          setState(() {
            widget.model.deliveryType = value;
          });
          widget.onUpdate();
        },
        child: Container(
          height: 80, // Tamaño fijo para todos
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? FlutterFlowTheme.of(context).primary : FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? Colors.transparent : FlutterFlowTheme.of(context).alternate),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Centrado vertical
            children: [
              Icon(icon, color: isSelected ? Colors.white : FlutterFlowTheme.of(context).secondaryText),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center, // Centrado horizontal
                style: FlutterFlowTheme.of(context).bodySmall.override(
                      fontFamily: 'Inter',
                      color: isSelected ? Colors.white : FlutterFlowTheme.of(context).secondaryText,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourierOption(String name, String imagePath) {
    bool isSelected = widget.model.selectedCourier == name;
    return GestureDetector(
      onTap: () {
        setState(() {
          widget.model.selectedCourier = name;
        });
        widget.onUpdate();
      },
      child: Container(
        width: 80,
        height: 60,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? FlutterFlowTheme.of(context).primary : FlutterFlowTheme.of(context).alternate,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            imagePath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported),
          ),
        ),
      ),
    );
  }
}
