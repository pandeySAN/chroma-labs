import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  int _step = 0; // 0=email, 1=otp, 2=new password

  final _identifierCtrl = TextEditingController();
  final _otpCtrls = List.generate(6, (_) => TextEditingController());
  final _otpFocus = List.generate(6, (_) => FocusNode());
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;
  String? _error;
  String _maskedEmail = '';
  String _otp = '';
  int _resendSec = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _identifierCtrl.dispose();
    for (final c in _otpCtrls) {
      c.dispose();
    }
    for (final f in _otpFocus) {
      f.dispose();
    }
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _resendSec = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _resendSec--;
        if (_resendSec <= 0) t.cancel();
      });
    });
  }

  Future<void> _sendOtp() async {
    final id = _identifierCtrl.text.trim();
    if (id.isEmpty) {
      setState(() => _error = 'Please enter your email or mobile');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final repo = ref.read(authRepositoryProvider);
    final result = await repo.forgotPassword(id);

    if (!mounted) return;
    setState(() => _loading = false);

    result.fold(
      (f) => setState(() => _error = f.message),
      (email) {
        _maskedEmail = email;
        _startTimer();
        setState(() => _step = 1);
        Future.delayed(const Duration(milliseconds: 200),
            () => _otpFocus[0].requestFocus());
      },
    );
  }

  Future<void> _verifyOtp() async {
    _otp = _otpCtrls.map((c) => c.text).join();
    if (_otp.length != 6) {
      setState(() => _error = 'Enter the complete 6-digit code');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final repo = ref.read(authRepositoryProvider);
    final result = await repo.verifyOtp(
      identifier: _identifierCtrl.text.trim(),
      otp: _otp,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    result.fold(
      (f) => setState(() => _error = f.message),
      (_) => setState(() => _step = 2),
    );
  }

  Future<void> _resetPassword() async {
    if (_passwordCtrl.text.length < 6) {
      setState(() => _error = 'Min 6 characters');
      return;
    }
    if (_passwordCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final repo = ref.read(authRepositoryProvider);
    final result = await repo.resetPassword(
      identifier: _identifierCtrl.text.trim(),
      otp: _otp,
      newPassword: _passwordCtrl.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    result.fold(
      (f) => setState(() => _error = f.message),
      (_) => _showSuccess(),
    );
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Password Reset!',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text(
              'You can now login with your new password.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back to Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            if (_step > 0) {
              setState(() {
                _step--;
                _error = null;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            children: [
              _buildStepIndicator(),
              const SizedBox(height: 28),
              _buildIcon(),
              const SizedBox(height: 24),
              if (_step == 0) _buildEmailStep(),
              if (_step == 1) _buildOtpStep(),
              if (_step == 2) _buildPasswordStep(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final active = i == _step;
        final done = i < _step;
        return Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: active ? 28 : 10,
              height: 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: active
                    ? AppColors.primary
                    : done
                        ? AppColors.success
                        : AppColors.divider,
              ),
            ),
            if (i < 2)
              Container(
                width: 32,
                height: 2,
                color: i < _step ? AppColors.success : AppColors.divider,
              ),
          ],
        );
      }),
    );
  }

  Widget _buildIcon() {
    final icons = [
      Icons.email_rounded,
      Icons.pin_rounded,
      Icons.lock_reset_rounded,
    ];
    final labels = ['Enter Email', 'Verify OTP', 'New Password'];
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.1),
          ),
          child: Icon(icons[_step], color: AppColors.primary, size: 32),
        ),
        const SizedBox(height: 12),
        Text(labels[_step],
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildEmailStep() {
    return _card([
      const Text(
        'Enter your registered email or mobile and we\'ll send a verification code.',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
      const SizedBox(height: 20),
      TextFormField(
        controller: _identifierCtrl,
        keyboardType: TextInputType.emailAddress,
        onFieldSubmitted: (_) => _sendOtp(),
        decoration: _input('Email or Mobile', Icons.person_outline_rounded),
      ),
      if (_error != null) ...[const SizedBox(height: 12), _errorBanner()],
      const SizedBox(height: 20),
      _button('Send OTP', _sendOtp),
    ]);
  }

  Widget _buildOtpStep() {
    return _card([
      Text('Code sent to $_maskedEmail',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
      const SizedBox(height: 24),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(6, (i) {
          return SizedBox(
            width: 42,
            height: 52,
            child: TextFormField(
              controller: _otpCtrls[i],
              focusNode: _otpFocus[i],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: AppColors.background,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              onChanged: (v) {
                if (v.isNotEmpty && i < 5) _otpFocus[i + 1].requestFocus();
                if (v.isEmpty && i > 0) _otpFocus[i - 1].requestFocus();
                if (_otpCtrls.every((c) => c.text.isNotEmpty)) _verifyOtp();
              },
            ),
          );
        }),
      ),
      if (_error != null) ...[const SizedBox(height: 14), _errorBanner()],
      const SizedBox(height: 20),
      _button('Verify', _verifyOtp),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: _resendSec > 0 ? null : _sendOtp,
        child: Text(
          _resendSec > 0
              ? 'Resend in ${_resendSec}s'
              : 'Resend OTP',
          style: TextStyle(
            color: _resendSec > 0 ? AppColors.textHint : AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    ]);
  }

  Widget _buildPasswordStep() {
    return _card([
      const Text('Create a strong password (min 6 characters).',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
      const SizedBox(height: 20),
      TextFormField(
        controller: _passwordCtrl,
        obscureText: _obscure,
        decoration: _input(
          'New Password',
          Icons.lock_outline_rounded,
          suffix: IconButton(
            icon: Icon(
                _obscure ? Icons.visibility_off : Icons.visibility,
                size: 20),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: _confirmCtrl,
        obscureText: _obscureConfirm,
        onFieldSubmitted: (_) => _resetPassword(),
        decoration: _input(
          'Confirm Password',
          Icons.lock_outline_rounded,
          suffix: IconButton(
            icon: Icon(
                _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                size: 20),
            onPressed: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),
      ),
      if (_error != null) ...[const SizedBox(height: 14), _errorBanner()],
      const SizedBox(height: 20),
      _button('Reset Password', _resetPassword),
    ]);
  }

  // Helpers

  Widget _card(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _button(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white))
            : Text(label),
      ),
    );
  }

  Widget _errorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(_error!,
                  style:
                      const TextStyle(color: AppColors.error, fontSize: 13))),
        ],
      ),
    );
  }

  InputDecoration _input(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
