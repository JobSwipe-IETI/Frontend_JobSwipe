import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class PremiumService {
  static const String _tag = '[PremiumService]';
  final http.Client _client = http.Client();

  Future<void> upgradeToPremium({
    required String jwt,
    required int userId,
  }) async {
    final Uri uri = Uri.parse(
      '${AppConfig.backendBaseUrl}/users/$userId/premium',
    );

    try {
      final response = await _client
          .patch(
            uri,
            headers: <String, String>{
              'Authorization': 'Bearer $jwt',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(<String, dynamic>{
              'isPremium': true,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception('Error upgrading to premium: ${response.statusCode}');
      }

      // Parse response to verify isPremium is true
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid response format');
      }

      if (decoded['isPremium'] != true) {
        throw Exception('Premium upgrade verification failed');
      }
    } catch (e) {
      print('$_tag Error: $e');
      rethrow;
    }
  }
}
