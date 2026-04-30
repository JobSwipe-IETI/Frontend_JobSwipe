import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

import '../controllers/user_provider.dart';
import '../services/profile_api_service.dart';
import '../services/auth_service.dart';

class CandidateProfileWidget extends StatefulWidget {
  const CandidateProfileWidget({
    super.key,
    required this.userProvider,
    required this.onLogout,
    required this.onEditProfile,
    required this.jwt,
    this.userId,
  });

  final UserProvider userProvider;
  final VoidCallback onLogout;
  final VoidCallback onEditProfile;
  final String jwt;
  final int? userId;

  @override
  State<CandidateProfileWidget> createState() => _CandidateProfileWidgetState();
}

class _CandidateProfileWidgetState extends State<CandidateProfileWidget> {
  bool _isPremium = false;
  bool _isUpdatingPremium = false;

  late List<String> _userSkills;

  Map<String, dynamic>? _feedback;
  bool _isLoadingFeedback = false;
  String? _feedbackError;
  int? _lastFeedbackUserId;
  String? _lastFeedbackJwt;
  final ProfileApiService _profileApi = ProfileApiService();

  @override
  void initState() {
    super.initState();
    _syncSkillsFromProfile();
    _loadPremiumStatus();
    _loadFeedbackIfPossible();
  }

  void _loadPremiumStatus() {
    setState(() {
      _isPremium = widget.userProvider.currentUser.isPremium;
    });
  }

  @override
  void didUpdateWidget(covariant CandidateProfileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldSkills = oldWidget.userProvider.currentUser.skills;
    final newSkills = widget.userProvider.currentUser.skills;
    if (oldSkills != newSkills) {
      _syncSkillsFromProfile();
    }

    // If JWT or userId changed, reload feedback
    if (oldWidget.jwt != widget.jwt || oldWidget.userId != widget.userId) {
      _loadFeedbackIfPossible();
    }

    if (oldWidget.userProvider.currentUser.isPremium !=
        widget.userProvider.currentUser.isPremium) {
      _loadPremiumStatus();
      if (widget.userProvider.currentUser.isPremium) {
        _loadFeedbackIfPossible();
      } else if (mounted) {
        setState(() {
          _feedback = null;
          _feedbackError = null;
          _isLoadingFeedback = false;
        });
      }
    }
  }

  void _syncSkillsFromProfile() {
    final raw = widget.userProvider.currentUser.skills;
    if (raw == null || raw.trim().isEmpty) {
      _userSkills = [];
      return;
    }
    _userSkills = _parseSkills(raw);
  }

  Future<void> _loadFeedbackIfPossible() async {
    final int? userId = widget.userId ?? AuthService.extractUserIdFromJwt(widget.jwt);
    if (userId == null || widget.jwt.isEmpty || !_isPremium) {
      if (mounted) {
        setState(() {
          _isLoadingFeedback = false;
        });
      }
      return;
    }

    // No recargar si ya tenemos feedback para este usuario
    if (_lastFeedbackUserId == userId && _lastFeedbackJwt == widget.jwt && _feedback != null) {
      return;
    }

    setState(() {
      _isLoadingFeedback = true;
      _feedbackError = null;
    });

    try {
      final Map<String, dynamic>? fb = await _profileApi.getProfileFeedback(
        jwt: widget.jwt,
        userId: userId,
      );
      if (mounted) {
        setState(() {
          _feedback = fb;
          _lastFeedbackUserId = userId;
          _lastFeedbackJwt = widget.jwt;
          _feedbackError = null;
          _isLoadingFeedback = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _feedbackError = null;
          _isLoadingFeedback = false;
        });
      }
    }
  }

  Future<void> _triggerReAnalysis() async {
    final int? userId = widget.userId ?? AuthService.extractUserIdFromJwt(widget.jwt);
    if (userId == null) {
      return;
    }

    setState(() {
      _isLoadingFeedback = true;
      _feedbackError = null;
      _feedback = null;
    });

    try {
      // Trigger re-analysis
      await _profileApi.reAnalyzeProfile(
        jwt: widget.jwt,
        userId: userId,
      );

      // Poll for the saved feedback instead of failing fast.
      const int maxAttempts = 8;
      const Duration pollDelay = Duration(seconds: 3);
      for (int attempt = 0; attempt < maxAttempts && mounted; attempt++) {
        final Map<String, dynamic>? fb = await _profileApi.getProfileFeedback(
          jwt: widget.jwt,
          userId: userId,
        );

        if (fb != null) {
          setState(() {
            _feedback = fb;
            _feedbackError = null;
            _isLoadingFeedback = false;
          });
          return;
        }

        if (attempt < maxAttempts - 1) {
          await Future.delayed(pollDelay);
        }
      }

      await _loadFeedbackIfPossible();
    } catch (e) {
      if (mounted) {
        setState(() {
          _feedbackError = null;
          _isLoadingFeedback = false;
        });
      }
    }
  }

