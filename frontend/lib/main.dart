import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize German date formatting
  await initializeDateFormatting('de_DE', null);

  // Initialize Supabase
  await SupabaseConfig.initialize();

  // Debug: Check initial session
  final session = SupabaseConfig.client.auth.currentSession;
  debugPrint('Initial session: ${session?.user?.email}');

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '1. FCPW Predictor',
      theme: AppTheme.darkTheme,
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('de', 'DE'),
      ],
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _authService = AuthService();
  bool _showRegister = false;
  bool _isPasswordRecovery = false;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    // Listen for auth state changes
    SupabaseConfig.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      debugPrint('Auth event: $event');

      if (event == AuthChangeEvent.passwordRecovery) {
        debugPrint('Password recovery detected!');
        if (mounted) {
          setState(() {
            _isPasswordRecovery = true;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show reset password screen if recovery token detected
    if (_isPasswordRecovery) {
      return const ResetPasswordScreen();
    }

    return StreamBuilder(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.hasData ? snapshot.data!.session : null;

        if (session != null) {
          return const HomeScreen();
        }

        if (_showRegister) {
          return RegisterScreen(
            onRegisterSuccess: () {
              setState(() {});
            },
            onNavigateToLogin: () {
              setState(() => _showRegister = false);
            },
          );
        }

        return LoginScreen(
          onLoginSuccess: () {
            setState(() {});
          },
          onNavigateToRegister: () {
            setState(() => _showRegister = true);
          },
        );
      },
    );
  }
}
