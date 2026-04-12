import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class AuthService {
  AuthService({GoogleSignIn? googleSignIn, http.Client? client})
    : _googleSignIn =
          googleSignIn ??
          GoogleSignIn(
            scopes: const <String>['email', 'profile'],
            clientId: !kIsWeb && defaultTargetPlatform == TargetPlatform.android
                ? AppConfig.googleAndroidClientId
                : AppConfig.googleWebClientId,
            serverClientId: AppConfig.googleWebClientId,
          ),
      _client = client ?? http.Client();

  final GoogleSignIn _googleSignIn;
  final http.Client _client;

  Future<AuthSession?> signInWithGoogleAndExchangeJwt() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      debugPrint('Google Sign-In result: $account');
      if (account == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await account.authentication;
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      if (idToken == null || idToken.isEmpty) {
        throw const AuthException('Google no devolvió idToken.');
      }

      final Uri uri = Uri.parse('${AppConfig.backendBaseUrl}/api/auth/google');
      final http.Response response = await _client
          .post(
            uri,
            headers: const <String, String>{'Content-Type': 'application/json'},
            body: jsonEncode(<String, String?>{
              'idToken': idToken,
              'accessToken': accessToken,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw AuthException(
          'Backend rechazó autenticación (${response.statusCode}): ${response.body}',
        );
      }

      final Map<String, dynamic> json =
          jsonDecode(response.body) as Map<String, dynamic>;
      final Object? token = json['accessToken'];
      final Object? user = json['user'];

      if (token is! String || token.isEmpty) {
        throw const AuthException('El backend no devolvió un JWT válido.');
      }

      final int? userId = user is Map<String, dynamic>
          ? (user['id'] as num?)?.toInt()
          : null;

      return AuthSession(
        jwt: token,
        userId: userId,
        role: user is Map<String, dynamic> ? user['role']?.toString() : null,
        name: user is Map<String, dynamic> ? user['name']?.toString() : null,
        email: user is Map<String, dynamic> ? user['email']?.toString() : null,
        avatarUrl: user is Map<String, dynamic> ? user['avatarUrl']?.toString() : null,
      );
    } on PlatformException catch (error) {
      debugPrint('Google Sign-In error: $error');
      throw AuthException(
        'Google Sign-In falló (${error.code}): ${error.message ?? 'sin detalle'}',
      );
    } on TimeoutException {
      throw const AuthException(
        'Timeout al conectar con el backend. Verifica URL y servidor.',
      );
    } on http.ClientException catch (error) {
      throw AuthException('Error de red: ${error.message}');
    }
  }

  /// Decodifica el JWT y extrae el rol del usuario
  /// Retorna "CANDIDATE" o "COMPANY"
  static String? extractRoleFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        debugPrint('JWT inválido: debe tener 3 partes');
        return null;
      }

      // Decodificar payload (segundo elemento)
      String payload = parts[1];
      
      // Agregar padding si es necesario
      final int padLength = 4 - (payload.length % 4);
      if (padLength != 4) {
        payload += '=' * padLength;
      }

      final decodedBytes = base64Url.decode(payload);
      final decodedString = utf8.decode(decodedBytes);
      final json = jsonDecode(decodedString) as Map<String, dynamic>;
      
      final role = json['role'] as String?;
      debugPrint('📋 JWT Role: $role');
      return role;
    } catch (e) {
      debugPrint('❌ Error decodificando JWT: $e');
      return null;
    }
  }

  static int? extractUserIdFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }

      String payload = parts[1];
      final int padLength = 4 - (payload.length % 4);
      if (padLength != 4) {
        payload += '=' * padLength;
      }

      final decodedBytes = base64Url.decode(payload);
      final decodedString = utf8.decode(decodedBytes);
      final json = jsonDecode(decodedString) as Map<String, dynamic>;

      final subject = json['sub']?.toString();
      if (subject == null) {
        return null;
      }

      return int.tryParse(subject);
    } catch (_) {
      return null;
    }
  }

  static String? extractNameFromJwt(String token) {
    return _extractStringClaim(token, 'name');
  }

  static String? extractEmailFromJwt(String token) {
    return _extractStringClaim(token, 'email');
  }

  static String? extractAvatarUrlFromJwt(String token) {
    return _extractStringClaim(token, 'avatarUrl');
  }

  static String? _extractStringClaim(String token, String claimKey) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }

      String payload = parts[1];
      final int padLength = 4 - (payload.length % 4);
      if (padLength != 4) {
        payload += '=' * padLength;
      }

      final decodedBytes = base64Url.decode(payload);
      final decodedString = utf8.decode(decodedBytes);
      final json = jsonDecode(decodedString) as Map<String, dynamic>;
      return json[claimKey]?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> signOutGoogle() => _googleSignIn.signOut();
}

class AuthSession {
  const AuthSession({
    required this.jwt,
    this.userId,
    this.role,
    this.name,
    this.email,
    this.avatarUrl,
  });

  final String jwt;
  final int? userId;
  final String? role;
  final String? name;
  final String? email;
  final String? avatarUrl;
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}