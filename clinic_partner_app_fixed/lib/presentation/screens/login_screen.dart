import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';

/// Login screen with Google and Microsoft sign-in options
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ),);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ),);

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
              Color(0xFF2196F3),
              Color(0xFF1565C0),
              Color(0xFF0D47A1),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      _buildLogo(),
                      const SizedBox(height: 32),
                      _buildTitle(),
                      const SizedBox(height: 8),
                      _buildSubtitle(),
                      const SizedBox(height: 60),
                      _buildAuthButtons(),
                      const SizedBox(height: 40),
                      _buildFooter(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.local_hospital_rounded,
          size: 64,
          color: Color(0xFF2196F3),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'Clinic Partner',
      style: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'Doctor Appointment Management',
      style: TextStyle(
        fontSize: 16,
        color: Colors.white.withOpacity(0.9),
        fontWeight: FontWeight.w300,
        letterSpacing: 0.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildAuthButtons() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Column(
          children: [
            // Error message
            if (authProvider.errorMessage != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        authProvider.errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => authProvider.clearError(),
                      child: Icon(
                        Icons.close,
                        color: Colors.red.shade400,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

            // Google Sign-In Button
            _SignInButton(
              onPressed: authProvider.isLoading
                  ? null
                  : () => _handleGoogleSignIn(context),
              icon: _buildGoogleIcon(),
              label: 'Continue with Google',
              isLoading: authProvider.isLoading,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1F1F1F),
            ),

            const SizedBox(height: 16),

            // Microsoft Sign-In Button (Disabled)
            _SignInButton(
              onPressed: null, // Disabled
              icon: _buildMicrosoftIcon(),
              label: 'Continue with Microsoft',
              isLoading: false,
              backgroundColor: Colors.white.withOpacity(0.3),
              foregroundColor: Colors.white.withOpacity(0.5),
              isDisabled: true,
            ),

            const SizedBox(height: 12),

            // Coming soon text for Microsoft
            Text(
              'Microsoft sign-in coming soon',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGoogleIcon() {
    return SizedBox(
      width: 24,
      height: 24,
      child: Image.network(
        'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
        width: 24,
        height: 24,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Center(
              child: Text(
                'G',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMicrosoftIcon() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
      ),
      child: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Container(color: const Color(0xFFF25022).withOpacity(0.5)),
          Container(color: const Color(0xFF7FBA00).withOpacity(0.5)),
          Container(color: const Color(0xFF00A4EF).withOpacity(0.5)),
          Container(color: const Color(0xFFFFB900).withOpacity(0.5)),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Container(
          width: 60,
          height: 1,
          color: Colors.white.withOpacity(0.3),
        ),
        const SizedBox(height: 20),
        Text(
          'Secure authentication powered by OAuth 2.0',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 14,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(width: 4),
            Text(
              'For healthcare professionals only',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.signInWithGoogle();

    if (success && mounted) {
      // Navigate to home screen
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } else if (!success && mounted) {
      // Show error snackbar as backup
      if (authProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(authProvider.errorMessage!)),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }
}

/// Reusable sign-in button widget
class _SignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final String label;
  final bool isLoading;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool isDisabled;

  const _SignInButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.isLoading,
    required this.backgroundColor,
    required this.foregroundColor,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: isDisabled ? 0 : 4,
          shadowColor: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 16),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: foregroundColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
