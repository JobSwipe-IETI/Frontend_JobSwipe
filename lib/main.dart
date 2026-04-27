import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/theme.dart';
import 'config/app_config.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/profile_api_service.dart';
import 'services/secure_token_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppConfig.isSupabaseChatConfigured) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );
    } catch (error) {
      debugPrint('Supabase init skipped: $error');
    }
  }

  runApp(const JobSwipeApp());
}

class JobSwipeApp extends StatelessWidget {
  const JobSwipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JobSwipe',
      theme: JobSwipeTheme.getTheme(),
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _showSplash = true;

  void _completeSplash() {
    setState(() {
      _showSplash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(onSplashComplete: _completeSplash);
    }
    return const AuthGate();
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();
  final ProfileApiService _profileApiService = ProfileApiService();
  final SecureTokenStorage _tokenStorage = SecureTokenStorage();

  bool _isLoading = false;
  bool _isAuthenticated = false;
  bool _requiresOnboarding = false;
  String? _jwt;
  int? _userId;
  String? _roleOverride;
  Map<String, dynamic>? _profileSeed;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final Stopwatch stopwatch = Stopwatch()..start();
    final String? token = await _tokenStorage.readToken();
    if (!mounted) {
      return;
    }

    if (token == null || token.isEmpty) {
      setState(() {
        _isAuthenticated = false;
        _requiresOnboarding = false;
        _jwt = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await _resolveProfileState(token);
    stopwatch.stop();
    debugPrint('⏱️ _restoreSession total: ${stopwatch.elapsedMilliseconds} ms');
  }

  Future<void> _resolveProfileState(String token) async {
    await _resolveProfileStateForUser(token, AuthService.extractUserIdFromJwt(token));
  }

  Future<void> _resolveProfileStateForUser(String token, int? userId) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    bool requiresOnboarding = true;
    Map<String, dynamic>? profileSeed;

    debugPrint('🔍 _resolveProfileStateForUser: userId=$userId');

    if (userId != null) {
      try {
        final bool hasProfile = await _profileApiService.hasProfile(
          jwt: token,
          userId: userId,
        );
        debugPrint('✅ hasProfile check: $hasProfile for userId=$userId');
        requiresOnboarding = !hasProfile;
        profileSeed = null;
      } catch (e) {
        debugPrint('❌ hasProfile error: $e');
        requiresOnboarding = true;
        profileSeed = null;
      }
    } else {
      debugPrint('❌ userId is null!');
    }

    setState(() {
      _isLoading = false;
      _isAuthenticated = true;
      _requiresOnboarding = requiresOnboarding;
      _jwt = token;
      _userId = userId;
      _profileSeed = profileSeed;
    });

    stopwatch.stop();
    debugPrint('⏱️ _resolveProfileStateForUser total: ${stopwatch.elapsedMilliseconds} ms');
  }

  Future<void> _signIn() async {
    final Stopwatch stopwatch = Stopwatch()..start();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _requiresOnboarding = false;
      _roleOverride = null;
      _profileSeed = null;
    });

    try {
      final authSession = await _authService.signInWithGoogleAndExchangeJwt();
      if (authSession == null) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLoading = false;
          _errorMessage = 'Inicio de sesión cancelado.';
        });
        return;
      }

      await _tokenStorage.saveToken(authSession.jwt);
      debugPrint('⏱️ Token persisted at ${stopwatch.elapsedMilliseconds} ms');

      debugPrint('✅ Login successful: userId=${authSession.userId}, role=${authSession.role}');
      if (kDebugMode) {
        debugPrint('🔐 JWT_ACCESS_TOKEN=${authSession.jwt}');
      }

      if (!mounted) {
        return;
      }

      if (authSession.hasProfile != null) {
        setState(() {
          _isLoading = false;
          _isAuthenticated = true;
          _requiresOnboarding = !authSession.hasProfile!;
          _jwt = authSession.jwt;
          _userId = authSession.userId;
          _roleOverride = authSession.role;
          _profileSeed = null;
        });
        debugPrint('⏱️ Fast login path resolved in ${stopwatch.elapsedMilliseconds} ms');
      } else {
        await _resolveProfileStateForUser(authSession.jwt, authSession.userId);
        if (!mounted) {
          return;
        }

        setState(() {
          _roleOverride = authSession.role;
        });
        debugPrint('⏱️ Fallback login path resolved in ${stopwatch.elapsedMilliseconds} ms');
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    } finally {
      stopwatch.stop();
      debugPrint('⏱️ _signIn total: ${stopwatch.elapsedMilliseconds} ms');
    }
  }

  Future<void> _logout() async {
    await _authService.signOutGoogle();
    await _tokenStorage.clearToken();

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _isAuthenticated = false;
      _requiresOnboarding = false;
      _jwt = null;
      _userId = null;
      _roleOverride = null;
      _profileSeed = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated) {
      if (_requiresOnboarding) {
        return OnboardingScreen(
          jwt: _jwt ?? '',
          userId: _userId,
          onLogout: _logout,
          onCompleted: (result) {
            final String? newJwt = result['newJwt']?.toString();
            setState(() {
              _requiresOnboarding = false;
              _roleOverride = result['role']?.toString();
              if (newJwt != null) _jwt = newJwt;
              _profileSeed = result;
            });
            if (newJwt != null) {
              _tokenStorage.saveToken(newJwt);
            }
          },
        );
      }

      return HomeScreen(
        onLogout: _logout,
        jwt: _jwt ?? '',
        userId: _userId,
        roleOverride: _roleOverride ?? AuthService.extractRoleFromJwt(_jwt ?? ''),
        profileSeed: _profileSeed,
      );
    }

    return LoginScreen(
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      onGoogleLogin: _signIn,
    );
  }
}
