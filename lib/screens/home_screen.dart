import 'dart:convert';

import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/vacancy_model.dart';
import '../models/user_profile.dart';
import '../widgets/swipe_cards_stack.dart';
import '../controllers/swipe_controller.dart';
import '../controllers/user_provider.dart';
import '../widgets/candidate_profile_widget.dart';
import '../widgets/company_profile_widget.dart';
import 'onboarding_screen.dart';
import 'create_vacancy_screen.dart';
import '../services/auth_service.dart';
import '../services/profile_api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onLogout,
    required this.jwt,
    this.userId,
    this.roleOverride,
    this.profileSeed,
  });

  final VoidCallback onLogout;
  final String jwt;
  final int? userId;
  final String? roleOverride;
  final Map<String, dynamic>? profileSeed;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late PageController _pageController;
  final ProfileApiService _profileApiService = ProfileApiService();
  late UserProvider _userProvider;
  bool get _isCompanyAccount => _userProvider.isCompany;
  bool get _isCandidateAccount => _userProvider.isCandidate;

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
    
    // Decodificar JWT para obtener el rol
    final role = widget.roleOverride ?? AuthService.extractRoleFromJwt(widget.jwt);
    final isCompany = role?.toUpperCase() == 'COMPANY';
    
    // Inicializar UserProvider con el perfil correcto basado en el rol
    _userProvider = UserProvider(
      initialUser: _buildFallbackProfile(isCompany),
    );

    _applyProfileSeed(widget.profileSeed);
    
    _pageController = PageController(initialPage: _selectedIndex);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animationController.forward();
    
    _loadPermissions();
    _loadUserProfile();
  }

  UserProfile _buildFallbackProfile(bool isCompany) {
    return UserProfile(
      id: (widget.userId ?? AuthService.extractUserIdFromJwt(widget.jwt))?.toString() ?? '',
      name: AuthService.extractNameFromJwt(widget.jwt) ?? '',
      email: AuthService.extractEmailFromJwt(widget.jwt) ?? '',
      userType: isCompany ? UserType.company : UserType.candidate,
      professionalTitle: '',
      profileImageUrl: AuthService.extractAvatarUrlFromJwt(widget.jwt) ?? '',
      bannerImageUrl: '',
      description: '',
      phoneNumber: '',
      skills: '',
      experience: '',
      education: '',
      location: '',
      nationality: '',
      languages: '',
      expectedSalary: null,
      availability: '',
      portfolioUrl: '',
      cvUrl: '',
      githubUrl: '',
      linkedinUrl: '',
      companyName: '',
      companyDescription: '',
      legalId: '',
      industry: '',
      companySize: '',
      website: '',
      headquartersLocation: '',
      hiringContactName: '',
      hiringContactEmail: '',
      createdAt: DateTime.now(),
    );
  }

  Future<void> _loadUserProfile() async {
    final int? userId = widget.userId ?? AuthService.extractUserIdFromJwt(widget.jwt);
    if (userId == null) {
      return;
    }

    try {
      final profileJson = await _profileApiService.getProfileByUserId(
        jwt: widget.jwt,
        userId: userId,
      );

      if (profileJson == null || !mounted) {
        return;
      }

      final String? roleClaim = widget.roleOverride ?? AuthService.extractRoleFromJwt(widget.jwt);
      final bool isCompany = roleClaim?.toUpperCase() == 'COMPANY';
      final user = _mapUserProfileFromBackend(profileJson, isCompany);

      setState(() {
        _userProvider.setUser(user);
      });
    } catch (_) {
      // Keep mock data fallback when backend profile cannot be loaded.
    }
  }

  Future<void> _openProfileEditor() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => OnboardingScreen(
          jwt: widget.jwt,
          userId: widget.userId,
          onCompleted: (seed) => Navigator.of(context).pop(seed),
          onLogout: widget.onLogout,
          initialProfile: _userProvider.currentUser,
          isEditing: true,
        ),
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _applyProfileSeed(result);
    });
  }

  void _applyProfileSeed(Map<String, dynamic>? seed) {
    if (seed == null) {
      return;
    }

    final current = _userProvider.currentUser;
    final isCompany = (seed['role']?.toString().toUpperCase() == 'COMPANY') || current.userType == UserType.company;

    final updated = current.copyWith(
      name: seed['displayName']?.toString() ?? seed['name']?.toString() ?? current.name,
      userType: isCompany ? UserType.company : UserType.candidate,
      professionalTitle: seed['professionalTitle']?.toString() ?? current.professionalTitle,
      description: seed['summary']?.toString() ?? seed['companyDescription']?.toString() ?? current.description,
      phoneNumber: seed['phoneNumber']?.toString() ?? current.phoneNumber,
      skills: _encodeSeedData(seed['skills']) ?? current.skills,
      experience: _encodeSeedData(seed['experiences'] ?? seed['experience']) ?? current.experience,
      education: seed['education']?.toString() ?? current.education,
      location: seed['location']?.toString() ?? current.location,
      nationality: seed['nationality']?.toString() ?? current.nationality,
      languages: seed['languages']?.toString() ?? current.languages,
      expectedSalary: (seed['expectedSalary'] as num?)?.toDouble() ?? current.expectedSalary,
      availability: seed['availability']?.toString() ?? current.availability,
      portfolioUrl: seed['portfolioUrl']?.toString() ?? current.portfolioUrl,
      cvUrl: seed['cvUrl']?.toString() ?? current.cvUrl,
      githubUrl: seed['githubUrl']?.toString() ?? current.githubUrl,
      linkedinUrl: seed['linkedinUrl']?.toString() ?? current.linkedinUrl,
      companyName: seed['companyName']?.toString() ?? current.companyName,
      companyDescription: seed['companyDescription']?.toString() ?? current.companyDescription,
      legalId: seed['legalId']?.toString() ?? current.legalId,
      industry: seed['sector']?.toString() ?? seed['industry']?.toString() ?? current.industry,
      companySize: seed['companySize']?.toString() ?? current.companySize,
      website: seed['website']?.toString() ?? current.website,
      headquartersLocation: seed['headquartersLocation']?.toString() ?? current.headquartersLocation,
      hiringContactName: seed['hiringContactName']?.toString() ?? current.hiringContactName,
      hiringContactEmail: seed['hiringContactEmail']?.toString() ?? current.hiringContactEmail,
    );

    _userProvider.setUser(updated);
  }

  String? _encodeSeedData(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is String) {
      return value;
    }

    return jsonEncode(value);
  }

  UserProfile _mapUserProfileFromBackend(Map<String, dynamic> json, bool isCompany) {
    final String name = AuthService.extractNameFromJwt(widget.jwt) ?? _userProvider.currentUser.name;
    final String email = AuthService.extractEmailFromJwt(widget.jwt) ?? _userProvider.currentUser.email;
    final String avatarUrl = AuthService.extractAvatarUrlFromJwt(widget.jwt) ?? _userProvider.currentUser.profileImageUrl;

    final Map<String, dynamic>? candidate = json['candidateProfile'] as Map<String, dynamic>?;
    final Map<String, dynamic>? company = json['companyProfile'] as Map<String, dynamic>?;

    return UserProfile(
      id: (widget.userId ?? AuthService.extractUserIdFromJwt(widget.jwt))?.toString() ?? _userProvider.currentUser.id,
      name: name,
      email: email,
      userType: isCompany ? UserType.company : UserType.candidate,
      professionalTitle: json['professionalTitle']?.toString(),
      profileImageUrl: avatarUrl,
      bannerImageUrl: _userProvider.currentUser.bannerImageUrl,
      description: json['summary']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString(),
      skills: json['skills']?.toString(),
      experience: json['experience']?.toString(),
      education: json['education']?.toString(),
      location: json['location']?.toString(),
      nationality: json['nationality']?.toString(),
      languages: candidate?['languages']?.toString(),
      expectedSalary: (candidate?['expectedSalary'] as num?)?.toDouble(),
      availability: candidate?['availability']?.toString(),
      portfolioUrl: candidate?['portfolioUrl']?.toString(),
      cvUrl: candidate?['cvUrl']?.toString(),
      githubUrl: candidate?['githubUrl']?.toString(),
      linkedinUrl: candidate?['linkedinUrl']?.toString(),
      companyName: company?['companyName']?.toString(),
      companyDescription: company?['companyDescription']?.toString(),
      legalId: company?['legalId']?.toString(),
      industry: candidate?['sector']?.toString() ?? company?['industry']?.toString(),
      companySize: company?['companySize']?.toString(),
      website: company?['website']?.toString(),
      headquartersLocation: company?['headquartersLocation']?.toString(),
      hiringContactName: company?['hiringContactName']?.toString(),
      hiringContactEmail: company?['hiringContactEmail']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
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
            children: _buildPageViewChildren(),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  List<Widget> _buildPageViewChildren() {
    final pages = [
      _buildExplore(),
      _buildMatches(),
      _buildProfile(),
    ];
    
    if (_isCompanyAccount) {
      pages.add(const CreateVacancySection());
    }
    
    return pages;
  }

  Widget _buildExplore() {
    // Datos de muestra
    final List<VacancyModel> sampleVacancies = [
      VacancyModel(
        id: 1,
        title: 'Senior Frontend Developer',
        company: 'Google',
        location: 'Remoto',
        salary: '\$120k - \$150k USD',
        matchPercentage: 92,
        badge: 'Mockup',
        description:
            'Buscamos un Senior Frontend Developer con experiencia en React y TypeScript. Trabajarás en productos que impactan a millones de usuarios.',
        logo: Icons.business_rounded.toString(),
      ),
      VacancyModel(
        id: 2,
        title: 'Product Manager',
        company: 'Meta',
        location: '100% Remoto',
        salary: '\$130k - \$180k USD',
        matchPercentage: 88,
        badge: 'Open',
        description:
            'Únete a nuestro equipo de Ingeniería de Meta para construir interfaces de próxima generación usando React y TypeScript. Trabajarás en productos que impactan a millones.',
        logo: Icons.business_rounded.toString(),
      ),
      VacancyModel(
        id: 3,
        title: 'Full Stack Engineer',
        company: 'Amazon',
        location: 'Remoto',
        salary: '\$100k - \$140k USD',
        matchPercentage: 85,
        badge: 'New',
        description:
            'Se requiere experiencia en backend con Node.js/Python y frontend con React. Trabajarás en sistemas distribuidos de alta escala.',
        logo: Icons.business_rounded.toString(),
      ),
      VacancyModel(
        id: 4,
        title: 'DevOps Engineer',
        company: 'Netflix',
        location: 'Remoto',
        salary: '\$110k - \$160k USD',
        matchPercentage: 81,
        badge: 'Hot',
        description:
            'Buscamos un DevOps Engineer experto en Kubernetes, Docker y AWS. Serás responsable de la infraestructura de millones de usuarios.',
        logo: Icons.business_rounded.toString(),
      ),
      VacancyModel(
        id: 5,
        title: 'Data Scientist',
        company: 'OpenAI',
        location: 'San Francisco, USA',
        salary: '\$140k - \$200k USD',
        matchPercentage: 87,
        badge: 'Premium',
        description:
            'Trabaja con modelos de IA de última generación. Necesitamos expertos en machine learning con experiencia en producción.',
        logo: Icons.business_rounded.toString(),
      ),
    ];

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader('Explora'),
            ],
          ),
        ),
        // Card Deck
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
            child: SwipeCardsStack(
              vacancies: sampleVacancies,
              onCardSwiped: (vacancy, result) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result == SwipeResult.like
                          ? '❤️ ${vacancy.title} guardado'
                          : '✋ ${vacancy.title} rechazado',
                    ),
                    duration: const Duration(milliseconds: 1200),
                  ),
                );
              },
              onStackEmpty: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No hay más vacantes disponibles 🎉'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        ),
      ],
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
    return _isCandidateAccount
        ? CandidateProfileWidget(
            userProvider: _userProvider,
            onLogout: _showLogoutDialog,
            onEditProfile: _openProfileEditor,
          )
        : CompanyProfileWidget(
            userProvider: _userProvider,
            onLogout: _showLogoutDialog,
            onEditProfile: _openProfileEditor,
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

  Widget _buildBottomNav() {
    // Construir tabs dinámicamente según el tipo de usuario
    final tabs = _isCompanyAccount
        ? const ['Explora', 'Matches', 'Perfil', 'Crear Vacante']
        : const ['Explora', 'Matches', 'Perfil'];
    
    final icons = _isCompanyAccount
        ? const [
            Icons.explore_rounded,
            Icons.favorite_rounded,
            Icons.person_rounded,
            Icons.post_add_rounded,
          ]
        : const [
            Icons.explore_rounded,
            Icons.favorite_rounded,
            Icons.person_rounded,
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
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Icon(
            icon,
            color: isSelected ? JobSwipeTheme.primaryIndigo : Colors.grey.shade500,
            size: 24,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSelected ? JobSwipeTheme.primaryIndigo : Colors.grey.shade500,
            ),
          ),
          if (isSelected)
            Container(
              width: 24,
              height: 3,
              decoration: BoxDecoration(
                color: JobSwipeTheme.primaryIndigo,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }

  void _onNavTap(int index) {
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
    // Ya no se necesita cargar permisos especiales
    // El tipo de usuario se obtiene del UserProvider
  }
}

