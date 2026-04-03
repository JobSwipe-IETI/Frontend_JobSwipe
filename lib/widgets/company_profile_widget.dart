import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/user_provider.dart';

class CompanyProfileWidget extends StatefulWidget {
  const CompanyProfileWidget({
    super.key,
    required this.userProvider,
    required this.onLogout,
    required this.onEditProfile,
  });

  final UserProvider userProvider;
  final VoidCallback onLogout;
  final VoidCallback onEditProfile;

  @override
  State<CompanyProfileWidget> createState() => _CompanyProfileWidgetState();
}

class _CompanyProfileWidgetState extends State<CompanyProfileWidget> {
  bool _notificationsOn = true;

  final List<Map<String, String>> _stats = const [
    {'label': 'Vistas', 'value': '0'},
    {'label': 'Vacantes', 'value': '0'},
    {'label': 'Matches', 'value': '0'},
    {'label': 'Score IA', 'value': '0%'},
  ];

  final List<Map<String, String>> _openRoles = const [
    {
      'title': 'Senior Flutter Engineer',
      'subtitle': 'Remoto - Tiempo completo',
      'meta': '32 candidatos',
      'color': '7C4DFF',
    },
    {
      'title': 'Backend Java Developer',
      'subtitle': 'Hibrido - Medellin',
      'meta': '18 candidatos',
      'color': '00B4D8',
    },
    {
      'title': 'Product Designer',
      'subtitle': 'Presencial - Bogota',
      'meta': '11 candidatos',
      'color': '1A237E',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final profile = widget.userProvider.currentUser;
    final displayName = profile.companyName ?? profile.name;

    return Container(
      color: const Color(0xFFF5F5F7),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 96),
        child: Column(
          children: [
            _buildTopHeader(displayName, profile.website),
            Transform.translate(
              offset: const Offset(0, -28),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildStatsGrid(),
                    const SizedBox(height: 12),
                    _buildCompanyDataCard(profile),
                    const SizedBox(height: 12),
                    _buildOpenRolesCard(),
                    const SizedBox(height: 12),
                    _buildSettingsCard(),
                    const SizedBox(height: 12),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(String displayName, String? website) {
    final initials = displayName
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0])
        .join()
        .toUpperCase();

    final websiteText = (website == null || website.isEmpty)
        ? 'www.jobswipe.co'
        : website;

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
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Cuenta Empresa',
                      style: TextStyle(
                        color: Color(0xFFBFDBFE),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 1),
                    GestureDetector(
                      onTap: () => _openUrl(websiteText),
                      child: Text(
                        websiteText,
                        style: const TextStyle(
                          color: Color(0xFF93C5FD),
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                        ),
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

  Widget _buildCompanyDataCard(dynamic profile) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informacion de empresa',
            style: TextStyle(
              color: Color(0xFF263238),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          ..._buildCompanyData(profile).map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      item['label']!,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: _buildDataValue(item['label']!, item['value']!),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 18, color: Color(0xFFE5E7EB)),
          Row(
            children: [
              const Icon(
                Icons.mail_rounded,
                size: 14,
                color: Color(0xFF7C4DFF),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _openEmail(profile.email),
                child: Text(
                  profile.email,
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataValue(String label, String value) {
    final isWebsite = label == 'Sitio web';
    final isEmail = label == 'Email contacto';

    if (isWebsite && _tryBuildHttpUri(value) != null) {
      return GestureDetector(
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
      );
    }

    if (isEmail && _looksLikeEmail(value)) {
      return GestureDetector(
        onTap: () => _openEmail(value),
        child: Text(
          value,
          style: const TextStyle(
            color: Color(0xFF2563EB),
            fontWeight: FontWeight.w700,
            fontSize: 12,
            decoration: TextDecoration.underline,
          ),
        ),
      );
    }

    return Text(
      value,
      style: const TextStyle(
        color: Color(0xFF263238),
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    );
  }

  Widget _buildOpenRolesCard() {
    return _card(
      child: Column(
        children: [
          Row(
            children: const [
              Icon(
                Icons.work_outline_rounded,
                size: 16,
                color: Color(0xFF1A237E),
              ),
              SizedBox(width: 8),
              Text(
                'Vacantes activas',
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
          ..._openRoles.map((role) {
            final color = Color(int.parse('0xFF${role['color']!}'));
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
                          role['title']!,
                          style: const TextStyle(
                            color: Color(0xFF263238),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          role['subtitle']!,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          role['meta']!,
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
          }),
        ],
      ),
    );
  }

  List<Map<String, String>> _buildCompanyData(dynamic profile) {
    return [
      {
        'label': 'Industria',
        'value': profile.industry ?? 'Software / SaaS',
      },
      {
        'label': 'Tamano',
        'value': profile.companySize ?? '120 colaboradores',
      },
      {
        'label': 'Sitio web',
        'value': profile.website ?? 'No especificado',
      },
      {
        'label': 'ID legal',
        'value': profile.legalId ?? 'No especificado',
      },
      {
        'label': 'Sede',
        'value': profile.headquartersLocation ?? 'Bogota, Colombia',
      },
      {
        'label': 'Pais/Nacionalidad',
        'value': profile.nationality ?? 'No especificado',
      },
      {
        'label': 'Descripcion',
        'value': profile.companyDescription ?? 'No especificado',
      },
      {
        'label': 'Contacto',
        'value': profile.hiringContactName ?? 'No especificado',
      },
      {
        'label': 'Email contacto',
        'value': profile.hiringContactEmail ?? 'No especificado',
      },
      {
        'label': 'Telefono',
        'value': profile.phoneNumber ?? 'No especificado',
      },
    ];
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

  Widget _buildActionButtons() {
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

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
      child: child,
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
    return Uri.tryParse('https://$value');
  }

  bool _looksLikeEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
  }

  Future<void> _openUrl(String raw) async {
    final uri = _tryBuildHttpUri(raw);
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openEmail(String email) async {
    final value = email.trim();
    if (!_looksLikeEmail(value)) {
      return;
    }
    final uri = Uri(scheme: 'mailto', path: value);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
