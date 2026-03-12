import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();

  // Step 0 = enter email, Step 1 = enter OTP, Step 2 = new password
  int _currentStep = 0;

  final _identifierController = TextEditingController();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;
  String _maskedEmail = '';
  String _otp = '';

  int _resendSeconds = 0;
  Timer? _resendTimer;

  late AnimationController _stepAnimController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _stepAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _stepAnimController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _stepAnimController,
      curve: Curves.easeOut,
    ));
    _stepAnimController.forward();
  }

  @override
  void dispose() {
    _identifierController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _stepAnimController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _animateToNextStep(int step) {
    _stepAnimController.reset();
    setState(() {
      _currentStep = step;
      _errorMessage = null;
    });
    _stepAnimController.forward();
  }

  void _startResendTimer() {
    _resendSeconds = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendSeconds--;
        if (_resendSeconds <= 0) {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _handleSendOtp() async {
    final identifier = _identifierController.text.trim();
    if (identifier.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email or mobile number');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _authService.forgotPassword(identifier);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _maskedEmail = result['email'] ?? '';
      _startResendTimer();
      _animateToNextStep(1);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _otpFocusNodes[0].requestFocus();
      });
    } else {
      setState(() => _errorMessage = result['error']);
    }
  }

  Future<void> _handleVerifyOtp() async {
    _otp = _otpControllers.map((c) => c.text).join();
    if (_otp.length != 6) {
      setState(() => _errorMessage = 'Please enter the complete 6-digit OTP');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _authService.verifyOtp(
      identifier: _identifierController.text.trim(),
      otp: _otp,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _animateToNextStep(2);
    } else {
      setState(() => _errorMessage = result['error']);
    }
  }

  Future<void> _handleResetPassword() async {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter a new password');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _authService.resetPassword(
      identifier: _identifierController.text.trim(),
      otp: _otp,
      newPassword: password,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _showSuccessAndPop();
    } else {
      setState(() => _errorMessage = result['error']);
    }
  }

  void _showSuccessAndPop() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF00B8A9).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF00B8A9),
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Password Reset!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your password has been changed successfully.\nPlease log in with your new password.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B8A9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Back to Login',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleResendOtp() async {
    if (_resendSeconds > 0) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _authService.forgotPassword(
      _identifierController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _startResendTimer();
      for (final c in _otpControllers) {
        c.clear();
      }
      _otpFocusNodes[0].requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('New OTP sent successfully'),
            ],
          ),
          backgroundColor: const Color(0xFF00B8A9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } else {
      setState(() => _errorMessage = result['error']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF153A4D),
              Color(0xFF0F2A3D),
              Color(0xFF0A2533),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildStepIndicator(),
                          const SizedBox(height: 32),
                          _buildStepIcon(),
                          const SizedBox(height: 24),
                          _buildStepContent(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (_currentStep > 0) {
                _animateToNextStep(_currentStep - 1);
              } else {
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          ),
          const Expanded(
            child: Text(
              'Reset Password',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index == _currentStep;
        final isCompleted = index < _currentStep;
        return Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isActive ? 32 : 12,
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: isActive
                    ? const Color(0xFF00B8A9)
                    : isCompleted
                        ? const Color(0xFF6FCF4E)
                        : Colors.white.withOpacity(0.2),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                  : null,
            ),
            if (index < 2)
              Container(
                width: 40,
                height: 2,
                color: index < _currentStep
                    ? const Color(0xFF6FCF4E)
                    : Colors.white.withOpacity(0.15),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildStepIcon() {
    final icons = [
      Icons.email_rounded,
      Icons.pin_rounded,
      Icons.lock_reset_rounded,
    ];
    final labels = ['Enter Email', 'Verify OTP', 'New Password'];

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                const Color(0xFF00B8A9).withOpacity(0.2),
                const Color(0xFF6FCF4E).withOpacity(0.2),
              ],
            ),
            border: Border.all(
              color: const Color(0xFF00B8A9).withOpacity(0.4),
              width: 2,
            ),
          ),
          child: Icon(
            icons[_currentStep],
            color: const Color(0xFF00B8A9),
            size: 36,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          labels[_currentStep],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildEmailStep();
      case 1:
        return _buildOtpStep();
      case 2:
        return _buildPasswordStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // ========================================
  // Step 0: Enter Email
  // ========================================

  Widget _buildEmailStep() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter your registered email or mobile number and we\'ll send you a verification code.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _identifierController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleSendOtp(),
            decoration: InputDecoration(
              labelText: 'Email or Mobile Number',
              hintText: 'Enter your email or mobile',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            _buildErrorBanner(),
          ],
          const SizedBox(height: 24),
          _buildPrimaryButton('Send OTP', _handleSendOtp),
        ],
      ),
    );
  }

  // ========================================
  // Step 1: Enter OTP
  // ========================================

  Widget _buildOtpStep() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'We\'ve sent a 6-digit code to',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            _maskedEmail,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF00B8A9),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 44,
                height: 54,
                child: TextFormField(
                  controller: _otpControllers[index],
                  focusNode: _otpFocusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF00B8A9),
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty && index < 5) {
                      _otpFocusNodes[index + 1].requestFocus();
                    }
                    if (value.isEmpty && index > 0) {
                      _otpFocusNodes[index - 1].requestFocus();
                    }
                    // Auto-verify when all 6 digits are entered
                    final fullOtp = _otpControllers.map((c) => c.text).join();
                    if (fullOtp.length == 6) {
                      _handleVerifyOtp();
                    }
                  },
                ),
              );
            }),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            _buildErrorBanner(),
          ],
          const SizedBox(height: 24),
          _buildPrimaryButton('Verify OTP', _handleVerifyOtp),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Didn't receive the code? ",
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              GestureDetector(
                onTap: _resendSeconds > 0 ? null : _handleResendOtp,
                child: Text(
                  _resendSeconds > 0
                      ? 'Resend in ${_resendSeconds}s'
                      : 'Resend OTP',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _resendSeconds > 0
                        ? Colors.grey.shade400
                        : const Color(0xFF00B8A9),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================
  // Step 2: New Password
  // ========================================

  Widget _buildPasswordStep() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create a strong password with at least 6 characters.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'New Password',
              hintText: 'Enter new password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleResetPassword(),
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              hintText: 'Re-enter new password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            _buildErrorBanner(),
          ],
          const SizedBox(height: 24),
          _buildPrimaryButton('Reset Password', _handleResetPassword),
        ],
      ),
    );
  }

  // ========================================
  // Shared Widgets
  // ========================================

  Widget _buildPrimaryButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00B8A9),
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
