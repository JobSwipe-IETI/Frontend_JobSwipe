import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
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

  Future<void> createExtendedVacancy(
    ExtendedVacancyFormData data, {
    PlatformFile? attachment,
  }) async {
    final String? jwt = await _tokenStorage.readToken();
    if (jwt == null || jwt.isEmpty) {
      throw const VacancyException('No hay sesión activa. Inicia sesión nuevamente.');
    }

    final int? companyId = _extractCompanyId(jwt);
    if (companyId == null) {
      throw const VacancyException('No se pudo identificar la empresa autenticada.');
    }

    final Uri uri = Uri.parse(
      '${AppConfig.backendBaseUrl}/vacancies/extended/multipart?companyId=$companyId',
    );

    final http.MultipartRequest request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $jwt'
      ..fields['payload'] = jsonEncode(data.toJson());

    if (attachment != null && attachment.bytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'document',
          attachment.bytes!,
          filename: attachment.name,
        ),
      );
    }

    final http.StreamedResponse streamedResponse =
      await _client.send(request).timeout(const Duration(seconds: 20));
    final http.Response response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return;
    }

    if (response.statusCode == 400) {
      throw const VacancyException(
        'El formulario tiene datos inválidos o tu rol no puede crear vacantes.',
      );
    }

    if (response.statusCode == 401) {
      throw const VacancyException('Tu sesión expiró. Inicia sesión nuevamente.');
    }

    if (response.statusCode == 404) {
      throw const VacancyException('La empresa no existe en el backend.');
    }

    throw VacancyException(
      'No se pudo crear la vacante (${response.statusCode}): ${response.body}',
    );
  }

  int? _extractCompanyId(String jwt) {
    final List<String> parts = jwt.split('.');
    if (parts.length != 3) {
      return null;
    }

    try {
      final String normalized = base64Url.normalize(parts[1]);
      final Map<String, dynamic> payload =
          jsonDecode(utf8.decode(base64Url.decode(normalized)))
              as Map<String, dynamic>;
      final dynamic sub = payload['sub'];
      if (sub is String) {
        return int.tryParse(sub);
      }
      if (sub is num) {
        return sub.toInt();
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

class ExtendedVacancyFormData {
  const ExtendedVacancyFormData({
    required this.positionRequested,
    required this.vacancySummary,
    required this.desiredMonthlySalary,
    required this.applicationDate,
    required this.candidateFullName,
    required this.phoneNumber,
    required this.email,
    required this.permanentAddress,
    required this.birthDate,
    required this.officialIdentification,
    required this.otherDocuments,
    required this.academicLevel,
    required this.institutionDetails,
    required this.previousEmploymentData,
    required this.responsibilities,
    required this.salaryHistory,
    required this.languages,
    required this.officeFunctions,
    required this.softwareAndMachinery,
    required this.softSkills,
    required this.personalAndWorkReferences,
    required this.referencesContactInfo,
    required this.openQuestionsAnswers,
    required this.killerQuestionsAnswers,
    required this.documentAttachments,
    required this.habitsAndGoals,
  });

  final String positionRequested;
  final String vacancySummary;
  final double desiredMonthlySalary;
  final String applicationDate;
  final String candidateFullName;
  final String phoneNumber;
  final String email;
  final String permanentAddress;
  final String birthDate;
  final String officialIdentification;
  final String otherDocuments;
  final String academicLevel;
  final String institutionDetails;
  final String previousEmploymentData;
  final String responsibilities;
  final String salaryHistory;
  final String languages;
  final String officeFunctions;
  final String softwareAndMachinery;
  final String softSkills;
  final String personalAndWorkReferences;
  final String referencesContactInfo;
  final String openQuestionsAnswers;
  final String killerQuestionsAnswers;
  final String documentAttachments;
  final String habitsAndGoals;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'positionRequested': positionRequested,
      'vacancySummary': vacancySummary,
      'desiredMonthlySalary': desiredMonthlySalary,
      'applicationDate': applicationDate,
      'candidateFullName': candidateFullName,
      'phoneNumber': phoneNumber,
      'email': email,
      'permanentAddress': permanentAddress,
      'birthDate': birthDate,
      'officialIdentification': officialIdentification,
      'otherDocuments': otherDocuments,
      'academicLevel': academicLevel,
      'institutionDetails': institutionDetails,
      'previousEmploymentData': previousEmploymentData,
      'responsibilities': responsibilities,
      'salaryHistory': salaryHistory,
      'languages': languages,
      'officeFunctions': officeFunctions,
      'softwareAndMachinery': softwareAndMachinery,
      'softSkills': softSkills,
      'personalAndWorkReferences': personalAndWorkReferences,
      'referencesContactInfo': referencesContactInfo,
      'openQuestionsAnswers': openQuestionsAnswers,
      'killerQuestionsAnswers': killerQuestionsAnswers,
      'documentAttachments': documentAttachments,
      'habitsAndGoals': habitsAndGoals,
    };
  }
}

class VacancyException implements Exception {
  const VacancyException(this.message);

  final String message;

  @override
  String toString() => message;
}
