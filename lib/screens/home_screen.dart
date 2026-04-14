import 'dart:async';
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
import 'employer_vacancies_tab_screen.dart';
import '../services/auth_service.dart';
import '../services/profile_api_service.dart';
import '../services/vacancy_service.dart';

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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late PageController _pageController;
  final ProfileApiService _profileApiService = ProfileApiService();
  final VacancyService _vacancyService = VacancyService();
  late UserProvider _userProvider;
  List<VacancyModel> _exploreVacancies = const [];
  bool _isLoadingExplore = false;
  String? _exploreError;
  bool _showingFallbackVacancies = false;
  bool _isLoadingCompanyDashboard = false;
  String? _companyDashboardError;
  List<VacancyModel> _companyVacancies = const [];
  List<CompanyVacancyPipelineItem> _companyVacancyPipeline = const [];
  List<CompanyLikeActivity> _companyLikeActivity = const [];
  final Map<int, List<VacancyApplicant>> _applicantsCache =
      <int, List<VacancyApplicant>>{};
  final Map<int, Future<List<VacancyApplicant>>> _applicantsInFlight =
      <int, Future<List<VacancyApplicant>>>{};
  int _exploreLoadingStep = 0;
  int _exploreProgressPercent = 0;
  String? _exploreBackendMessage;
  Timer? _exploreLoadingTicker;
  static const List<String> _exploreLoadingMessages = <String>[
    'Cargando vacantes...',
    'Organizando la informacion del perfil...',
    'Buscando coincidencias para ti...',
  ];
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
    final role =
        widget.roleOverride ?? AuthService.extractRoleFromJwt(widget.jwt);
    final isCompany = role?.toUpperCase() == 'COMPANY';

    // Inicializar UserProvider con el perfil correcto basado en el rol
    _userProvider = UserProvider(initialUser: _buildFallbackProfile(isCompany));

    _applyProfileSeed(widget.profileSeed);

    _pageController = PageController(initialPage: _selectedIndex);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animationController.forward();

    _loadPermissions();
    _loadUserProfile();
    if (_isCandidateAccount) {
      _loadRecommendedVacancies();
    }
    if (_isCompanyAccount) {
      _loadCompanyDashboard();
    }
  }

  UserProfile _buildFallbackProfile(bool isCompany) {
    return UserProfile(
      id:
          (widget.userId ?? AuthService.extractUserIdFromJwt(widget.jwt))
              ?.toString() ??
          '',
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
    final int? userId =
        widget.userId ?? AuthService.extractUserIdFromJwt(widget.jwt);
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

      final String? roleClaim =
          widget.roleOverride ?? AuthService.extractRoleFromJwt(widget.jwt);
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
    final isCompany =
        (seed['role']?.toString().toUpperCase() == 'COMPANY') ||
        current.userType == UserType.company;

    final updated = current.copyWith(
      name:
          seed['displayName']?.toString() ??
          seed['name']?.toString() ??
          current.name,
      userType: isCompany ? UserType.company : UserType.candidate,
      professionalTitle:
          seed['professionalTitle']?.toString() ?? current.professionalTitle,
      description:
          seed['summary']?.toString() ??
          seed['companyDescription']?.toString() ??
          current.description,
      phoneNumber: seed['phoneNumber']?.toString() ?? current.phoneNumber,
      skills: _encodeSeedData(seed['skills']) ?? current.skills,
      experience:
          _encodeSeedData(seed['experiences'] ?? seed['experience']) ??
          current.experience,
      education: seed['education']?.toString() ?? current.education,
      location: seed['location']?.toString() ?? current.location,
      nationality: seed['nationality']?.toString() ?? current.nationality,
      languages: seed['languages']?.toString() ?? current.languages,
      expectedSalary:
          (seed['expectedSalary'] as num?)?.toDouble() ??
          current.expectedSalary,
      availability: seed['availability']?.toString() ?? current.availability,
      portfolioUrl: seed['portfolioUrl']?.toString() ?? current.portfolioUrl,
      cvUrl: seed['cvUrl']?.toString() ?? current.cvUrl,
      githubUrl: seed['githubUrl']?.toString() ?? current.githubUrl,
      linkedinUrl: seed['linkedinUrl']?.toString() ?? current.linkedinUrl,
      companyName: seed['companyName']?.toString() ?? current.companyName,
      companyDescription:
          seed['companyDescription']?.toString() ?? current.companyDescription,
      legalId: seed['legalId']?.toString() ?? current.legalId,
      industry:
          seed['sector']?.toString() ??
          seed['industry']?.toString() ??
          current.industry,
      companySize: seed['companySize']?.toString() ?? current.companySize,
      website: seed['website']?.toString() ?? current.website,
      headquartersLocation:
          seed['headquartersLocation']?.toString() ??
          current.headquartersLocation,
      hiringContactName:
          seed['hiringContactName']?.toString() ?? current.hiringContactName,
      hiringContactEmail:
          seed['hiringContactEmail']?.toString() ?? current.hiringContactEmail,
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

  UserProfile _mapUserProfileFromBackend(
    Map<String, dynamic> json,
    bool isCompany,
  ) {
    final Map<String, dynamic>? candidate =
        json['candidateProfile'] as Map<String, dynamic>?;
    final Map<String, dynamic>? company =
        json['companyProfile'] as Map<String, dynamic>?;

    final String name =
        candidate?['displayName']?.toString() ??
        candidate?['fullName']?.toString() ??
        candidate?['name']?.toString() ??
        company?['companyName']?.toString() ??
        company?['name']?.toString() ??
        json['displayName']?.toString() ??
        json['fullName']?.toString() ??
        json['name']?.toString() ??
        _userProvider.currentUser.name;
    final String email =
        AuthService.extractEmailFromJwt(widget.jwt) ??
        _userProvider.currentUser.email;
    final String avatarUrl =
        AuthService.extractAvatarUrlFromJwt(widget.jwt) ??
        _userProvider.currentUser.profileImageUrl;

    return UserProfile(
      id:
          (widget.userId ?? AuthService.extractUserIdFromJwt(widget.jwt))
              ?.toString() ??
          _userProvider.currentUser.id,
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
      industry:
          candidate?['sector']?.toString() ?? company?['industry']?.toString(),
      companySize: company?['companySize']?.toString(),
      website: company?['website']?.toString(),
      headquartersLocation: company?['headquartersLocation']?.toString(),
      hiringContactName: company?['hiringContactName']?.toString(),
      hiringContactEmail: company?['hiringContactEmail']?.toString(),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  @override
  void dispose() {
    _exploreLoadingTicker?.cancel();
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
    final pages = [_buildExplore(), _buildMatches(), _buildProfile()];

    if (_isCompanyAccount) {
      pages.add(
        EmployerVacanciesTabScreen(
          userProvider: _userProvider,
          jwt: widget.jwt,
        ),
      );
    }

    return pages;
  }

  Widget _buildExplore() {
    final String sectionTitle = _isCompanyAccount ? 'Actividad' : 'Explora';

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_buildHeader(sectionTitle)],
          ),
        ),
        // Card Deck
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
            child: _buildExploreBody(),
          ),
        ),
      ],
    );
  }

  Widget _buildExploreBody() {
    if (_isCompanyAccount) {
      return _buildCompanyExploreState();
    }

    if (_exploreVacancies.isNotEmpty) {
      return SwipeCardsStack(
        vacancies: _exploreVacancies,
        onCardSwiped: (vacancy, result) {
          setState(() {
            _exploreVacancies = _exploreVacancies
                .where((item) => item.id != vacancy.id)
                .toList(growable: false);
          });

          final SwipeDecision decision = result == SwipeResult.like
              ? SwipeDecision.like
              : SwipeDecision.dislike;
          unawaited(
            _vacancyService
                .registerSwipeDecision(
                  jwt: widget.jwt,
                  vacancyId: vacancy.id,
                  decision: decision,
                )
                .catchError((_) {
                  // Keep UX smooth if swipe persistence fails transiently.
                }),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result == SwipeResult.like
                    ? '❤️ ${vacancy.title} guardado'
                    : '✋ ${vacancy.title} rechazado',
              ),
              duration: const Duration(milliseconds: 900),
            ),
          );
        },
        onStackEmpty: _handleExploreStackEmpty,
      );
    }

    if (_isLoadingExplore) {
      return _buildExploreLoadingState();
    }

    if (_exploreError != null) {
      return _buildExploreErrorState();
    }

    return _buildExploreEmptyState();
  }

  Widget _buildCompanyExploreState() {
    if (_isLoadingCompanyDashboard) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: JobSwipeTheme.primaryIndigo.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: 14),
              const Text(
                'Cargando actividad de vacantes...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Estamos reuniendo tus vacantes, postulados y likes.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    if (_companyDashboardError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              _companyDashboardError!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCompanyDashboard,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final int vacanciesCount = _companyVacancies.length;
    final int likesCount = _companyLikeActivity.length;
    final int uniqueCandidates = _companyLikeActivity
        .map((item) => item.candidateId)
        .toSet()
        .length;

    return RefreshIndicator(
      onRefresh: _loadCompanyDashboard,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          Row(
            children: [
              Expanded(
                child: _buildCompanyStatCard(
                  label: 'Vacantes actuales',
                  value: '$vacanciesCount',
                  icon: Icons.work_outline_rounded,
                  color: const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCompanyStatCard(
                  label: 'Likes recibidos',
                  value: '$likesCount',
                  icon: Icons.favorite_rounded,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildCompanyStatCard(
            label: 'Usuarios postulados',
            value: '$uniqueCandidates',
            icon: Icons.people_alt_outlined,
            color: const Color(0xFF1E3A8A),
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('Pipeline por vacante'),
          const SizedBox(height: 10),
          if (_companyVacancyPipeline.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Text(
                'No hay postulaciones todavía en tus vacantes.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            ..._companyVacancyPipeline
                .map(_buildCompanyVacancyPipelineCard)
                .toList(growable: false),
          const SizedBox(height: 20),
          _buildSectionTitle('Notificaciones de interés'),
          const SizedBox(height: 10),
          if (_companyLikeActivity.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Text(
                'Aún no tienes likes en tus vacantes. Cuando lleguen, te aparecerán aquí.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            ..._companyLikeActivity
                .map(_buildCompanyActivityItem)
                .toList(growable: false),
        ],
      ),
    );
  }

  Widget _buildCompanyVacancyPipelineCard(CompanyVacancyPipelineItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.work_outline_rounded,
              color: Color(0xFF6366F1),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.vacancyTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.applicantsCount} postulados',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => _openApplicantsForVacancy(item),
            icon: const Icon(Icons.chevron_right_rounded, size: 16),
            label: const Text('Ver'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyActivityItem(CompanyLikeActivity activity) {
    final String when = _formatRelativeTime(activity.likedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFF10B981),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${activity.candidateName} dio like a ${activity.vacancyTitle}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            when,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Pronto podrás evaluar candidatos desde aquí.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.thumb_up_alt_outlined, size: 16),
                label: const Text('Like'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Pronto podrás evaluar candidatos desde aquí.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.thumb_down_alt_outlined, size: 16),
                label: const Text('Dislike'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime? value) {
    if (value == null) {
      return 'Hace un momento';
    }

    final Duration diff = DateTime.now().difference(value.toLocal());
    if (diff.inMinutes < 1) {
      return 'Hace unos segundos';
    }
    if (diff.inHours < 1) {
      return 'Hace ${diff.inMinutes} min';
    }
    if (diff.inDays < 1) {
      return 'Hace ${diff.inHours} h';
    }
    return 'Hace ${diff.inDays} días';
  }

  Future<void> _loadCompanyDashboard() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoadingCompanyDashboard = true;
      _companyDashboardError = null;
    });

    final List<String> errors = <String>[];
    Future<T> safeLoad<T>(Future<T> future, T fallback) async {
      try {
        return await future;
      } catch (error) {
        errors.add(error.toString());
        return fallback;
      }
    }

    final Future<List<VacancyModel>> vacanciesFuture = safeLoad(
      _vacancyService.getCompanyVacancies(jwt: widget.jwt),
      _companyVacancies,
    );
    final Future<List<CompanyVacancyPipelineItem>> pipelineFuture = safeLoad(
      _vacancyService.getCompanyVacancyPipeline(jwt: widget.jwt),
      _companyVacancyPipeline,
    );
    final Future<List<CompanyLikeActivity>> activityFuture = safeLoad(
      _vacancyService.getCompanyLikeActivity(jwt: widget.jwt, limit: 20),
      _companyLikeActivity,
    );

    final List<dynamic> results = await Future.wait<dynamic>([
      vacanciesFuture,
      pipelineFuture,
      activityFuture,
    ]);

    final List<VacancyModel> vacancies = results[0] as List<VacancyModel>;
    final List<CompanyVacancyPipelineItem> pipeline =
        results[1] as List<CompanyVacancyPipelineItem>;
    final List<CompanyLikeActivity> activity =
        results[2] as List<CompanyLikeActivity>;

    if (!mounted) {
      return;
    }

    setState(() {
      _companyVacancies = vacancies;
      _companyVacancyPipeline = pipeline;
      _companyLikeActivity = activity;
      _companyDashboardError = errors.length == 3
          ? 'No se pudo cargar el panel en este momento. Intenta de nuevo.'
          : null;
      _isLoadingCompanyDashboard = false;
    });
  }

  Future<List<VacancyApplicant>> _loadApplicantsForVacancy(
    int vacancyId, {
    bool forceRefresh = false,
  }) {
    if (!forceRefresh) {
      final List<VacancyApplicant>? cached = _applicantsCache[vacancyId];
      if (cached != null) {
        return Future.value(cached);
      }

      final Future<List<VacancyApplicant>>? inFlight =
          _applicantsInFlight[vacancyId];
      if (inFlight != null) {
        return inFlight;
      }
    } else {
      _applicantsCache.remove(vacancyId);
      _applicantsInFlight.remove(vacancyId);
    }

    final Future<List<VacancyApplicant>> future = _vacancyService
        .getVacancyApplicants(jwt: widget.jwt, vacancyId: vacancyId, limit: 50)
        .then((applicants) {
          _applicantsCache[vacancyId] = applicants;
          return applicants;
        });

    _applicantsInFlight[vacancyId] = future;
    future.whenComplete(() {
      if (_applicantsInFlight[vacancyId] == future) {
        _applicantsInFlight.remove(vacancyId);
      }
    });

    return future;
  }

  Widget _buildApplicantsStatusCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    Widget? action,
  }) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: JobSwipeTheme.primaryIndigo.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            if (action != null) ...[const SizedBox(height: 16), action],
          ],
        ),
      ),
    );
  }

  Widget _buildApplicantsLoadingState(String vacancyTitle) {
    return _buildApplicantsStatusCard(
      icon: Icons.groups_rounded,
      iconColor: JobSwipeTheme.primaryIndigo,
      title: 'Cargando postulados',
      description:
          'Estamos trayendo compatibilidad, score IA y fecha de postulación para "$vacancyTitle".',
    );
  }

  Widget _buildApplicantsErrorState({
    required String message,
    required VoidCallback onRetry,
  }) {
    return _buildApplicantsStatusCard(
      icon: Icons.error_outline_rounded,
      iconColor: JobSwipeTheme.errorRed,
      title: 'No se pudieron cargar los postulados',
      description: message,
      action: OutlinedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded, size: 16),
        label: const Text('Reintentar'),
      ),
    );
  }

  Widget _buildApplicantsContent({
    required CompanyVacancyPipelineItem item,
    required List<VacancyApplicant> applicants,
    required VoidCallback onRefresh,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.vacancyTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${applicants.length} postulados',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Actualizar'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: applicants.isEmpty
              ? _buildApplicantsStatusCard(
                  icon: Icons.person_search_rounded,
                  iconColor: JobSwipeTheme.primaryIndigo,
                  title: 'Aún no hay postulados',
                  description:
                      'Cuando lleguen candidaturas para esta vacante, aparecerán aquí con su score y resumen IA.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: applicants.length,
                  itemBuilder: (context, index) {
                    final applicant = applicants[index];
                    final String compatibilityText =
                        applicant.compatibilityPercentage == null
                        ? 'Sin score'
                        : '${applicant.compatibilityPercentage!.toStringAsFixed(1)}%';
                    final String feedback =
                        (applicant.feedback != null &&
                            applicant.feedback!.isNotEmpty)
                        ? applicant.feedback!
                        : 'Sin resumen IA disponible para este perfil.';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            applicant.candidateName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF6366F1,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  compatibilityText,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF6366F1),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatRelativeTime(applicant.appliedAt),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            feedback,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Falta habilitar endpoint de decisión de empresa para guardar este like.',
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.thumb_up_alt_outlined,
                                  size: 16,
                                ),
                                label: const Text('Like'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Falta habilitar endpoint de decisión de empresa para guardar este dislike.',
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.thumb_down_alt_outlined,
                                  size: 16,
                                ),
                                label: const Text('Dislike'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _openApplicantsForVacancy(
    CompanyVacancyPipelineItem item,
  ) async {
    List<VacancyApplicant>? cachedApplicants = _applicantsCache[item.vacancyId];
    Future<List<VacancyApplicant>>? applicantsFuture;
    if (cachedApplicants == null) {
      applicantsFuture = _loadApplicantsForVacancy(item.vacancyId);
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.78,
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: cachedApplicants != null
                  ? _buildApplicantsContent(
                      item: item,
                      applicants: cachedApplicants!,
                      onRefresh: () {
                        setModalState(() {
                          cachedApplicants = null;
                          applicantsFuture = _loadApplicantsForVacancy(
                            item.vacancyId,
                            forceRefresh: true,
                          );
                        });
                      },
                    )
                  : FutureBuilder<List<VacancyApplicant>>(
                      future: applicantsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return _buildApplicantsLoadingState(
                            item.vacancyTitle,
                          );
                        }

                        if (snapshot.hasError) {
                          return _buildApplicantsErrorState(
                            message:
                                'No se pudo cargar postulados: ${snapshot.error}',
                            onRetry: () {
                              setModalState(() {
                                applicantsFuture = _loadApplicantsForVacancy(
                                  item.vacancyId,
                                  forceRefresh: true,
                                );
                              });
                            },
                          );
                        }

                        final List<VacancyApplicant> applicants =
                            snapshot.data ?? const <VacancyApplicant>[];
                        cachedApplicants = applicants;

                        return _buildApplicantsContent(
                          item: item,
                          applicants: applicants,
                          onRefresh: () {
                            setModalState(() {
                              cachedApplicants = null;
                              applicantsFuture = _loadApplicantsForVacancy(
                                item.vacancyId,
                                forceRefresh: true,
                              );
                            });
                          },
                        );
                      },
                    ),
            );
          },
        );
      },
    );
  }

  Widget _buildExploreErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 56,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            _exploreError ?? 'No se pudieron cargar las vacantes.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadRecommendedVacancies,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreLoadingState() {
    final String loadingMessage =
        (_exploreBackendMessage != null && _exploreBackendMessage!.isNotEmpty)
        ? _exploreBackendMessage!
        : _exploreLoadingMessages[_exploreLoadingStep %
              _exploreLoadingMessages.length];
    final double progressValue = (_exploreProgressPercent.clamp(0, 100)) / 100;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: JobSwipeTheme.primaryIndigo.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              size: 42,
              color: Color(0xFF6366F1),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: 240,
              child: LinearProgressIndicator(
                value: progressValue > 0 ? progressValue : null,
                minHeight: 8,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: Text(
                loadingMessage,
                key: ValueKey<String>(loadingMessage),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF334155),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _exploreProgressPercent > 0
                  ? '$_exploreProgressPercent% completado'
                  : 'Cargando vacantes para ti...',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enseguida te mostramos las mejores coincidencias, sin bloquear la pantalla.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  void _startExploreLoadingMessages() {
    _exploreLoadingTicker?.cancel();
    _exploreLoadingStep = 0;
    _exploreProgressPercent = 0;
    _exploreBackendMessage = null;
    _exploreLoadingTicker = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted || !_isLoadingExplore) {
        return;
      }
      setState(() {
        _exploreLoadingStep =
            (_exploreLoadingStep + 1) % _exploreLoadingMessages.length;
      });
    });
  }

  void _stopExploreLoadingMessages() {
    _exploreLoadingTicker?.cancel();
    _exploreLoadingTicker = null;
    _exploreLoadingStep = 0;
    _exploreProgressPercent = 0;
    _exploreBackendMessage = null;
  }

  Widget _buildExploreEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 56,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            _showingFallbackVacancies
                ? 'No hay más vacantes por ahora.'
                : 'No hay recomendaciones disponibles todavía.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15),
          ),
        ],
      ),
    );
  }

  Future<void> _loadRecommendedVacancies() async {
    if (!_isCandidateAccount) {
      return;
    }

    setState(() {
      _isLoadingExplore = true;
      _exploreError = null;
    });
    _startExploreLoadingMessages();

    try {
      final String jobId = await _vacancyService.startRecommendedVacanciesJob(
        jwt: widget.jwt,
        minScore: 70,
        limit: 20,
      );

      final Set<int> streamedRecommendationIds = _exploreVacancies
          .map((item) => item.id)
          .toSet();
      int partialOffset = 0;

      void appendPartialItems(List<VacancyModel> items) {
        if (items.isEmpty || !mounted) {
          return;
        }

        bool changed = false;
        final List<VacancyModel> updated = List<VacancyModel>.from(
          _exploreVacancies,
        );

        for (final VacancyModel item in items) {
          if (streamedRecommendationIds.add(item.id)) {
            updated.add(item);
            changed = true;
          }
        }

        if (!changed) {
          return;
        }

        setState(() {
          _exploreVacancies = updated;
          _showingFallbackVacancies = false;
        });
      }

      RecommendationJobStatus? status;
      for (int i = 0; i < 150; i++) {
        status = await _vacancyService.getRecommendedVacanciesJobStatus(
          jwt: widget.jwt,
          jobId: jobId,
        );

        final RecommendationJobPartial partial = await _vacancyService
            .getRecommendedVacanciesJobPartial(
              jwt: widget.jwt,
              jobId: jobId,
              offset: partialOffset,
              limit: 6,
            );
        partialOffset = partial.nextOffset;
        appendPartialItems(partial.items);

        if (mounted) {
          setState(() {
            _exploreProgressPercent = status!.progressPercent;
            _exploreBackendMessage = status.message;
          });
        }

        if (status.isCompleted) {
          break;
        }

        if (status.isFailed) {
          throw VacancyException(
            (status.error != null && status.error!.isNotEmpty)
                ? status.error!
                : 'No se pudieron generar recomendaciones.',
          );
        }

        await Future.delayed(const Duration(milliseconds: 1200));
      }

      for (int i = 0; i < 6; i++) {
        final RecommendationJobPartial trailing = await _vacancyService
            .getRecommendedVacanciesJobPartial(
              jwt: widget.jwt,
              jobId: jobId,
              offset: partialOffset,
              limit: 20,
            );

        if (trailing.nextOffset == partialOffset) {
          break;
        }

        partialOffset = trailing.nextOffset;
        appendPartialItems(trailing.items);
      }

      if (status == null ||
          (!status.isCompleted && _exploreVacancies.isEmpty)) {
        throw const VacancyException(
          'Las recomendaciones estan tardando mas de lo esperado. Intenta nuevamente.',
        );
      }

      if (!mounted) {
        return;
      }

      if (_exploreVacancies.isEmpty) {
        setState(() {
          _showingFallbackVacancies = true;
          _isLoadingExplore = false;
        });
        _stopExploreLoadingMessages();
        return;
      }

      setState(() {
        _showingFallbackVacancies = false;
        _isLoadingExplore = false;
      });
      _stopExploreLoadingMessages();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingExplore = false;
        _exploreError = error.toString();
      });
      _stopExploreLoadingMessages();
    }
  }

  Future<void> _loadFallbackVacancies({
    required bool showTransitionMessage,
  }) async {
    if (!_isCandidateAccount) {
      return;
    }

    setState(() {
      _isLoadingExplore = true;
      _exploreError = null;
    });
    _startExploreLoadingMessages();

    try {
      final List<VacancyModel> fallback = await _vacancyService
          .getExploreVacancies(jwt: widget.jwt, limit: 20);

      if (!mounted) {
        return;
      }

      setState(() {
        _exploreVacancies = fallback;
        _showingFallbackVacancies = true;
        _isLoadingExplore = false;
      });
      _stopExploreLoadingMessages();

      if (showTransitionMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Se acabaron tus recomendadas. Te mostramos más oportunidades.',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingExplore = false;
        _exploreError = error.toString();
      });
      _stopExploreLoadingMessages();
    }
  }

  Future<void> _handleExploreStackEmpty() async {
    if (_showingFallbackVacancies) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay más vacantes disponibles por ahora.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_isLoadingExplore) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cargando más vacantes...'),
          duration: Duration(milliseconds: 1200),
        ),
      );
      return;
    }

    await _loadFallbackVacancies(showTransitionMessage: true);
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
        Expanded(
          child: _buildStatCard('Aplicaciones', '8', Colors.green.shade100),
        ),
        Expanded(
          child: _buildStatCard('Visitantes', '42', Colors.purple.shade100),
        ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
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
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
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
        ? const ['Explora', 'Matches', 'Perfil', 'Vacantes']
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
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
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
            color: isSelected
                ? JobSwipeTheme.primaryIndigo
                : Colors.grey.shade500,
            size: 24,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? JobSwipeTheme.primaryIndigo
                  : Colors.grey.shade500,
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
