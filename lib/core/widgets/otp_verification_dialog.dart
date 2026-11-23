import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'animated_button.dart';

/// An interactive, glassmorphic 6-digit OTP verification bottom sheet or dialog.
class OtpVerificationDialog extends StatefulWidget {
  final String phoneNumber;
  final Future<void> Function(String otp) onVerify;
  final Future<void> Function() onResend;
  final VoidCallback? onEditPhoneNumber;

  const OtpVerificationDialog({
    Key? key,
    required this.phoneNumber,
    required this.onVerify,
    required this.onResend,
    this.onEditPhoneNumber,
  }) : super(key: key);

  /// Helper static method to display the modal bottom sheet cleanly.
  static Future<void> show({
    required BuildContext context,
    required String phoneNumber,
    required Future<void> Function(String otp) onVerify,
    required Future<void> Function() onResend,
    VoidCallback? onEditPhoneNumber,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: OtpVerificationDialog(
          phoneNumber: phoneNumber,
          onVerify: onVerify,
          onResend: onResend,
          onEditPhoneNumber: onEditPhoneNumber,
        ),
      ),
    );
  }

  @override
  State<OtpVerificationDialog> createState() => _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends State<OtpVerificationDialog> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _resendCountdown = 60;
  Timer? _timer;
  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    // Auto focus the first field after modal settles
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() {
      _resendCountdown = 60;
      _errorMessage = null;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        if (mounted) {
          setState(() => _resendCountdown--);
        }
      } else {
        timer.cancel();
      }
    });
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    setState(() => _errorMessage = null);

    // Support pasting full 6 digits into any field
    if (value.length > 1) {
      String cleanDigits = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanDigits.length >= 6) {
        for (int i = 0; i < 6; i++) {
          _controllers[i].text = cleanDigits[i];
        }
        _focusNodes[5].requestFocus();
        _handleVerify();
        return;
      }
    }

    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        if (_otpCode.length == 6) {
          _handleVerify();
        }
      }
    }
  }

  void _handleVerify() async {
    final code = _otpCode;
    if (code.length < 6) {
      setState(() => _errorMessage = "Please enter the complete 6-digit OTP.");
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      await widget.onVerify(code);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _handleResend() async {
    if (_resendCountdown > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      await widget.onResend();
      if (mounted) {
        _startResendTimer();
        // Clear pin boxes
        for (var c in _controllers) {
          c.clear();
        }
        _focusNodes[0].requestFocus();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: const Border(
          top: BorderSide(color: AppTheme.glassBorder, width: 1.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Drag handle pill
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Top Shield Icon Badge
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.amber.withValues(alpha: 0.2),
                    AppTheme.amber.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: AppTheme.amber.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.amber.withValues(alpha: 0.2),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                color: AppTheme.amber,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),

            // Title & Subtitle
            Text(
              "Verify Phone Number",
              style: GoogleFonts.outfit(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Code sent to ",
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                Text(
                  widget.phoneNumber,
                  style: GoogleFonts.inter(
                    color: AppTheme.amber,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.onEditPhoneNumber != null) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onEditPhoneNumber!();
                    },
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 16,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            // 6 OTP Digit Fields
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) => _buildDigitField(index)),
            ),
            const SizedBox(height: 14),

            // Error Message (if any)
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppTheme.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.inter(
                          color: AppTheme.red,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Countdown & Resend Section
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Didn't receive the OTP? ",
                  style: GoogleFonts.inter(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                  ),
                ),
                if (_resendCountdown > 0)
                  Text(
                    "Resend in ${_resendCountdown}s",
                    style: GoogleFonts.inter(
                      color: AppTheme.amber,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  GestureDetector(
                    onTap: _isResending ? null : _handleResend,
                    child: _isResending
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation(AppTheme.amber),
                            ),
                          )
                        : Text(
                            "Resend OTP",
                            style: GoogleFonts.inter(
                              color: AppTheme.amber,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Verify Action Button
            GradientButton(
              label: "Verify & Continue",
              isLoading: _isVerifying,
              icon: Icons.check_circle_outline_rounded,
              onPressed: _handleVerify,
              gradient: AppTheme.amberGradient,
            ),
            const SizedBox(height: 10),

            // Cancel Button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Cancel",
                style: GoogleFonts.inter(
                  color: AppTheme.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDigitField(int index) {
    return SizedBox(
      width: 46,
      height: 54,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace) {
            if (_controllers[index].text.isEmpty && index > 0) {
              _focusNodes[index - 1].requestFocus();
              _controllers[index - 1].clear();
            }
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.glass,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focusNodes[index].hasFocus
                  ? AppTheme.amber
                  : (_controllers[index].text.isNotEmpty
                      ? AppTheme.amber.withValues(alpha: 0.6)
                      : AppTheme.glassBorder),
              width: _focusNodes[index].hasFocus ? 2.0 : 1.2,
            ),
            boxShadow: _focusNodes[index].hasFocus
                ? [
                    BoxShadow(
                      color: AppTheme.amber.withValues(alpha: 0.25),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: Center(
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              style: GoogleFonts.outfit(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(
                counterText: "",
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (val) => _onDigitChanged(index, val),
            ),
          ),
        ),
      ),
    );
  }
}
