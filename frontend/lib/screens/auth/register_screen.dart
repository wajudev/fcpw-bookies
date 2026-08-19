import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onRegisterSuccess;
  final VoidCallback onNavigateToLogin;

  const RegisterScreen({
    super.key,
    required this.onRegisterSuccess,
    required this.onNavigateToLogin,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        username: _usernameController.text.trim(),
      );

      if (!mounted) return;

      // Check if email confirmation is required
      if (response.session == null) {
        // Email confirmation required
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Bestätigung erforderlich'),
            content: Text(
              'Wir haben eine Email an ${_emailController.text} gesendet.\n\n'
              'Bitte klicke auf den Link in der Email, um dein Konto zu aktivieren.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onNavigateToLogin();
                },
                child: const Text('Zur Anmeldung'),
              ),
            ],
          ),
        );
      } else {
        // Auto-logged in (email confirmation disabled)
        widget.onRegisterSuccess();
      }
    } catch (e) {
      // Log technical error for debugging
      debugPrint('Registration error: $e');

      // Show user-friendly message based on error type
      setState(() {
        final errorStr = e.toString().toLowerCase();

        // Network errors
        if (errorStr.contains('socketfailed') || errorStr.contains('host lookup') ||
            errorStr.contains('network') || errorStr.contains('connection refused')) {
          _errorMessage = 'Keine Verbindung zum Server. Bitte Internetverbindung prüfen.';
        }
        // Email already exists
        else if (errorStr.contains('user already registered') ||
                 errorStr.contains('email already in use') ||
                 errorStr.contains('duplicate') && errorStr.contains('email')) {
          _errorMessage = 'Diese E-Mail ist bereits registriert. Bitte einloggen oder andere E-Mail verwenden.';
        }
        // Username already taken
        else if (errorStr.contains('duplicate key') || errorStr.contains('unique constraint') ||
                 (errorStr.contains('username') && errorStr.contains('already'))) {
          _errorMessage = 'Benutzername bereits vergeben. Bitte anderen wählen.';
        }
        // Password validation errors
        else if (errorStr.contains('password should be') || errorStr.contains('password must be')) {
          if (errorStr.contains('6')) {
            _errorMessage = 'Passwort zu kurz. Mindestens 6 Zeichen erforderlich.';
          } else if (errorStr.contains('72')) {
            _errorMessage = 'Passwort zu lang. Maximal 72 Zeichen erlaubt.';
          } else {
            _errorMessage = 'Passwort erfüllt nicht die Anforderungen. Mindestens 6 Zeichen.';
          }
        }
        // Invalid email format
        else if (errorStr.contains('invalid') && errorStr.contains('email')) {
          _errorMessage = 'Ungültige E-Mail-Adresse. Bitte korrektes Format verwenden.';
        }
        // Username validation errors
        else if (errorStr.contains('username') && (errorStr.contains('invalid') ||
                 errorStr.contains('char_length') || errorStr.contains('regex'))) {
          _errorMessage = 'Benutzername ungültig. 3-20 Zeichen, nur Buchstaben, Zahlen und Unterstrich erlaubt.';
        }
        // Rate limiting
        else if (errorStr.contains('rate limit') || errorStr.contains('too many')) {
          _errorMessage = 'Zu viele Versuche. Bitte in einigen Minuten erneut versuchen.';
        }
        // Email confirmation timeout
        else if (errorStr.contains('confirmation') || errorStr.contains('verify')) {
          _errorMessage = 'E-Mail-Bestätigung erforderlich. Bitte überprüfe dein Postfach.';
        }
        // Generic fallback with hint to check logs
        else {
          _errorMessage = 'Registrierung fehlgeschlagen. Bitte Eingaben überprüfen und erneut versuchen.';
          debugPrint('⚠️ Unhandled registration error: $e');
        }
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onNavigateToLogin,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Registrieren',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEAB308), // gold
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Benutzername',
                      prefixIcon: Icon(Icons.person),
                      helperText: 'Wird anderen Spielern angezeigt',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bitte Benutzername eingeben';
                      }
                      if (value.length < 3) {
                        return 'Mindestens 3 Zeichen';
                      }
                      if (value.length > 20) {
                        return 'Maximal 20 Zeichen';
                      }
                      if (!RegExp(r'^[A-Za-z0-9_]+$').hasMatch(value)) {
                        return 'Nur Buchstaben, Zahlen und Unterstrich';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      helperText: 'Für Login und Passwort-Reset',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bitte Email eingeben';
                      }
                      if (!value.contains('@')) {
                        return 'Ungültige Email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Passwort',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bitte Passwort eingeben';
                      }
                      if (value.length < 6) {
                        return 'Mindestens 6 Zeichen';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Passwort bestätigen',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Passwörter stimmen nicht überein';
                      }
                      return null;
                    },
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade400),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Konto erstellen'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
