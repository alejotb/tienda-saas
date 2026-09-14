import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';

class CheckoutProgressBar extends StatelessWidget {
  const CheckoutProgressBar({
    super.key,
    required this.currentStep,
  });

  final int currentStep;

  static const List<String> _steps = [
    'Envío',
    'Pago',
    'Confirmar',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_steps.length, (index) {
              int stepIndex = index + 1;
              bool isCompleted = stepIndex < currentStep;
              bool isActive = stepIndex == currentStep;

              return Expanded(
                child: Row(
                  children: [
                    // Step Circle
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: isCompleted || isActive
                                  ? FlutterFlowTheme.of(context).primary
                                  : FlutterFlowTheme.of(context).secondaryText,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isCompleted || isActive
                                    ? FlutterFlowTheme.of(context).primary
                                    : FlutterFlowTheme.of(context).alternate,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: isCompleted
                                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                                  : Text(
                                      '$stepIndex',
                                      style: GoogleFonts.inter(
                                        color: isCompleted || isActive
                                            ? Colors.white
                                            : FlutterFlowTheme.of(context).secondaryText,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _steps[index],
                            style: GoogleFonts.inter(
                              color: isActive
                                  ? FlutterFlowTheme.of(context).primaryText
                                  : FlutterFlowTheme.of(context).secondaryText,
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Connector Line
                    if (index < _steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: stepIndex < currentStep
                              ? FlutterFlowTheme.of(context).primary
                              : FlutterFlowTheme.of(context).alternate,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
