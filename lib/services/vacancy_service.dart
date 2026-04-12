import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/vacancy_model.dart';
import 'secure_token_storage.dart';

class VacancyService {
  static const Duration _recommendedVacanciesTimeout = Duration(seconds: 90);
  static const Duration _recommendedJobStatusTimeout = Duration(seconds: 30);

  VacancyService({
    http.Client? client,
    SecureTokenStorage? tokenStorage,
  })  : _client = client ?? http.Client(),
      _tokenStorage = tokenStorage ?? SecureTokenStorage();

  final http.Client _client;
  final SecureTokenStorage _tokenStorage;

  Future<List<VacancyModel>> getRecommendedVacancies({
    required String jwt,
    double minScore = 70,
    int limit = 20,
  }) async {
    final Uri uri = Uri.parse(
      '${AppConfig.backendBaseUrl}/vacancies/recommended',
    ).replace(
      queryParameters: <String, String>{
        'minScore': minScore.toString(),
        'limit': limit.toString(),
      },
    );

    late final http.Response response;
    try {
      response = await _client
          .get(
            uri,
            headers: <String, String>{
              'Authorization': 'Bearer $jwt',
              'Content-Type': 'application/json',
            },
          )
          .timeout(_recommendedVacanciesTimeout);
    } on TimeoutException {
      throw const VacancyException(
        'Las recomendaciones estan tardando mas de lo normal. Intenta de nuevo en unos segundos.',
      );
    }

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw const VacancyException('Formato inválido de recomendaciones.');
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(_mapRecommendedVacancy)
          .toList(growable: false);
    }

    if (response.statusCode == 401) {
      throw const VacancyException('Tu sesión expiró. Inicia sesión nuevamente.');
    }

    if (response.statusCode == 404) {
      throw const VacancyException('No se encontró perfil candidato para recomendar.');
    }

