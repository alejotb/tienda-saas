import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_widgets.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/auth/supabase_auth/supabase_user_provider.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';

class OtpVerificationDialog extends StatefulWidget {
  const OtpVerificationDialog({
    super.key,
    required this.email,
    this.title = 'Confirma tu correo',
    this.subtitle,
    this.onVerified,
  });

  final String email;
  final String? title;
  final String? subtitle;
  final Future<void> Function()? onVerified;

  static Future<bool> show(
    BuildContext context, {
    required String email,
    String? title,
    String? subtitle,
    Future<void> Function()? onVerified,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => OtpVerificationDialog(
        email: email,
        title: title,
        subtitle: subtitle,
        onVerified: onVerified,
      ),
    );
    return result ?? false;
  }

  @override
  State<OtpVerificationDialog> createState() => _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends State<OtpVerificationDialog> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  int _countdown = 45;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    // Auto focus on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _otpFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _countdown = 45);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _resendCode() async {
    if (_countdown > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      try {
        await SupaFlow.client.auth.resend(
          type: OtpType.signup,
          email: widget.email.trim(),
        );
      } catch (_) {
        await SupaFlow.client.auth.resend(
          type: OtpType.email,
          email: widget.email.trim(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nuevo código de confirmación enviado a ${widget.email}'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _startCountdown();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'No se pudo reenviar el código. Intenta nuevamente en unos segundos.';
      });
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length < 6) {
      setState(() => _errorMessage = 'Por favor ingresa los 6 dígitos del código.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      AuthResponse? res;
      try {
        res = await SupaFlow.client.auth.verifyOTP(
          email: widget.email.trim(),
          token: code,
          type: OtpType.signup,
        );
      } catch (e) {
        // Fallback to OtpType.email if signup fails
        try {
          res = await SupaFlow.client.auth.verifyOTP(
            email: widget.email.trim(),
            token: code,
            type: OtpType.email,
          );
        } catch (_) {
          rethrow;
        }
      }

      if (res.user != null) {
        final authUser = BaulPandoraSupabaseUser(res.user!);
        currentUser = authUser;
        await AppStateNotifier.instance.update(authUser);

        if (widget.onVerified != null) {
          await widget.onVerified!();
        }

        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        throw Exception('No se pudo validar el código.');
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message.contains('expired') || e.message.contains('invalid')
            ? 'El código ingresado es incorrecto o ha expirado.'
            : 'Error al verificar: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Código inválido o error de verificación. Intenta nuevamente.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: theme.secondaryBackground,
      elevation: 10,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Header
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.mark_email_read_rounded,
                    color: theme.primary,
                    size: 38,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                widget.title ?? 'Confirma tu correo',
                textAlign: TextAlign.center,
                style: theme.headlineSmall.override(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.0,
                ),
              ),
              const SizedBox(height: 10),

              // Subtitle
              Text(
                widget.subtitle ??
                    'Te enviamos un código de 6 dígitos a:\n${widget.email}',
                textAlign: TextAlign.center,
                style: theme.bodyMedium.override(
                  fontFamily: 'Inter',
                  color: theme.secondaryText,
                  lineHeight: 1.4,
                  letterSpacing: 0.0,
                ),
              ),
              const SizedBox(height: 24),

              // OTP Input Box
              Container(
                decoration: BoxDecoration(
                  color: theme.primaryBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _errorMessage != null
                        ? Colors.red.shade400
                        : theme.alternate,
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _otpController,
                  focusNode: _otpFocusNode,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  style: theme.titleLarge.override(
                    fontFamily: 'Inter',
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 14.0,
                    color: theme.primaryText,
                  ),
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    hintText: '------',
                    hintStyle: TextStyle(
                      letterSpacing: 14.0,
                      color: Colors.grey,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  onSubmitted: (_) => _verifyOtp(),
                ),
              ),

              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: theme.bodySmall.override(
                            fontFamily: 'Inter',
                            color: Colors.red.shade700,
                            letterSpacing: 0.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Confirm Button
              FFButtonWidget(
                onPressed: _isLoading ? null : _verifyOtp,
                text: _isLoading ? 'Verificando...' : 'Verificar y Continuar',
                icon: _isLoading
                    ? null
                    : const Icon(Icons.check_circle_outline, size: 20),
                options: FFButtonOptions(
                  width: double.infinity,
                  height: 48,
                  color: theme.primary,
                  textStyle: theme.titleSmall.override(
                    fontFamily: 'Inter',
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.0,
                  ),
                  elevation: 2,
                  borderRadius: BorderRadius.circular(14),
                  disabledColor: theme.primary.withOpacity(0.5),
                ),
              ),

              const SizedBox(height: 16),

              // Resend & Cancel Options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: Text(
                      'Cancelar',
                      style: theme.bodyMedium.override(
                        fontFamily: 'Inter',
                        color: theme.secondaryText,
                        letterSpacing: 0.0,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: (_countdown == 0 && !_isResending && !_isLoading)
                        ? _resendCode
                        : null,
                    child: Text(
                      _countdown > 0
                          ? 'Reenviar en ${_countdown}s'
                          : (_isResending ? 'Enviando...' : 'Reenviar código'),
                      style: theme.bodyMedium.override(
                        fontFamily: 'Inter',
                        color: _countdown > 0
                            ? theme.secondaryText
                            : theme.primary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
