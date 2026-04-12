import 'package:flutter/material.dart';

import '../controllers/user_provider.dart';

class CandidateProfileWidget extends StatefulWidget {
  const CandidateProfileWidget({
    super.key,
    required this.userProvider,
    required this.onLogout,
  });

  final UserProvider userProvider;
  final VoidCallback onLogout;

  @override
  State<CandidateProfileWidget> createState() => _CandidateProfileWidgetState();
}

class _CandidateProfileWidgetState extends State<CandidateProfileWidget> {
  bool _notificationsOn = true;
  bool _editSkills = false;

  static const List<String> _defaultSkills = [
    'React',
    'TypeScript',
    'Node.js',
    'GraphQL',
    'CSS/Tailwind',
    'Figma',
    'Docker',
    'Git',
    'AWS',
    'Python',
  ];

  final List<Map<String, String>> _experiences = const [
    {
      'title': 'Senior Developer',
      'company': 'StartupCo',
      'period': '2022 - Presente',
      'color': '7C4DFF',
    },
    {
      'title': 'Frontend Developer',
      'company': 'TechAgency',
      'period': '2020 - 2022',
      'color': '00B4D8',
    },
    {
      'title': 'Junior Developer',
      'company': 'WebStudio',
      'period': '2018 - 2020',
      'color': '1A237E',
    },
  ];

  final List<Map<String, String>> _education = const [
    {
      'degree': 'Ing. en Sistemas',
      'school': 'Universidad Nacional',
      'period': '2014 - 2018',
    },
    {
      'degree': 'Bootcamp FullStack',
      'school': 'Platzi Master',
      'period': '2019',
    },
  ];

  final List<Map<String, String>> _stats = const [
    {'label': 'Vistas', 'value': '148'},
    {'label': 'Postulaciones', 'value': '23'},
    {'label': 'Matches', 'value': '8'},
    {'label': 'Score IA', 'value': '88%'},
  ];

  late final List<String> _userSkills = List<String>.from(_defaultSkills);

  void _removeSkill(String skill) {
    setState(() {
      _userSkills.remove(skill);
    });
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
              Container(
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
                    const Text(
                      'Senior Frontend Developer',
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
            children: const [
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
                '78%',
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
                tween: Tween<double>(begin: 0, end: 0.78),
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
          const Text(
            'Agrega tu experiencia laboral para llegar al 100%',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
          ),
        ],
      ),
    );
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
          Row(
            children: [
              const Text(
                'Habilidades',
                style: TextStyle(
                  color: Color(0xFF263238),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _editSkills = !_editSkills),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF7C4DFF),
                ),
                child: Text(_editSkills ? 'Listo' : 'Editar'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ..._userSkills.map((skill) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0EEFF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          skill,
                          style: const TextStyle(
                            color: Color(0xFF7C4DFF),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_editSkills)
                          GestureDetector(
                            onTap: () => _removeSkill(skill),
                            child: const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Text(
                                '×',
                                style: TextStyle(
                                  color: Color(0xFF7C4DFF),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
                if (_editSkills)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF7C4DFF),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_rounded,
                          size: 13,
                          color: Color(0xFF7C4DFF),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Agregar',
                          style: TextStyle(
                            color: Color(0xFF7C4DFF),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
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
              Spacer(),
              Icon(Icons.add_rounded, color: Color(0xFF7C4DFF), size: 18),
            ],
          ),
          const SizedBox(height: 12),
          ..._experiences.map(_experienceTile),
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
              Spacer(),
              Icon(Icons.add_rounded, color: Color(0xFF7C4DFF), size: 18),
            ],
          ),
          const SizedBox(height: 12),
          ..._education.map(_educationTile),
        ],
      ),
    );
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
              activeColor: const Color(0xFF1A237E),
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
