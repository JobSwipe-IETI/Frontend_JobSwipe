import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/user_provider.dart';

class CandidateProfileWidget extends StatefulWidget {
  const CandidateProfileWidget({
    super.key,
    required this.userProvider,
    required this.onLogout,
    required this.onEditProfile,
  });

  final UserProvider userProvider;
  final VoidCallback onLogout;
  final VoidCallback onEditProfile;

  @override
  State<CandidateProfileWidget> createState() => _CandidateProfileWidgetState();
}

class _CandidateProfileWidgetState extends State<CandidateProfileWidget> {
  bool _notificationsOn = true;

  final List<Map<String, String>> _stats = const [
    {'label': 'Vistas', 'value': '0'},
    {'label': 'Postulaciones', 'value': '0'},
    {'label': 'Matches', 'value': '0'},
    {'label': 'Score IA', 'value': '0%'},
  ];

  late List<String> _userSkills;

  @override
  void initState() {
    super.initState();
    _syncSkillsFromProfile();
  }

  @override
  void didUpdateWidget(covariant CandidateProfileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldSkills = oldWidget.userProvider.currentUser.skills;
    final newSkills = widget.userProvider.currentUser.skills;
    if (oldSkills != newSkills) {
      _syncSkillsFromProfile();
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
                    _buildStatsGrid(),
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

  Widget _buildStatsGrid() {
    return GridView.builder(
      itemCount: _stats.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.92,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final stat = _stats[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                stat['value']!,
                style: const TextStyle(
                  color: Color(0xFF263238),
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                stat['label']!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkillsCard() {
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
        ],
      ),
    );
  }

  Widget _buildExperienceCard() {
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
        ],
      ),
    );
  }

  Widget _buildEducationCard() {
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
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoCard() {
    final profile = widget.userProvider.currentUser;
    final salary = profile.expectedSalary != null
        ? 'USD ${profile.expectedSalary!.toStringAsFixed(0)}'
        : 'No especificado';

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
        ],
      ),
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
            icon: Icons.notifications_rounded,
            label: 'Notificaciones',
            trailing: Switch.adaptive(
              value: _notificationsOn,
              onChanged: (v) => setState(() => _notificationsOn = v),
              activeTrackColor: const Color(0xFF1A237E),
            ),
          ),
          _settingRow(icon: Icons.lock_rounded, label: 'Privacidad'),
          _settingRow(
            icon: Icons.language_rounded,
            label: 'Idioma',
            value: 'Espanol',
          ),
          _settingRow(
            icon: Icons.help_center_rounded,
            label: 'Ayuda y soporte',
          ),
        ],
      ),
    );
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