    throw VacancyException(
      'No se pudieron cargar recomendaciones (${response.statusCode}).',
    );
  }

  Future<String> startRecommendedVacanciesJob({
    required String jwt,
    double minScore = 70,
    int limit = 20,
  }) async {
    final Uri uri = Uri.parse(
      '${AppConfig.backendBaseUrl}/vacancies/recommended/jobs',
    ).replace(
      queryParameters: <String, String>{
        'minScore': minScore.toString(),
        'limit': limit.toString(),
      },
    );

    final http.Response response = await _client
        .post(
          uri,
          headers: <String, String>{
            'Authorization': 'Bearer $jwt',
            'Content-Type': 'application/json',
          },
        )
        .timeout(_recommendedVacanciesTimeout);

    if (response.statusCode != 202) {
      throw VacancyException(
        'No se pudo iniciar el analisis de recomendaciones (${response.statusCode}).',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const VacancyException('Respuesta invalida al iniciar recomendaciones.');
    }

    final String? jobId = decoded['jobId']?.toString();
    if (jobId == null || jobId.isEmpty) {
      throw const VacancyException('No se recibio jobId para recomendaciones.');
    }

    return jobId;
  }

  Future<RecommendationJobStatus> getRecommendedVacanciesJobStatus({
    required String jwt,
    required String jobId,
  }) async {
    final Uri uri = Uri.parse(
      '${AppConfig.backendBaseUrl}/vacancies/recommended/jobs/$jobId',
    );

    final http.Response response = await _client
        .get(
          uri,
          headers: <String, String>{
            'Authorization': 'Bearer $jwt',
            'Content-Type': 'application/json',
          },
        )
        .timeout(_recommendedJobStatusTimeout);

    if (response.statusCode != 200) {
      throw VacancyException(
        'No se pudo consultar progreso de recomendaciones (${response.statusCode}).',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const VacancyException('Respuesta invalida de estado de recomendaciones.');
    }

    return RecommendationJobStatus.fromJson(decoded);
  }

  Future<List<VacancyModel>> getRecommendedVacanciesJobResult({
    required String jwt,
    required String jobId,
  }) async {
    final Uri uri = Uri.parse(
      '${AppConfig.backendBaseUrl}/vacancies/recommended/jobs/$jobId/result',
    );

    final http.Response response = await _client
        .get(
          uri,
          headers: <String, String>{
            'Authorization': 'Bearer $jwt',
            'Content-Type': 'application/json',
          },
        )
        .timeout(_recommendedVacanciesTimeout);

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw const VacancyException('Formato inválido de resultado de recomendaciones.');
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(_mapRecommendedVacancy)
          .toList(growable: false);
    }

    if (response.statusCode == 202) {
      throw const VacancyException('Las recomendaciones todavia se estan procesando.');
    }

    throw VacancyException(
      'No se pudo obtener resultado de recomendaciones (${response.statusCode}).',
    );
  }

  Future<List<VacancyModel>> getExploreVacancies({
    required String jwt,
    int limit = 20,
  }) async {
    final Uri uri = Uri.parse('${AppConfig.backendBaseUrl}/vacancies');

    final http.Response response = await _client
        .get(
          uri,
          headers: <String, String>{
            'Authorization': 'Bearer $jwt',
            'Content-Type': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw const VacancyException('Formato inválido de vacantes.');
      }

        return decoded
          .whereType<Map<String, dynamic>>()
          .map(_mapExploreVacancy)
          .take(limit)
          .toList(growable: false);
    }

    if (response.statusCode == 401) {
      throw const VacancyException('Tu sesión expiró. Inicia sesión nuevamente.');
    }

    throw VacancyException(
      'No se pudieron cargar vacantes de exploración (${response.statusCode}).',
    );
  }

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

  Future<void> registerSwipeDecision({
    required String jwt,
    required int vacancyId,
    required SwipeDecision decision,
  }) async {
    final Uri uri = Uri.parse(
      '${AppConfig.backendBaseUrl}/vacancies/$vacancyId/swipe',
    ).replace(
      queryParameters: <String, String>{
        'decision': decision == SwipeDecision.like ? 'LIKE' : 'DISLIKE',
      },
    );

    final http.Response response = await _client
        .post(
          uri,
          headers: <String, String>{
            'Authorization': 'Bearer $jwt',
            'Content-Type': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 204) {
      return;
    }

    throw VacancyException(
      'No se pudo guardar tu decision de swipe (${response.statusCode}).',
    );
  }

  VacancyModel _mapRecommendedVacancy(Map<String, dynamic> json) {
    final double score = _asDouble(json['compatibilityPercentage']) ?? 0;
    final int id = _asInt(json['vacancyId']) ?? _asInt(json['id']) ?? 0;
    final String title = _asString(json['title']) ?? 'Vacante recomendada';
    final String location = _asString(json['location']) ?? 'Ubicación por definir';
    final String description = _asString(json['feedback']) ??
        'Esta vacante fue recomendada por tu nivel de compatibilidad.';

    return VacancyModel(
      id: id,
      title: title,
      company: 'Empresa recomendada',
      location: location,
      salary: 'Salario por definir',
      matchPercentage: score,
      badge: _recommendationBadge(score),
      description: description,
      logo: 'recommended',
    );
  }

  VacancyModel _mapExploreVacancy(Map<String, dynamic> json) {
    final int id = _asInt(json['id']) ?? 0;
    final String title = _asString(json['title']) ?? 'Vacante disponible';
    final String location = _asString(json['location']) ?? 'Ubicación por definir';
    final String description = _asString(json['description']) ??
        'Vacante disponible para exploración.';

    final String company = _asString(json['companyName']) ?? 'Empresa disponible';

    return VacancyModel(
      id: id,
      title: title,
      company: company,
      location: location,
      salary: _formatSalary(json),
      matchPercentage: 55,
      badge: 'Exploración adicional',
      description: description,
      logo: 'explore',
    );
  }

  String _recommendationBadge(double score) {
    if (score >= 85) {
      return 'Alta compatibilidad';
    }
    if (score >= 70) {
      return 'Recomendada';
    }
    return 'Exploración adicional';
  }

  String _formatSalary(Map<String, dynamic> json) {
    final double? minSalary = _asDouble(json['minSalary']);
    final double? maxSalary = _asDouble(json['maxSalary']);

    if (minSalary != null && maxSalary != null) {
      return '\$${minSalary.toStringAsFixed(0)} - \$${maxSalary.toStringAsFixed(0)}';
    }

    return _asString(json['salary']) ?? 'Salario por definir';
  }

  String? _asString(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return value.toString();
  }

  int? _asInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  double? _asDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}

class VacancyFormData {
  const VacancyFormData({
    required this.title,
    required this.description,
    required this.location,
    required this.sector,
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
  final String sector;
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
        'sector': sector,
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

class RecommendationJobStatus {
  RecommendationJobStatus({
    required this.jobId,
    required this.status,
    required this.processed,
    required this.total,
    required this.progressPercent,
    required this.message,
    this.error,
  });

  final String jobId;
  final String status;
  final int processed;
  final int total;
  final int progressPercent;
  final String message;
  final String? error;

  bool get isCompleted => status.toUpperCase() == 'COMPLETED';
  bool get isFailed => status.toUpperCase() == 'FAILED';

  static RecommendationJobStatus fromJson(Map<String, dynamic> json) {
    return RecommendationJobStatus(
      jobId: json['jobId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'RUNNING',
      processed: _toInt(json['processed']),
      total: _toInt(json['total']),
      progressPercent: _toInt(json['progressPercent']),
      message: json['message']?.toString() ?? '',
      error: json['error']?.toString(),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

enum SwipeDecision {
  like,
  dislike,
}
