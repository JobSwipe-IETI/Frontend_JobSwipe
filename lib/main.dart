import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/secure_token_storage.dart';

void main() {
  runApp(const JobSwipeApp());
}

class JobSwipeApp extends StatelessWidget {
  const JobSwipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JobSwipe',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade700),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();
  final SecureTokenStorage _tokenStorage = SecureTokenStorage();

  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final String? token = await _tokenStorage.readToken();
    if (!mounted) {
      return;
    }

    setState(() {
      _isAuthenticated = token != null && token.isNotEmpty;
    });
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final String? jwt = await _authService.signInWithGoogleAndExchangeJwt();
      if (jwt == null) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLoading = false;
          _errorMessage = 'Inicio de sesión cancelado.';
        });
        return;
      }

      await _tokenStorage.saveToken(jwt);

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _isAuthenticated = true;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _logout() async {
    await _authService.signOutGoogle();
    await _tokenStorage.clearToken();

    if (!mounted) {
      return;
    }

    setState(() {
      _isAuthenticated = false;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated) {
      return HomeScreen(onLogout: _logout);
    }

    return LoginScreen(
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      onGoogleLogin: _signIn,
    );
  }
}
