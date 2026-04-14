import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/vacancy_model.dart';
import 'secure_token_storage.dart';

class VacancyService {
  static const Duration _recommendedVacanciesTimeout = Duration(seconds: 90);
  static const Duration _recommendedJobStatusTimeout = Duration(seconds: 30);

  VacancyService({http.Client? client, SecureTokenStorage? tokenStorage})
    : _client = client ?? http.Client(),
      _tokenStorage = tokenStorage ?? SecureTokenStorage();

  final http.Client _client;
  final SecureTokenStorage _tokenStorage;

  Future<List<VacancyModel>> getRecommendedVacancies({
    required String jwt,
    double minScore = 70,
    int limit = 20,
  }) async {
    final Uri uri =
        Uri.parse('${AppConfig.backendBaseUrl}/vacancies/recommended').replace(
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
      throw const VacancyException(
        'Tu sesión expiró. Inicia sesión nuevamente.',
      );
    }

    if (response.statusCode == 404) {
      throw const VacancyException(
        'No se encontró perfil candidato para recomendar.',
      );
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
    final Uri uri =
        Uri.parse(
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
      throw const VacancyException(
        'Respuesta invalida al iniciar recomendaciones.',
      );
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
      throw const VacancyException(
        'Respuesta invalida de estado de recomendaciones.',
      );
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
        throw const VacancyException(
          'Formato inválido de resultado de recomendaciones.',
        );
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(_mapRecommendedVacancy)
          .toList(growable: false);
    }

    if (response.statusCode == 202) {
      throw const VacancyException(
        'Las recomendaciones todavia se estan procesando.',
      );
    }

    throw VacancyException(
      'No se pudo obtener resultado de recomendaciones (${response.statusCode}).',
    );
  }

  Future<RecommendationJobPartial> getRecommendedVacanciesJobPartial({
    required String jwt,
    required String jobId,
    required int offset,
    int limit = 10,
  }) async {
    final Uri uri =
        Uri.parse(
          '${AppConfig.backendBaseUrl}/vacancies/recommended/jobs/$jobId/partial',
        ).replace(
          queryParameters: <String, String>{
            'offset': offset.toString(),
            'limit': limit.toString(),
          },
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
        'No se pudo obtener resultados parciales (${response.statusCode}).',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const VacancyException(
        'Respuesta invalida de resultados parciales.',
      );
    }

    return RecommendationJobPartial.fromJson(
      decoded,
      mapper: _mapRecommendedVacancy,
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
      throw const VacancyException(
        'Tu sesión expiró. Inicia sesión nuevamente.',
      );
    }

    throw VacancyException(
      'No se pudieron cargar vacantes de exploración (${response.statusCode}).',
    );
  }

  Future<void> createVacancy(VacancyFormData data) async {
    final String? jwt = await _tokenStorage.readToken();
    if (jwt == null || jwt.isEmpty) {
      throw const VacancyException(
        'No hay sesión activa. Inicia sesión nuevamente.',
      );
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
      throw const VacancyException(
        'Tu sesión expiró. Inicia sesión nuevamente.',
      );
    }
    if (response.statusCode == 404) {
      throw const VacancyException(
        'La empresa no fue encontrada en el sistema.',
      );
    }

    throw VacancyException(
      'No se pudo crear la vacante (${response.statusCode}): ${response.body}',
    );
  }

  Future<List<VacancyModel>> getCompanyVacancies({required String jwt}) async {
    final Uri uri = Uri.parse('${AppConfig.backendBaseUrl}/vacancies');

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
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw const VacancyException(
        'La carga de vacantes está tardando más de lo esperado. Intenta de nuevo.',
      );
    }

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw const VacancyException('Formato inválido de vacantes.');
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(_mapCompanyVacancy)
          .toList(growable: false);
    }

    if (response.statusCode == 401) {
      throw const VacancyException(
        'Tu sesión expiró. Inicia sesión nuevamente.',
      );
    }

