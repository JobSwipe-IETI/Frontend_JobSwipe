import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'secure_token_storage.dart';

class VacancyService {
  VacancyService({
    http.Client? client,
    SecureTokenStorage? tokenStorage,
  })  : _client = client ?? http.Client(),
        _tokenStorage = tokenStorage ?? SecureTokenStorage();

  final http.Client _client;
  final SecureTokenStorage _tokenStorage;

  Future<void> createVacancy(VacancyFormData data) async {
    final String? jwt = await _tokenStorage.readToken();
    if (jwt == null || jwt.isEmpty) {
      throw const VacancyException('No hay sesión activa. Inicia sesión nuevamente.');
    }

    final Uri uri = Uri.parse('${AppConfig.backendBaseUrl}/vacancies');

    final http.Response response = await _client
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer $jwt',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(data.toJson()),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 201) return;

    if (response.statusCode == 400) {
      throw const VacancyException(
        'Los datos del formulario son inválidos o tu cuenta no es de empresa.',
      );
    }
    if (response.statusCode == 401) {
      throw const VacancyException('Tu sesión expiró. Inicia sesión nuevamente.');
    }
    if (response.statusCode == 404) {
      throw const VacancyException('La empresa no fue encontrada en el sistema.');
    }

    throw VacancyException(
      'No se pudo crear la vacante (${response.statusCode}): ${response.body}',
    );
  }
}

class VacancyFormData {
  const VacancyFormData({
    required this.title,
    required this.description,
    required this.location,
    required this.modality,
    required this.employmentType,
    required this.experienceLevel,
    required this.technologies,
    required this.softSkills,
    required this.responsibilities,
    required this.technicalRequirements,
    required this.minSalary,
    required this.maxSalary,
    required this.benefits,
  });

  final String title;
  final String description;
  final String location;
  final String modality;
  final String employmentType;
  final String experienceLevel;
  final List<String> technologies;
  final List<String> softSkills;
  final List<String> responsibilities;
  final List<String> technicalRequirements;
  final double minSalary;
  final double maxSalary;
  final List<String> benefits;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title,
        'description': description,
        'location': location,
        'modality': modality,
        'employmentType': employmentType,
        'experienceLevel': experienceLevel,
        'technologies': technologies,
        'softSkills': softSkills,
        'responsibilities': responsibilities,
        'technicalRequirements': technicalRequirements,
        'minSalary': minSalary,
        'maxSalary': maxSalary,
        'benefits': benefits,
      };
}

class VacancyException implements Exception {
  const VacancyException(this.message);

  final String message;

  @override
  String toString() => message;
}
