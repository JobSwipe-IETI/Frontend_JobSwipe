import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class ProfileApiService {
  ProfileApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>?> getProfileByUserId({
    required String jwt,
    required int userId,
  }) async {
    final Uri uri = Uri.parse('${AppConfig.backendBaseUrl}/profiles/user/$userId');

    final response = await _client.get(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwt',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    if (response.statusCode == 404) {
      return null;
    }

    throw ProfileApiException(
      'Error consultando perfil (${response.statusCode}): ${response.body}',
    );
  }

  Future<bool> hasProfile({required String jwt, required int userId}) async {
    final Uri uri = Uri.parse('${AppConfig.backendBaseUrl}/profiles/user/$userId');

    final response = await _client.get(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwt',
      },
    );

    if (response.statusCode == 200) {
      return true;
    }

    if (response.statusCode == 404) {
      return false;
    }

    throw ProfileApiException(
      'Error consultando perfil (${response.statusCode}): ${response.body}',
    );
  }

  Future<void> createCandidateProfile({
    required String jwt,
    required int userId,
    required Map<String, dynamic> payload,
  }) async {
    final Uri uri = Uri.parse(
      '${AppConfig.backendBaseUrl}/profiles/candidate/$userId',
    );

    final response = await _client.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwt',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw ProfileApiException(
        _extractApiError(
          response,
          fallback:
              'No se pudo guardar perfil candidato (${response.statusCode})',
        ),
      );
    }
  }

  Future<void> createCompanyProfile({
    required String jwt,
    required int userId,
    required Map<String, dynamic> payload,
  }) async {
    final Uri uri = Uri.parse(
      '${AppConfig.backendBaseUrl}/profiles/company/$userId',
    );

    final response = await _client.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwt',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw ProfileApiException(
        _extractApiError(
          response,
          fallback: 'No se pudo guardar perfil empresa (${response.statusCode})',
        ),
      );
    }
  }

  /// Calls PATCH /api/auth/me/role and returns the new JWT on success, or null.
  Future<String?> updateUserRole({
    required String jwt,
    required String role,
  }) async {
    final response = await _client
        .patch(
          Uri.parse('${AppConfig.backendBaseUrl}/api/auth/me/role'),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $jwt',
          },
          body: jsonEncode(<String, String>{'role': role}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return decoded['accessToken'] as String?;
    }
    return null;
  }

  String _extractApiError(http.Response response, {required String fallback}) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final Object? errors = decoded['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final firstValue = errors.values.first;
          if (firstValue != null && firstValue.toString().trim().isNotEmpty) {
            return firstValue.toString();
          }
        }

        final Object? message = decoded['message'];
        if (message != null && message.toString().trim().isNotEmpty) {
          return message.toString();
        }
      }
    } catch (_) {
      // Keep fallback if backend payload is not JSON.
    }

    return fallback;
  }
}

class ProfileApiException implements Exception {
  const ProfileApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