    throw VacancyException(
      'No se pudieron cargar tus vacantes (${response.statusCode}).',
    );
  }

  Future<List<CompanyLikeActivity>> getCompanyLikeActivity({
    required String jwt,
    int limit = 20,
  }) async {
    final Uri uri = Uri.parse(
      '${AppConfig.backendBaseUrl}/vacancies/company/activity',
    ).replace(queryParameters: <String, String>{'limit': limit.toString()});

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
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw const VacancyException(
        'La actividad está tardando en cargar. Intenta de nuevo.',
      );
    }

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw const VacancyException('Formato inválido de actividad de likes.');
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(CompanyLikeActivity.fromJson)
          .toList(growable: false);
    }

    if (response.statusCode == 401) {
      throw const VacancyException(
        'Tu sesión expiró. Inicia sesión nuevamente.',
      );
    }

    throw VacancyException(
      'No se pudo cargar la actividad (${response.statusCode}).',
    );
  }

  Future<List<CompanyVacancyPipelineItem>> getCompanyVacancyPipeline({
    required String jwt,
  }) async {
    final Uri uri = Uri.parse(
      '${AppConfig.backendBaseUrl}/vacancies/company/pipeline',
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
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw const VacancyException(
        'El pipeline está tardando en cargar. Intenta de nuevo.',
      );
    }

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw const VacancyException(
          'Formato inválido de pipeline de vacantes.',
        );
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(CompanyVacancyPipelineItem.fromJson)
          .toList(growable: false);
    }

    if (response.statusCode == 401) {
      throw const VacancyException(
        'Tu sesión expiró. Inicia sesión nuevamente.',
      );
    }

    throw VacancyException(
      'No se pudo cargar el pipeline (${response.statusCode}).',
    );
  }

  Future<List<VacancyApplicant>> getVacancyApplicants({
    required String jwt,
    required int vacancyId,
    int limit = 50,
  }) async {
    final Uri uri = Uri.parse(
      '${AppConfig.backendBaseUrl}/vacancies/company/vacancies/$vacancyId/applicants',
    ).replace(queryParameters: <String, String>{'limit': limit.toString()});

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
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw const VacancyException(
        'La carga de postulados está tardando. Intenta de nuevo.',
      );
    }

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw const VacancyException('Formato inválido de postulados.');
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(VacancyApplicant.fromJson)
          .toList(growable: false);
    }

    if (response.statusCode == 401) {
      throw const VacancyException(
        'Tu sesión expiró. Inicia sesión nuevamente.',
      );
    }

    if (response.statusCode == 404) {
      throw const VacancyException(
        'La vacante no fue encontrada o no pertenece a tu empresa.',
      );
    }

    throw VacancyException(
      'No se pudieron cargar postulados (${response.statusCode}).',
    );
  }

  Future<VacancyFormData> getVacancyById({
    required String jwt,
    required int vacancyId,
  }) async {
    final Uri uri = Uri.parse(
      '${AppConfig.backendBaseUrl}/vacancies/$vacancyId',
    );

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
      final Map<String, dynamic> decoded =
          jsonDecode(response.body) as Map<String, dynamic>;
      return VacancyFormData.fromJson(decoded);
    }

    if (response.statusCode == 401) {
      throw const VacancyException(
        'Tu sesión expiró. Inicia sesión nuevamente.',
      );
    }

    if (response.statusCode == 404) {
      throw const VacancyException('La vacante no fue encontrada.');
    }

    throw VacancyException(
      'No se pudo cargar la vacante (${response.statusCode}).',
    );
  }

  Future<void> updateVacancy({
    required String jwt,
    required int vacancyId,
    required VacancyFormData data,
  }) async {
    final Uri uri = Uri.parse(
      '${AppConfig.backendBaseUrl}/vacancies/$vacancyId',
    );

    final http.Response response = await _client
        .put(
          uri,
          headers: <String, String>{
            'Authorization': 'Bearer $jwt',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(data.toJson()),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) return;

    if (response.statusCode == 400) {
      throw const VacancyException('Los datos del formulario son inválidos.');
    }
    if (response.statusCode == 401) {
      throw const VacancyException(
        'Tu sesión expiró. Inicia sesión nuevamente.',
      );
    }
    if (response.statusCode == 404) {
      throw const VacancyException('La vacante no fue encontrada.');
    }

    throw VacancyException(
      'No se pudo actualizar la vacante (${response.statusCode}).',
    );
  }

  Future<void> deleteVacancy({
    required String jwt,
    required int vacancyId,
  }) async {
    final Uri uri = Uri.parse(
      '${AppConfig.backendBaseUrl}/vacancies/$vacancyId',
    );

    final http.Response response = await _client
        .delete(
          uri,
          headers: <String, String>{
            'Authorization': 'Bearer $jwt',
            'Content-Type': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 204) return;

    if (response.statusCode == 401) {
      throw const VacancyException(
        'Tu sesión expiró. Inicia sesión nuevamente.',
      );
    }
    if (response.statusCode == 404) {
      throw const VacancyException('La vacante no fue encontrada.');
    }

    throw VacancyException(
      'No se pudo eliminar la vacante (${response.statusCode}).',
    );
  }

  Future<void> registerSwipeDecision({
    required String jwt,
    required int vacancyId,
    required SwipeDecision decision,
  }) async {
    final Uri uri =
        Uri.parse(
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
    final String location =
        _asString(json['location']) ?? 'Ubicación por definir';
    final String description =
        _asString(json['feedback']) ??
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
    final String location =
        _asString(json['location']) ?? 'Ubicación por definir';
    final String description =
        _asString(json['description']) ??
        'Vacante disponible para exploración.';

    final String company =
        _asString(json['companyName']) ?? 'Empresa disponible';

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

  VacancyModel _mapCompanyVacancy(Map<String, dynamic> json) {
    final int id = _asInt(json['id']) ?? 0;
    final String title = _asString(json['title']) ?? 'Vacante';
    final String location =
        _asString(json['location']) ?? 'Ubicación por definir';
    final String description =
        _asString(json['description']) ?? 'Vacante creada por tu empresa.';

    return VacancyModel(
      id: id,
      title: title,
      company: 'Tu vacante',
      location: location,
      salary: _formatSalary(json),
      matchPercentage: 0,
      badge: 'Administrar',
      description: description,
      logo: 'company',
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

  factory VacancyFormData.fromJson(Map<String, dynamic> json) {
    return VacancyFormData(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      sector: json['sector']?.toString() ?? 'Otro',
      modality: json['modality']?.toString() ?? 'REMOTE',
      employmentType: json['employmentType']?.toString() ?? 'FULL_TIME',
      experienceLevel: json['experienceLevel']?.toString() ?? 'JUNIOR',
      technologies: _asStringList(json['technologies']),
      softSkills: _asStringList(json['softSkills']),
      responsibilities: _asStringList(json['responsibilities']),
      technicalRequirements: _asStringList(json['technicalRequirements']),
      minSalary: _toDouble(json['minSalary']),
      maxSalary: _toDouble(json['maxSalary']),
      benefits: _asStringList(json['benefits']),
    );
  }

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

  static List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList(growable: false);
    }
    return <String>[];
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

class CompanyLikeActivity {
  CompanyLikeActivity({
    required this.vacancyId,
    required this.vacancyTitle,
    required this.candidateId,
    required this.candidateName,
    required this.likedAt,
  });

  final int vacancyId;
  final String vacancyTitle;
  final int candidateId;
  final String candidateName;
  final DateTime? likedAt;

  static CompanyLikeActivity fromJson(Map<String, dynamic> json) {
    return CompanyLikeActivity(
      vacancyId: _toInt(json['vacancyId']),
      vacancyTitle: json['vacancyTitle']?.toString() ?? 'Vacante',
      candidateId: _toInt(json['candidateId']),
      candidateName: json['candidateName']?.toString() ?? 'Candidato',
      likedAt: _toDateTime(json['likedAt']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

class CompanyVacancyPipelineItem {
  CompanyVacancyPipelineItem({
    required this.vacancyId,
    required this.vacancyTitle,
    required this.applicantsCount,
  });

  final int vacancyId;
  final String vacancyTitle;
  final int applicantsCount;

  static CompanyVacancyPipelineItem fromJson(Map<String, dynamic> json) {
    return CompanyVacancyPipelineItem(
      vacancyId: CompanyLikeActivity._toInt(json['vacancyId']),
      vacancyTitle: json['vacancyTitle']?.toString() ?? 'Vacante',
      applicantsCount: CompanyLikeActivity._toInt(json['applicantsCount']),
    );
  }
}

class VacancyApplicant {
  VacancyApplicant({
    required this.candidateId,
    required this.candidateName,
    required this.compatibilityPercentage,
    required this.compatibilityLevel,
    required this.feedback,
    required this.appliedAt,
  });

  final int candidateId;
  final String candidateName;
  final double? compatibilityPercentage;
  final String? compatibilityLevel;
  final String? feedback;
  final DateTime? appliedAt;

  static VacancyApplicant fromJson(Map<String, dynamic> json) {
    final dynamic rawPercentage = json['compatibilityPercentage'];
    double? compatibilityPercentage;
    if (rawPercentage is num) {
      compatibilityPercentage = rawPercentage.toDouble();
    } else if (rawPercentage is String) {
      compatibilityPercentage = double.tryParse(rawPercentage);
    }

    return VacancyApplicant(
      candidateId: CompanyLikeActivity._toInt(json['candidateId']),
      candidateName: json['candidateName']?.toString() ?? 'Candidato',
      compatibilityPercentage: compatibilityPercentage,
      compatibilityLevel: json['compatibilityLevel']?.toString(),
      feedback: json['feedback']?.toString(),
      appliedAt: CompanyLikeActivity._toDateTime(json['appliedAt']),
    );
  }
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

class RecommendationJobPartial {
  RecommendationJobPartial({
    required this.nextOffset,
    required this.done,
    required this.items,
  });

  final int nextOffset;
  final bool done;
  final List<VacancyModel> items;

  static RecommendationJobPartial fromJson(
    Map<String, dynamic> json, {
    required VacancyModel Function(Map<String, dynamic>) mapper,
  }) {
    final dynamic rawItems = json['items'];
    final List<VacancyModel> items = (rawItems is List)
        ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(mapper)
              .toList(growable: false)
        : const <VacancyModel>[];

    return RecommendationJobPartial(
      nextOffset: RecommendationJobStatus._toInt(json['nextOffset']),
      done: json['done'] == true,
      items: items,
    );
  }
}

enum SwipeDecision { like, dislike }
