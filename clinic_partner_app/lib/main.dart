import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/appointment_provider.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/signup_screen.dart';
import 'presentation/screens/doctor_home_screen.dart';
import 'presentation/screens/doctor_registration_screen.dart';
import 'presentation/screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style for splash
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A2533),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
      ],
      child: const ClinicPartnerApp(),
    ),
  );
}

class ClinicPartnerApp extends StatefulWidget {
  const ClinicPartnerApp({super.key});

  @override
  State<ClinicPartnerApp> createState() => _ClinicPartnerAppState();
}

class _ClinicPartnerAppState extends State<ClinicPartnerApp> {
  bool _showSplash = true;
  bool _splashAnimationComplete = false;

  @override
  void initState() {
    super.initState();
    // Initialize auth state on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().initialize();
    });
  }

  void _onSplashComplete() {
    setState(() {
      _splashAnimationComplete = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CEREBRO – Clinic Partner',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      // Custom page transitions
      onGenerateRoute: _generateRoute,
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // Show animated splash during initialization
          if (_showSplash && (!authProvider.isInitialized || !_splashAnimationComplete)) {
            return AnimatedSplashScreen(
              onAnimationComplete: _onSplashComplete,
              showLoadingIndicator: !authProvider.isInitialized,
            );
          }

          // Transition from splash to main content
          if (_showSplash && authProvider.isInitialized && _splashAnimationComplete) {
            // Small delay to ensure smooth transition
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                setState(() {
                  _showSplash = false;
                });
              }
            });
            
            // Return splash with loading hidden during transition
            return const AnimatedSplashScreen(showLoadingIndicator: false);
          }
          
          // Navigate based on auth state with animated transition
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.02),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _buildMainContent(authProvider),
          );
        },
      ),
    );
  }

  Widget _buildMainContent(AuthProvider authProvider) {
    if (authProvider.isAuthenticated) {
      if (authProvider.isDoctor) {
        return const DoctorHomeScreen(key: ValueKey('doctor_home'));
      } else {
        return const DoctorRegistrationScreen(key: ValueKey('doctor_registration'));
      }
    } else {
      return const LoginScreen(key: ValueKey('login'));
    }
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    Widget page;
    
    switch (settings.name) {
      case '/login':
        page = const LoginScreen();
        break;
      case '/signup':
        page = const SignupScreen();
        break;
      case '/home':
        page = const DoctorHomeScreen();
        break;
      case '/register-doctor':
        page = const DoctorRegistrationScreen();
        break;
      default:
        return null;
    }

    // Use custom fade-slide transition for all routes
    return FadeSlidePageRoute(page: page);
  }

  ThemeData _buildTheme() {
    // Cerebro brand colors - teal/cyan gradient matching the logo
    const primaryColor = Color(0xFF00B8A9); // Teal/Cyan from logo
    const secondaryColor = Color(0xFF6FCF4E); // Green from logo
    const darkNavy = Color(0xFF0F2A3D); // Dark navy background
    
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: Colors.white,
        background: const Color(0xFFF8FAFC),
      ),
      
      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: darkNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      
      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      
      // Card theme
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),
      
      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      
      // Dialog theme
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