  List<String> _parseSkills(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((item) => item.toString()).toList();
      }
    } catch (_) {
      // Fall back to comma-separated values below.
    }

    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.userProvider.currentUser;

    return Container(
      color: const Color(0xFFF5F5F7),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 96),
        child: Column(
          children: [
            _buildTopHeader(profile),
            Transform.translate(
              offset: const Offset(0, -28),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildProfileCompleteness(),
                    const SizedBox(height: 12),
                    _buildAiFeedbackCard(),
                    const SizedBox(height: 12),
                    _buildSkillsCard(),
                    const SizedBox(height: 12),
                    _buildExperienceCard(),
                    const SizedBox(height: 12),
                    _buildEducationCard(),
                    const SizedBox(height: 12),
                    _buildAdditionalInfoCard(),
                    const SizedBox(height: 12),
                    _buildSettingsCard(),
                    const SizedBox(height: 12),
                    _buildLogoutButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(dynamic profile) {
    final initials = profile.name.isNotEmpty
        ? profile.name
              .trim()
              .split(' ')
              .take(2)
              .map((word) => word.isNotEmpty ? word[0] : '')
              .join()
              .toUpperCase()
        : 'CG';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 52),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A237E), Color(0xFF7C4DFF)],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Mi Perfil',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (_isPremium)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Text(
                    'PREMIUM',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ),
              GestureDetector(
                onTap: widget.onEditProfile,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.white.withValues(alpha: 0.22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.professionalTitle ?? 'Senior Frontend Developer',
                      style: TextStyle(
                        color: Color(0xFFBFDBFE),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '📍 ${profile.location ?? 'Bogotá, Colombia'}',
                      style: const TextStyle(
                        color: Color(0xFF93C5FD),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCompleteness() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Completitud del perfil',
                style: TextStyle(
                  color: Color(0xFF263238),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Spacer(),
              Text(
                '${_getCompletionPercent(widget.userProvider.currentUser)}%',
                style: TextStyle(
                  color: Color(0xFF7C4DFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(999),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0,
                  end: _getCompletionPercent(widget.userProvider.currentUser) / 100,
                ),
                duration: const Duration(milliseconds: 950),
                builder: (context, value, _) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: value,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF7C4DFF), Color(0xFF00B4D8)],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getCompletionHint(widget.userProvider.currentUser),
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
          ),
        ],
      ),
    );
  }
  Widget _buildAiFeedbackCard() {
    if (!_isPremium) {
      return Container();
    }

    if (_isLoadingFeedback) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0,4))],
        ),
        child: Row(
          children: const [
            SizedBox(width: 16),
            CircularProgressIndicator(),
            SizedBox(width: 12),
            Text('Cargando análisis IA guardado...'),
          ],
        ),
      );
    }

    // If feedback is null or error, show the empty state with button
    if (_feedback == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0,4))],
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: Color(0xFF7C4DFF)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _feedbackError != null
                        ? 'Error al cargar análisis. Intenta nuevamente.'
                        : 'No hay un análisis IA guardado para mostrar.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _triggerReAnalysis,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Re-analizar perfil'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C4DFF),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Feedback exists: show compact controls only.

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0,4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: Color(0xFF7C4DFF)),
              const SizedBox(width: 8),
              const Text('Mejoras IA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              const Spacer(),
              Tooltip(
                message: 'Re-analizar perfil',
                child: IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  onPressed: _triggerReAnalysis,
                  color: const Color(0xFF7C4DFF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Las mejoras IA se muestran en cada sección del perfil.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  int _getCompletionPercent(dynamic profile) {
    final fields = [
      profile.name,
      profile.professionalTitle,
      profile.description,
      profile.skills,
      profile.experience,
      profile.education,
      profile.location,
      profile.nationality,
      profile.phoneNumber,
      profile.languages,
      profile.expectedSalary,
      profile.availability,
    ];

    final filled = fields.where((value) {
      if (value == null) return false;
      if (value is num) return value > 0;
      return value.toString().trim().isNotEmpty;
    }).length;

    return ((filled / fields.length) * 100).round();
  }

  String _getCompletionHint(dynamic profile) {
    if ((profile.experience ?? '').toString().trim().isEmpty) {
      return 'Agrega tu experiencia laboral para llegar al 100%';
    }
    if ((profile.skills ?? '').toString().trim().isEmpty) {
      return 'Agrega tus habilidades para completar el perfil';
    }
    return 'Tu perfil ya está casi completo';
  }

  Map<String, Object> _severityPalette(String severity) {
    if (severity == 'high') {
      return {
        'background': const Color(0xFFFFF1F2),
        'border': const Color(0xFFFECACA),
        'chip': const Color(0xFFFEE2E2),
        'text': const Color(0xFFB91C1C),
        'icon': Icons.warning_rounded,
      };
    }
    if (severity == 'medium') {
      return {
        'background': const Color(0xFFFFFBEB),
        'border': const Color(0xFFFDE68A),
        'chip': const Color(0xFFFEF3C7),
        'text': const Color(0xFFB45309),
        'icon': Icons.info_rounded,
      };
    }
    return {
      'background': const Color(0xFFF8FAFC),
      'border': const Color(0xFFE2E8F0),
      'chip': const Color(0xFFE2E8F0),
      'text': const Color(0xFF334155),
      'icon': Icons.check_circle_rounded,
    };
  }

  String _sectionSeverity(List<dynamic> suggestions) {
    var hasMedium = false;
    for (final item in suggestions) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final severity = item['severity']?.toString() ?? 'low';
      if (severity == 'high') {
        return 'high';
      }
      if (severity == 'medium') {
        hasMedium = true;
      }
    }
    return hasMedium ? 'medium' : 'low';
  }

  Widget _buildSkillsCard() {
    final skillsSuggestions = _suggestionsForAliases(
      const ['habilidades', 'skills'],
    );

    return _card(
      child: Column(
        children: [
          const Row(
            children: [
              Text(
                'Habilidades',
                style: TextStyle(
                  color: Color(0xFF263238),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (_userSkills.isEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Sin habilidades registradas',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _userSkills
                    .map(
                      (skill) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0EEFF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          skill,
                          style: const TextStyle(
                            color: Color(0xFF7C4DFF),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          if (skillsSuggestions.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildSectionAlert(
              sectionTitle: 'Habilidades',
              suggestions: skillsSuggestions,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExperienceCard() {
    final experienceSuggestions = _suggestionsForAliases(
      const ['experiencia', 'experience'],
    );

    return _card(
      child: Column(
        children: [
          Row(
            children: const [
              Icon(Icons.work_rounded, size: 16, color: Color(0xFF1A237E)),
              SizedBox(width: 8),
              Text(
                'Experiencia',
                style: TextStyle(
                  color: Color(0xFF263238),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._buildExperienceItems().map(_experienceTile),
          if (experienceSuggestions.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildSectionAlert(
              sectionTitle: 'Experiencia',
              suggestions: experienceSuggestions,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEducationCard() {
    final educationSuggestions = _suggestionsForAliases(
      const ['educación', 'educacion', 'education'],
    );

    return _card(
      child: Column(
        children: [
          Row(
            children: const [
              Icon(Icons.school_rounded, size: 16, color: Color(0xFF1A237E)),
              SizedBox(width: 8),
              Text(
                'Educación',
                style: TextStyle(
                  color: Color(0xFF263238),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._buildEducationItems().map(_educationTile),
          if (educationSuggestions.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildSectionAlert(
              sectionTitle: 'Educación',
              suggestions: educationSuggestions,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoCard() {
    final profile = widget.userProvider.currentUser;
    final salary = profile.expectedSalary != null
        ? 'USD ${profile.expectedSalary!.toStringAsFixed(0)}'
        : 'No especificado';
    final additionalSuggestions = _suggestionsForAliases(
      const [
        'información adicional',
        'informacion adicional',
        'additional',
        'contact',
        'summary',
        'professional_title',
      ],
    );

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información adicional',
            style: TextStyle(
              color: Color(0xFF263238),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          _infoRow('Resumen', profile.description),
          _infoRow('Nacionalidad', profile.nationality ?? 'No especificado'),
          _infoRow('Teléfono', profile.phoneNumber ?? 'No especificado'),
          _infoRow('Sector', profile.industry ?? 'No especificado'),
          _infoRow('Idiomas', profile.languages ?? 'No especificado'),
          _infoRow('Salario esperado', salary),
          _infoRow('Disponibilidad', profile.availability ?? 'No especificado'),
          _infoRow('GitHub', profile.githubUrl ?? 'No especificado', isLink: true),
          _infoRow('LinkedIn', profile.linkedinUrl ?? 'No especificado', isLink: true),
          if (additionalSuggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildSectionAlert(
              sectionTitle: 'Información adicional',
              suggestions: additionalSuggestions,
            ),
          ],
        ],
      ),
    );
  }

  String _normalizeSectionLabel(String value) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .trim();
  }

  List<Map<String, dynamic>> _suggestionsForAliases(List<String> aliases) {
    if (_feedback == null) {
      return const [];
    }

    final normalizedAliases = aliases.map(_normalizeSectionLabel).toList();
    final List<Map<String, dynamic>> collected = [];
    final seen = <String>{};

    final sections = _feedback?['sections'] as List<dynamic>? ?? [];
    for (final section in sections) {
      if (section is! Map<String, dynamic>) {
        continue;
      }
      final sectionName = _normalizeSectionLabel(
        section['name']?.toString() ?? section['category']?.toString() ?? '',
      );
      if (!normalizedAliases.contains(sectionName)) {
        continue;
      }

      final items = section['suggestions'] as List<dynamic>? ?? [];
      for (final item in items) {
        if (item is! Map<String, dynamic>) {
          continue;
        }
        final key = '${item['message']}-${item['severity']}';
        if (seen.contains(key)) {
          continue;
        }
        seen.add(key);
        collected.add(item);
      }
    }

    final flat = _feedback?['suggestions'] as List<dynamic>? ?? [];
    for (final item in flat) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final category = _normalizeSectionLabel(item['category']?.toString() ?? '');
      if (!normalizedAliases.contains(category)) {
        continue;
      }
      final key = '${item['message']}-${item['severity']}';
      if (seen.contains(key)) {
        continue;
      }
      seen.add(key);
      collected.add(item);
    }

    return collected;
  }

  Widget _buildSectionAlert({
    required String sectionTitle,
    required List<Map<String, dynamic>> suggestions,
  }) {
    final severity = _sectionSeverity(suggestions);
    final palette = _severityPalette(severity);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette['background'] as Color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette['border'] as Color),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showSectionSuggestions(sectionTitle, suggestions),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                palette['icon'] as IconData,
                size: 18,
                color: palette['text'] as Color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'IA detectó ${suggestions.length} mejora${suggestions.length == 1 ? '' : 's'} en $sectionTitle. Toca para ver.',
                  style: TextStyle(
                    color: palette['text'] as Color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: palette['text'] as Color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSectionSuggestions(String sectionTitle, List<Map<String, dynamic>> suggestions) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.7,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Mejoras IA - $sectionTitle',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: suggestions.length,
                  itemBuilder: (context, index) {
                    final item = suggestions[index];
                    final message = item['message']?.toString() ?? '';
                    final severity = item['severity']?.toString() ?? 'low';
                    final example = item['example']?.toString() ?? '';
                    final palette = _severityPalette(severity);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: palette['background'] as Color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: palette['border'] as Color),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: palette['chip'] as Color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              severity.toUpperCase(),
                              style: TextStyle(
                                color: palette['text'] as Color,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            message,
                            style: const TextStyle(
                              color: Color(0xFF334155),
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                          if (example.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              example,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value, {bool isLink = false}) {
    final canOpenLink = isLink && _tryBuildHttpUri(value) != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: canOpenLink
                ? GestureDetector(
                    onTap: () => _openUrl(value),
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: const TextStyle(
                      color: Color(0xFF263238),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Uri? _tryBuildHttpUri(String raw) {
    final value = raw.trim();
    if (value.isEmpty || value == 'No especificado') {
      return null;
    }
    final parsed = Uri.tryParse(value);
    if (parsed == null) {
      return null;
    }
    if (parsed.scheme == 'http' || parsed.scheme == 'https') {
      return parsed;
    }
    final withHttps = Uri.tryParse('https://$value');
    if (withHttps == null) {
      return null;
    }
    return withHttps;
  }

  Future<void> _openUrl(String raw) async {
    final uri = _tryBuildHttpUri(raw);
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildSettingsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'CONFIGURACION',
              style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          _settingRow(
            icon: Icons.star_rounded,
            label: 'Modo Premium',
            trailing: Switch.adaptive(
              value: _isPremium,
              onChanged: _isUpdatingPremium ? null : _updatePremiumStatus,
              activeTrackColor: const Color(0xFF1A237E),
            ),
          ),

        ],
      ),
    );
  }

  Future<void> _updatePremiumStatus(bool newValue) async {
    final int? userId = widget.userId ?? AuthService.extractUserIdFromJwt(widget.jwt);
    if (userId == null) {
      return;
    }

    setState(() {
      _isUpdatingPremium = true;
    });

    try {
      await _profileApi.updateUserPremiumStatus(
        jwt: widget.jwt,
        userId: userId,
        isPremium: newValue,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isPremium = newValue;
        _isUpdatingPremium = false;
      });

      // Actualizar el UserProvider también
      widget.userProvider.updateUserPremiumStatus(newValue);

      if (newValue) {
        setState(() {
          _feedback = null;
          _feedbackError = null;
          _isLoadingFeedback = true;
        });

        _profileApi.reAnalyzeProfile(
          jwt: widget.jwt,
          userId: userId,
        ).catchError((_) {});

        _loadFeedbackIfPossible();
      } else {
        setState(() {
          _feedback = null;
          _feedbackError = null;
          _isLoadingFeedback = false;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newValue
                ? '¡Bienvenido a Premium! Ya puedes usar análisis IA.'
                : 'Has cambiado a modo Free.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUpdatingPremium = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error actualizando estado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _settingRow({
    required IconData icon,
    required String label,
    Widget? trailing,
    String? value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF5F5F7))),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF1A237E)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF263238), fontSize: 13),
            ),
          ),
          if (trailing != null)
            trailing
          else if (value != null)
            Text(
              value,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            )
          else
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFD1D5DB)),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: widget.onLogout,
        icon: const Icon(Icons.logout_rounded),
        label: const Text(
          'Cerrar sesion',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFFFFF5F5),
          foregroundColor: const Color(0xFFD32F2F),
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  List<Map<String, String>> _buildExperienceItems() {
    final experience = widget.userProvider.currentUser.experience;
    if (experience == null || experience.trim().isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(experience);
      if (decoded is List) {
        return decoded.map((item) {
          final map = item as Map<String, dynamic>;
          final startDate = map['startDate']?.toString() ?? '';
          final endDate = map['endDate']?.toString();
          final period = endDate == null || endDate.isEmpty
              ? '$startDate - Actual'
              : '$startDate - $endDate';
          return {
            'title': map['title']?.toString() ?? 'Experiencia',
            'company': map['company']?.toString() ?? 'Empresa',
            'period': period,
            'color': '7C4DFF',
          };
        }).toList();
      }
    } catch (_) {
      // Use legacy string below.
    }

    return [
      {
        'title': widget.userProvider.currentUser.professionalTitle ?? 'Experiencia profesional',
        'company': widget.userProvider.currentUser.location ?? 'No especificada',
        'period': experience,
        'color': '7C4DFF',
      },
    ];
  }

  List<Map<String, String>> _buildEducationItems() {
    final education = widget.userProvider.currentUser.education;
    if (education == null || education.trim().isEmpty) {
      return [];
    }
    return [
      {
        'degree': education,
        'school': 'Formación registrada',
        'period': 'Actual',
      },
    ];
  }

  Widget _experienceTile(Map<String, String> exp) {
    final color = Color(int.parse('0xFF${exp['color']!}'));
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.work_rounded, size: 14, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exp['title']!,
                  style: const TextStyle(
                    color: Color(0xFF263238),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  exp['company']!,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
                Text(
                  exp['period']!,
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _educationTile(Map<String, String> edu) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.school_rounded,
              size: 14,
              color: Color(0xFF1565C0),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  edu['degree']!,
                  style: const TextStyle(
                    color: Color(0xFF263238),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  edu['school']!,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
                Text(
                  edu['period']!,
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child, Border? border}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: border,
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
