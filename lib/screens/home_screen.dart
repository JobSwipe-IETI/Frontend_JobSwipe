import 'package:flutter/material.dart';
import 'dart:convert';
import '../config/app_config.dart';
import '../config/theme.dart';
import 'create_vacancy_screen.dart';
import 'profile_view_screen.dart';
import 'vacancy_detail_screen.dart';
import '../services/secure_token_storage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late PageController _pageController;
  final SecureTokenStorage _tokenStorage = SecureTokenStorage();
  bool _canCreateVacancy = false;

  Future<void> _showLogoutDialog() async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Cerrar sesión'),
          content: const Text('¿Seguro que deseas cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      widget.onLogout();
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animationController.forward();
    _loadPermissions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              JobSwipeTheme.primaryIndigo.withValues(alpha: 0.04),
              const Color(0xFF1E3A8A).withValues(alpha: 0.02),
              Colors.white,
            ],
            stops: const [0, 0.5, 1],
          ),
        ),
        child: SafeArea(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
                _animationController.forward(from: 0.0);
              });
            },
            children: [
              _buildExplore(),
              _buildMatches(),
              _buildProfile(),
              const CreateVacancySection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildExplore() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('Explora'),
          const SizedBox(height: 24),
          _buildSearchBar(),
          const SizedBox(height: 28),
          _buildSectionTitle('Empleos recomendados'),
          const SizedBox(height: 16),
          ...[1, 2, 3].map((i) => _buildJobCard(i)),
        ],
      ),
    );
  }

  Widget _buildMatches() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('Tus Matches'),
          const SizedBox(height: 24),
          _buildStatsCards(),
          const SizedBox(height: 28),
          _buildSectionTitle('Últimos matches'),
          const SizedBox(height: 16),
          ...[1, 2].map((i) => _buildMatchCard(i)),
        ],
      ),
    );
  }

  Widget _buildProfile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('Perfil'),
          const SizedBox(height: 24),
          _buildProfileSection(),
          const SizedBox(height: 28),
          _buildProfileMenu(),
          const SizedBox(height: 32),
          Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _showLogoutDialog,
                icon: const Icon(
                  Icons.logout_rounded,
                  size: 20,
                ),
                label: const Text(
                  'Cerrar sesión',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6366F1),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFF6366F1),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Activo ahora',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: JobSwipeTheme.primaryIndigo.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Buscar empleos...',
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.grey.shade600,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF6366F1),
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildJobCard(int index) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => VacancyDetailScreen(
              vacancyId: index,
              title: 'Senior Developer',
              company: 'Tech Company Inc.',
              location: 'Madrid, España',
              salary: '\$80,000 - \$120,000',
              matchPercentage: 92.0,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: JobSwipeTheme.primaryIndigo.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      JobSwipeTheme.primaryIndigo.withValues(alpha: 0.1),
                      const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.business_rounded,
                  color: JobSwipeTheme.primaryIndigo,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Senior Developer',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                    Text(
                      'Tech Company Inc.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: JobSwipeTheme.primaryIndigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '92% match',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: JobSwipeTheme.primaryIndigo,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            spacing: 8,
            children: [
              _buildTag('Remoto'),
              _buildTag('\$80k - \$120k'),
              _buildTag('Full-time'),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: JobSwipeTheme.primaryIndigo.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: JobSwipeTheme.primaryIndigo.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: JobSwipeTheme.primaryIndigo,
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      spacing: 12,
      children: [
        Expanded(child: _buildStatCard('Matches', '24', Colors.blue.shade100)),
        Expanded(child: _buildStatCard('Aplicaciones', '8', Colors.green.shade100)),
        Expanded(child: _buildStatCard('Visitantes', '42', Colors.purple.shade100)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Product Manager',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6366F1),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Interesado',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Startup Innovadora - hace 2 horas',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color(0xFFE2E8F0),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Ver detalles',
                    style: TextStyle(
                      color: JobSwipeTheme.primaryIndigo,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: JobSwipeTheme.primaryIndigo,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Responder',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  JobSwipeTheme.primaryIndigo.withValues(alpha: 0.1),
                  const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_rounded,
              size: 40,
              color: JobSwipeTheme.primaryIndigo,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Usuario JobSwipe',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'usuario@example.com',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            spacing: 12,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBFDEF8)),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        '4.8',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                      Text(
                        'Rating',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        '12',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF92400E),
                        ),
                      ),
                      Text(
                        'Entrevistas',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF78350F),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenu() {
    return Column(
      spacing: 10,
      children: [
        _buildMenuOption(
          Icons.person_outline_rounded,
          'Editar Perfil',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProfileViewScreen(onLogout: _showLogoutDialog),
              ),
            );
          },
        ),
        _buildMenuOption(Icons.settings_rounded, 'Configuración'),
        _buildMenuOption(Icons.notifications_none_rounded, 'Notificaciones'),
        _buildMenuOption(Icons.help_outline_rounded, 'Ayuda'),
      ],
    );
  }

  Widget _buildMenuOption(
    IconData icon,
    String label, {
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        leading: Icon(icon, color: JobSwipeTheme.primaryIndigo),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6366F1),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_rounded,
          color: Colors.grey.shade400,
          size: 18,
        ),
        onTap: onTap ?? () {},
      ),
    );
  }

  Widget _buildBottomNav() {
    const tabs = ['Explora', 'Matches', 'Perfil', 'Crear Vacante'];
    const icons = [
      Icons.explore_rounded,
      Icons.favorite_rounded,
      Icons.person_rounded,
      Icons.post_add_rounded,
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
        boxShadow: [
          BoxShadow(
            color: JobSwipeTheme.primaryIndigo.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              tabs.length,
              (index) => _buildNavItem(
                icon: icons[index],
                label: tabs[index],
                isSelected: _selectedIndex == index,
                isEnabled: index != 3 || _canCreateVacancy,
                onTap: () => _onNavTap(index),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : _showCreateVacancyLockedMessage,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Icon(
            icon,
            color: isEnabled
                ? (isSelected ? JobSwipeTheme.primaryIndigo : Colors.grey.shade500)
                : Colors.grey.shade400,
            size: 24,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isEnabled
                  ? (isSelected ? JobSwipeTheme.primaryIndigo : Colors.grey.shade500)
                  : Colors.grey.shade400,
            ),
          ),
          if (isSelected && isEnabled)
            Container(
              width: 24,
              height: 3,
              decoration: BoxDecoration(
                color: JobSwipeTheme.primaryIndigo,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          if (!isEnabled)
            Icon(
              Icons.lock_rounded,
              size: 10,
              color: Colors.grey.shade400,
            ),
        ],
      ),
    );
  }

  void _onNavTap(int index) {
    if (index == 3 && !_canCreateVacancy) {
      _showCreateVacancyLockedMessage();
      return;
    }

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _loadPermissions() async {
    final String? token = await _tokenStorage.readToken();
    if (!mounted) {
      return;
    }

    setState(() {
      _canCreateVacancy =
          AppConfig.allowCreateVacancyForAll || _hasCompanyRole(token);
    });
  }

  bool _hasCompanyRole(String? token) {
    if (token == null || token.isEmpty) {
      return false;
    }

    final List<String> parts = token.split('.');
    if (parts.length != 3) {
      return false;
    }

    try {
      final String normalized = base64Url.normalize(parts[1]);
      final Map<String, dynamic> payload =
          jsonDecode(utf8.decode(base64Url.decode(normalized))) as Map<String, dynamic>;
      final String role = (payload['role'] as String?)?.toUpperCase() ?? '';
      return role == 'COMPANY';
    } catch (_) {
      return false;
    }
  }

  void _showCreateVacancyLockedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Solo usuarios COMPANY pueden crear vacantes.'),
      ),
    );
  }
}

