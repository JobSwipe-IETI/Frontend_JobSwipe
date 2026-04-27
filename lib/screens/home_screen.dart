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
import 'conversation_chat_screen.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
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
  with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const int _connectionsNavIndex = 1;
  static const int _exploreNavIndex = 0;
  static const Duration _realtimeSyncInterval = Duration(seconds: 6);
  static const Duration _companyDashboardRefreshWindow = Duration(seconds: 12);
  static const Duration _connectionsRefreshWindow = Duration(seconds: 6);
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late PageController _pageController;
  final ProfileApiService _profileApiService = ProfileApiService();
  final VacancyService _vacancyService = VacancyService();
  final ChatService _chatService = ChatService();
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
  List<UserMatchItem> _matches = const [];
  List<ConversationSummary> _conversations = const [];
  List<CandidateApplicationItem> _candidateApplications = const [];
  final Set<String> _knownMatchKeys = <String>{};
  final Set<String> _openingChatMatchKeys = <String>{};
  final Set<String> _knownCompanyLikeKeys = <String>{};
  final Set<String> _knownCandidateDecisionKeys = <String>{};
  final Set<String> _unreadCandidateMatchKeys = <String>{};
  final Set<String> _unreadCandidateRejectionKeys = <String>{};
  final Set<String> _recentCompanyLikeKeys = <String>{};
  final Map<int, int> _lastPipelineApplicantsByVacancy = <int, int>{};
  final Set<int> _recentlyUpdatedPipelineVacancyIds = <int>{};
  final Map<int, int> _recentPipelineDeltaByVacancy = <int, int>{};
  bool _isLoadingMatches = false;
  bool _isLoadingApplications = false;
  bool _isRealtimeSyncInFlight = false;
  Future<void>? _matchesLoadInFlight;
  Future<void>? _conversationsLoadInFlight;
  Future<void>? _applicationsLoadInFlight;
  String? _matchesError;
  String? _conversationsError;
  String? _applicationsError;
  DateTime? _lastCompanyDashboardSyncAt;
  DateTime? _lastMatchesSyncAt;
  DateTime? _lastConversationsSyncAt;
  DateTime? _lastApplicationsSyncAt;
  bool _hasLoadedCompanyDashboard = false;
  bool _hasLoadedMatches = false;
  bool _hasLoadedConversations = false;
  bool _hasLoadedApplications = false;
  int _matchesBadgeCount = 0;
  int _activityBadgeCount = 0;
  int _connectionsSectionIndex = 0;
  bool _isShowingRejectionDialog = false;
  OverlayEntry? _topNoticeEntry;
  Timer? _topNoticeTimer;
  final Map<int, List<VacancyApplicant>> _applicantsCache =
      <int, List<VacancyApplicant>>{};
  final Map<int, Future<List<VacancyApplicant>>> _applicantsInFlight =
      <int, Future<List<VacancyApplicant>>>{};
    final Map<int, VacancyFormData> _vacancyFormCache =
      <int, VacancyFormData>{};
    final Map<int, Future<VacancyFormData>> _vacancyFormInFlight =
      <int, Future<VacancyFormData>>{};
  int _exploreLoadingStep = 0;
  int _exploreProgressPercent = 0;
  String? _exploreBackendMessage;
  Timer? _exploreLoadingTicker;
  Timer? _exploreEmptyAutoRefreshTicker;
  Timer? _realtimeSyncTicker;
  StreamSubscription<RealtimeNotificationEvent>? _notificationRealtimeSubscription;
  DateTime? _lastExploreSyncAt;
  static const List<String> _exploreLoadingMessages = <String>[
    'Cargando vacantes...',
    'Organizando la informacion del perfil...',
    'Buscando coincidencias para ti...',
  ];
  bool get _isCompanyAccount => _userProvider.isCompany;
  bool get _isCandidateAccount => _userProvider.isCandidate;
  int get _candidateConnectionsSignalCount => _unreadCandidateMatchKeys.length;
  int get _candidateRejectionsSignalCount =>
      _unreadCandidateRejectionKeys.length;
  int get _conversationUnreadCount =>
      _conversations.fold(0, (sum, item) => sum + item.unreadCount);
  int get _connectionsBadgeCount => _matchesBadgeCount + _conversationUnreadCount;
    int get _notificationBadgeNavIndex => _connectionsNavIndex;

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
    WidgetsBinding.instance.addObserver(this);

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

    unawaited(_loadPermissions());
    unawaited(_loadUserProfile());
    if (_isCandidateAccount) {
      unawaited(_loadRecommendedVacancies());
      _startExploreEmptyAutoRefreshLoop();
    }
    if (_isCompanyAccount) {
      unawaited(_loadCompanyDashboard(initialLoad: true));
    }
    _loadDeferredHomeData();
    _startNotificationRealtimeStream();
    _startRealtimeSyncLoop();
  }

  void _loadDeferredHomeData() {
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) {
        return;
      }

      unawaited(_loadMatches(initialLoad: true));
      unawaited(_loadConversations(initialLoad: true));
      if (_isCandidateAccount) {
        unawaited(_loadCandidateApplications(initialLoad: true));
      }
    });
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
    final Stopwatch stopwatch = Stopwatch()..start();
    final int? userId =
        widget.userId ?? AuthService.extractUserIdFromJwt(widget.jwt);
    if (userId == null) {
      return;
    }

    try {
      Map<String, dynamic>? profileJson;
      try {
        profileJson = await _profileApiService.getProfileByUserId(
          jwt: widget.jwt,
          userId: userId,
        );
      } catch (_) {
        // One lightweight retry to avoid empty profile UI on transient network spikes.
        profileJson = await _profileApiService.getProfileByUserId(
          jwt: widget.jwt,
          userId: userId,
        );
      }

      if (profileJson == null || !mounted) {
        debugPrint('⚠️ _loadUserProfile returned null for userId=$userId');
        return;
      }

      final String? roleClaim =
          widget.roleOverride ?? AuthService.extractRoleFromJwt(widget.jwt);
      final bool isCompany = roleClaim?.toUpperCase() == 'COMPANY';
      final user = _mapUserProfileFromBackend(profileJson, isCompany);

      setState(() {
        _userProvider.setUser(user);
      });
      debugPrint('⏱️ _loadUserProfile completed in ${stopwatch.elapsedMilliseconds} ms');
    } catch (error) {
      // Keep fallback when backend profile cannot be loaded.
      debugPrint(
        '❌ _loadUserProfile failed after ${stopwatch.elapsedMilliseconds} ms: $error',
      );
    } finally {
      stopwatch.stop();
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
        companyName:
          company?['companyName']?.toString() ??
          json['professionalTitle']?.toString() ??
          _userProvider.currentUser.companyName,
        companyDescription:
          company?['companyDescription']?.toString() ??
          json['summary']?.toString() ??
          _userProvider.currentUser.companyDescription,
      legalId: company?['legalId']?.toString(),
      industry:
          candidate?['sector']?.toString() ??
          company?['industry']?.toString() ??
          json['sector']?.toString() ??
          _userProvider.currentUser.industry,
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
    WidgetsBinding.instance.removeObserver(this);
    _exploreLoadingTicker?.cancel();
    _exploreEmptyAutoRefreshTicker?.cancel();
    _realtimeSyncTicker?.cancel();
    _notificationRealtimeSubscription?.cancel();
    _topNoticeTimer?.cancel();
    _topNoticeEntry?.remove();
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startNotificationRealtimeStream();
      _startRealtimeSyncLoop();
      unawaited(_runRealtimeSync());
      if (_shouldAutoRefreshExploreVacancies()) {
        unawaited(_loadRecommendedVacancies());
      }
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _notificationRealtimeSubscription?.cancel();
      _realtimeSyncTicker?.cancel();
    }
  }

  void _startNotificationRealtimeStream() {
    _notificationRealtimeSubscription?.cancel();

    final int? currentUserId =
        widget.userId ?? AuthService.extractUserIdFromJwt(widget.jwt);
    if (currentUserId == null || currentUserId <= 0) {
      return;
    }

    _notificationRealtimeSubscription = _chatService
        .streamNotificationEvents(currentUserId: currentUserId)
        .listen(
          (RealtimeNotificationEvent event) {
            if (!mounted) {
              return;
            }
            _handleRealtimeNotificationEvent(event);
          },
          onError: (Object error) {
            debugPrint('Realtime notifications stream error: $error');
          },
        );
  }

  void _handleRealtimeNotificationEvent(RealtimeNotificationEvent event) {
    final Map<String, dynamic> payload = event.payload;
    final int? actorUserId = _toNullableInt(payload['actorUserId']);
    final int? currentUserId =
        widget.userId ?? AuthService.extractUserIdFromJwt(widget.jwt);
    final bool isOwnAction =
        actorUserId != null && currentUserId != null && actorUserId == currentUserId;

    switch (event.type) {
      case 'notification.company_like':
        if (!_isCompanyAccount) {
          return;
        }
        unawaited(_loadCompanyDashboard(silent: true, forceRefresh: true));
        unawaited(_loadMatches(forceRefresh: true));
        if (!isOwnAction && _selectedIndex != _exploreNavIndex) {
          setState(() {
            _activityBadgeCount += 1;
          });
        }
        if (isOwnAction) {
          return;
        }
        final String candidateName =
            payload['candidateName']?.toString() ?? 'un candidato';
        final String vacancyTitle =
            payload['vacancyTitle']?.toString() ?? 'tu vacante';
        _showFloatingNotification(
          'Nuevo like de $candidateName en $vacancyTitle.',
          icon: Icons.favorite_rounded,
          accentColor: const Color(0xFFEF4444),
        );
        return;

      case 'notification.company_decision':
        if (!_isCandidateAccount) {
          return;
        }
        unawaited(_loadCandidateApplications(forceRefresh: true));
        unawaited(_loadMatches(forceRefresh: true));
        if (!isOwnAction && _selectedIndex != _notificationBadgeNavIndex) {
          setState(() {
            _matchesBadgeCount += 1;
          });
        }
        if (isOwnAction) {
          return;
        }
        final bool matched = payload['matched'] == true;
        final String companyName = payload['companyName']?.toString() ?? 'la empresa';
        if (matched) {
          _showFloatingNotification(
            '¡Match con $companyName! Ya puedes ver la conexion.',
            icon: Icons.favorite_rounded,
            accentColor: const Color(0xFF7C3AED),
          );
          return;
        }
        final String decision = payload['decision']?.toString() ?? 'DISLIKE';
        if (decision == 'DISLIKE') {
          _showFloatingNotification(
            '$companyName actualizo el estado de tu postulacion.',
            icon: Icons.info_outline_rounded,
            accentColor: const Color(0xFF2563EB),
          );
        }
        return;

      case 'notification.match':
        unawaited(_loadMatches(forceRefresh: true));
        if (_isCompanyAccount) {
          unawaited(_loadCompanyDashboard(silent: true, forceRefresh: true));
        } else if (_isCandidateAccount) {
          unawaited(_loadCandidateApplications(forceRefresh: true));
        }
        if (!isOwnAction && _selectedIndex != _notificationBadgeNavIndex) {
          setState(() {
            _matchesBadgeCount += 1;
          });
        }
        if (isOwnAction) {
          return;
        }
        final String counterpartName =
            payload['counterpartName']?.toString() ?? 'la contraparte';
        _showFloatingNotification(
          'Nueva conexion con $counterpartName.',
          icon: Icons.celebration_rounded,
          accentColor: const Color(0xFF7C3AED),
        );
        return;

      default:
        return;
    }
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
          onVacancySaved: () {
            unawaited(_loadCompanyDashboard(silent: true));
          },
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
          // Optimistic UI update: remove vacancy and update counters instantly
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
                .then((_) {
                  if (_isCandidateAccount) {
                    unawaited(_loadCandidateApplications(forceRefresh: true));
                    unawaited(_loadMatches(forceRefresh: true));
                  }
                  if (_isCompanyAccount) {
                    // Refresca dashboard para datos reales
                    unawaited(_loadCompanyDashboard(forceRefresh: true));
                  }
                })
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
              const Icon(
                Icons.workspaces_rounded,
                size: 42,
                color: Color(0xFF0EA5E9),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: 240,
                child: LinearProgressIndicator(
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Cargando actividad de vacantes... 📊',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Estamos reuniendo tus vacantes, postulados y likes.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  height: 1.3,
                ),
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
                .map(_buildCompanyVacancyPipelineCard),
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
                .map(_buildCompanyActivityItem),
        ],
      ),
    );
  }

  Widget _buildCompanyVacancyPipelineCard(CompanyVacancyPipelineItem item) {
    final bool recentlyUpdated = _recentlyUpdatedPipelineVacancyIds.contains(
      item.vacancyId,
    );
    final int delta = _recentPipelineDeltaByVacancy[item.vacancyId] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: recentlyUpdated
            ? const Color(0xFFECFDF5)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: recentlyUpdated
              ? const Color(0xFF10B981)
              : const Color(0xFFE2E8F0),
        ),
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
                if (recentlyUpdated && delta > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '+$delta nuevo${delta > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ),
                ],
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
    final String signalKey = _companyLikeSignalKey(activity);
    final bool isRecentSignal = _recentCompanyLikeKeys.contains(signalKey);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isRecentSignal ? const Color(0xFFFFFBEB) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRecentSignal
              ? const Color(0xFFF59E0B)
              : const Color(0xFFE2E8F0),
        ),
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
              if (isRecentSignal)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Nuevo',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFB45309),
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

  Future<void> _loadCompanyDashboard({
    bool initialLoad = false,
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    if (!mounted) {
      return;
    }

    if (!forceRefresh &&
        !initialLoad &&
        _hasLoadedCompanyDashboard &&
        _lastCompanyDashboardSyncAt != null &&
        DateTime.now().difference(_lastCompanyDashboardSyncAt!) <
            _companyDashboardRefreshWindow) {
      return;
    }

    if (!silent) {
      setState(() {
        _isLoadingCompanyDashboard = true;
        _companyDashboardError = null;
      });
    }

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

    final Map<int, int> previousPipeline = Map<int, int>.from(
      _lastPipelineApplicantsByVacancy,
    );
    final Set<int> increasedPipelineVacancyIds = <int>{};
    final Map<int, int> pipelineDeltaByVacancy = <int, int>{};
    if (!initialLoad) {
      for (final CompanyVacancyPipelineItem item in pipeline) {
        final int previous = previousPipeline[item.vacancyId] ?? 0;
        if (item.applicantsCount > previous) {
          increasedPipelineVacancyIds.add(item.vacancyId);
          pipelineDeltaByVacancy[item.vacancyId] =
              item.applicantsCount - previous;
        }
      }
    }

    final Set<String> incomingLikeKeys = activity
        .map(_companyLikeSignalKey)
        .toSet();
    final List<CompanyLikeActivity> newLikeItems = <CompanyLikeActivity>[];
    int newLikeSignals = 0;
    if (!initialLoad) {
      for (final CompanyLikeActivity item in activity) {
        final String key = _companyLikeSignalKey(item);
        if (!_knownCompanyLikeKeys.contains(key)) {
          newLikeSignals++;
          newLikeItems.add(item);
        }
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _companyVacancies = vacancies;
      _companyVacancyPipeline = pipeline;
      _companyLikeActivity = activity;
      _lastPipelineApplicantsByVacancy
        ..clear()
        ..addEntries(
          pipeline.map(
            (item) => MapEntry(item.vacancyId, item.applicantsCount),
          ),
        );
      _recentlyUpdatedPipelineVacancyIds
        ..addAll(increasedPipelineVacancyIds);
      for (final MapEntry<int, int> entry in pipelineDeltaByVacancy.entries) {
        final int previousDelta = _recentPipelineDeltaByVacancy[entry.key] ?? 0;
        _recentPipelineDeltaByVacancy[entry.key] = previousDelta + entry.value;
      }
      _knownCompanyLikeKeys
        ..clear()
        ..addAll(incomingLikeKeys);
      _recentCompanyLikeKeys
        ..addAll(newLikeItems.map(_companyLikeSignalKey));
      _lastCompanyDashboardSyncAt = DateTime.now();
      _hasLoadedCompanyDashboard = true;
      if (!initialLoad &&
          _selectedIndex != _exploreNavIndex &&
          newLikeSignals > 0) {
        _activityBadgeCount += newLikeSignals;
      }
      _companyDashboardError = errors.length == 3
          ? 'No se pudo cargar el panel en este momento. Intenta de nuevo.'
          : null;
      if (!silent) {
        _isLoadingCompanyDashboard = false;
      }
    });

    if (_isCompanyAccount && pipeline.isNotEmpty) {
      _prefetchCompanyApplicants(pipeline);
    }

  }

  void _prefetchCompanyApplicants(List<CompanyVacancyPipelineItem> pipeline) {
    final List<CompanyVacancyPipelineItem> topVacancies = pipeline
        .take(2)
        .toList(growable: false);

    for (final CompanyVacancyPipelineItem item in topVacancies) {
      if (_applicantsCache.containsKey(item.vacancyId) ||
          _applicantsInFlight.containsKey(item.vacancyId)) {
        continue;
      }
      unawaited(_loadApplicantsForVacancy(item.vacancyId));
    }
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
              Icons.groups_rounded,
              size: 42,
              color: Color(0xFF6366F1),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: 240,
              child: LinearProgressIndicator(
                minHeight: 8,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Cargando postulados... 👥',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Estamos trayendo compatibilidad, score IA y fecha de postulación para "$vacancyTitle".',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
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
    required Set<int> decisionInProgressCandidateIds,
    required VoidCallback onRefresh,
    required Future<void> Function(
      VacancyApplicant applicant,
      SwipeDecision decision,
    ) onDecision,
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
                    final bool isProcessing =
                        decisionInProgressCandidateIds.contains(
                          applicant.candidateId,
                        );
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
                              if (isProcessing)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              if (isProcessing) const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: isProcessing
                                    ? null
                                    : () => onDecision(
                                        applicant,
                                        SwipeDecision.like,
                                      ),
                                icon: const Icon(
                                  Icons.thumb_up_alt_outlined,
                                  size: 16,
                                ),
                                label: const Text('Like'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: isProcessing
                                    ? null
                                    : () => onDecision(
                                        applicant,
                                        SwipeDecision.dislike,
                                      ),
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
    _markCompanyVacancySignalsAsSeen(item.vacancyId);

    List<VacancyApplicant>? cachedApplicants = _applicantsCache[item.vacancyId];
    final Set<int> decisionInProgressCandidateIds = <int>{};
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
                      decisionInProgressCandidateIds:
                          decisionInProgressCandidateIds,
                      onRefresh: () {
                        setModalState(() {
                          cachedApplicants = null;
                          applicantsFuture = _loadApplicantsForVacancy(
                            item.vacancyId,
                            forceRefresh: true,
                          );
                        });
                      },
                      onDecision: (applicant, decision) async {
                        final List<VacancyApplicant> previousApplicants =
                            List<VacancyApplicant>.from(cachedApplicants!);
                        setModalState(() {
                          decisionInProgressCandidateIds.add(
                            applicant.candidateId,
                          );
                          cachedApplicants = cachedApplicants!
                              .where(
                                (entry) =>
                                    entry.candidateId != applicant.candidateId,
                              )
                              .toList(growable: false);
                        });
                        _applicantsCache[item.vacancyId] = cachedApplicants!;
                        _decrementCompanyPipelineApplicantCount(item.vacancyId);

                        final CompanyCandidateDecisionResult? decisionResult = await _handleCompanyCandidateDecision(
                          vacancyId: item.vacancyId,
                          applicant: applicant,
                          decision: decision,
                        );

                        if (decisionResult == null) {
                          if (!mounted) {
                            return;
                          }
                          setModalState(() {
                            cachedApplicants = previousApplicants;
                            decisionInProgressCandidateIds.remove(
                              applicant.candidateId,
                            );
                          });
                          _applicantsCache[item.vacancyId] = cachedApplicants!;
                          _incrementCompanyPipelineApplicantCount(item.vacancyId);
                          return;
                        }

                        final bool matched = decisionResult.matched;

                        if (!mounted) {
                          return;
                        }

                        setModalState(() {
                          decisionInProgressCandidateIds.remove(
                            applicant.candidateId,
                          );
                        });

                        if (matched) {
                          _pushImmediateMatchSignal(
                            vacancyId: item.vacancyId,
                            vacancyTitle: item.vacancyTitle,
                            applicant: applicant,
                          );
                        }

                        _showFloatingNotification(
                          matched
                            ? 'Candidato aprobado. Nueva conexion lista en Conexiones. 💜'
                            : decision == SwipeDecision.like
                              ? 'Candidato aprobado correctamente. ✅'
                              : 'Dislike guardado para ${applicant.candidateName}.',
                          icon: matched
                            ? Icons.favorite_rounded
                            : decision == SwipeDecision.like
                              ? Icons.check_circle_rounded
                              : Icons.thumb_down_alt_rounded,
                          accentColor: matched
                            ? const Color(0xFF7C3AED)
                            : decision == SwipeDecision.like
                              ? JobSwipeTheme.successGreen
                              : const Color(0xFF64748B),
                        );
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
                          decisionInProgressCandidateIds:
                              decisionInProgressCandidateIds,
                          onRefresh: () {
                            setModalState(() {
                              cachedApplicants = null;
                              applicantsFuture = _loadApplicantsForVacancy(
                                item.vacancyId,
                                forceRefresh: true,
                              );
                            });
                          },
                          onDecision: (applicant, decision) async {
                            final List<VacancyApplicant> previousApplicants =
                                List<VacancyApplicant>.from(applicants);
                            setModalState(() {
                              decisionInProgressCandidateIds.add(
                                applicant.candidateId,
                              );
                              cachedApplicants = applicants
                                  .where(
                                    (entry) =>
                                        entry.candidateId != applicant.candidateId,
                                  )
                                  .toList(growable: false);
                              applicantsFuture = Future.value(cachedApplicants);
                            });
                            _applicantsCache[item.vacancyId] = cachedApplicants!;
                            _decrementCompanyPipelineApplicantCount(item.vacancyId);

                            final CompanyCandidateDecisionResult? decisionResult = await _handleCompanyCandidateDecision(
                              vacancyId: item.vacancyId,
                              applicant: applicant,
                              decision: decision,
                            );

                            if (decisionResult == null) {
                              if (!mounted) {
                                return;
                              }
                              setModalState(() {
                                cachedApplicants = previousApplicants;
                                applicantsFuture = Future.value(cachedApplicants);
                                decisionInProgressCandidateIds.remove(
                                  applicant.candidateId,
                                );
                              });
                              _applicantsCache[item.vacancyId] = cachedApplicants!;
                              _incrementCompanyPipelineApplicantCount(item.vacancyId);
                              return;
                            }

                            final bool matched = decisionResult.matched;

                            if (!mounted) {
                              return;
                            }

                            setModalState(() {
                              decisionInProgressCandidateIds.remove(
                                applicant.candidateId,
                              );
                            });

                            if (matched) {
                              _pushImmediateMatchSignal(
                                vacancyId: item.vacancyId,
                                vacancyTitle: item.vacancyTitle,
                                applicant: applicant,
                              );
                            }

                            _showFloatingNotification(
                              matched
                                  ? 'Candidato aprobado. Nueva conexion lista en Conexiones. 💜'
                                  : decision == SwipeDecision.like
                                      ? 'Candidato aprobado correctamente. ✅'
                                      : 'Dislike guardado para ${applicant.candidateName}.',
                              icon: matched
                                  ? Icons.favorite_rounded
                                  : decision == SwipeDecision.like
                                      ? Icons.check_circle_rounded
                                      : Icons.thumb_down_alt_rounded,
                              accentColor: matched
                                  ? const Color(0xFF7C3AED)
                                  : decision == SwipeDecision.like
                                      ? JobSwipeTheme.successGreen
                                      : const Color(0xFF64748B),
                            );
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
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _isLoadingExplore ? null : _loadRecommendedVacancies,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Buscar nuevamente'),
          ),
          const SizedBox(height: 8),
          Text(
            'Actualizamos automaticamente cada 45 segundos mientras esta vista siga vacia.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Future<void> _loadRecommendedVacancies() async {
    if (!_isCandidateAccount) {
      return;
    }
    if (_isLoadingExplore) {
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

        await Future.delayed(const Duration(milliseconds: 500));
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
          _exploreError = null;
        });
        _stopExploreLoadingMessages();
      } catch (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLoadingExplore = false;
          _exploreError =
              'No se pudieron cargar vacantes por ahora. Intenta de nuevo en un momento.';
        });
        _stopExploreLoadingMessages();
      }
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

  Future<void> _loadMatches({
    bool initialLoad = false,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        !initialLoad &&
        _hasLoadedMatches &&
        _lastMatchesSyncAt != null &&
        DateTime.now().difference(_lastMatchesSyncAt!) <
            _connectionsRefreshWindow) {
      return;
    }

    if (_matchesLoadInFlight != null) {
      return _matchesLoadInFlight!;
    }

    final Future<void> inFlight = _loadMatchesInternal(initialLoad: initialLoad);
    _matchesLoadInFlight = inFlight;

    try {
      await inFlight;
    } finally {
      if (_matchesLoadInFlight == inFlight) {
        _matchesLoadInFlight = null;
      }
    }
  }

  Future<void> _loadMatchesInternal({bool initialLoad = false}) async {
    if (_isLoadingMatches) {
      return;
    }

    bool shouldRetry = false;

    setState(() {
      _isLoadingMatches = true;
      _matchesError = null;
    });

    try {
      final List<UserMatchItem> matches = await _vacancyService.getMatches(
        jwt: widget.jwt,
        limit: 30,
      );

      final Set<String> incomingKeys = matches
          .map((item) => item.stableKey)
          .toSet();
      int newCount = 0;
      if (!initialLoad) {
        for (final String key in incomingKeys) {
          if (!_knownMatchKeys.contains(key)) {
            newCount++;
            if (_isCandidateAccount) {
              _unreadCandidateMatchKeys.add(key);
            }
          }
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _matches = matches;
        _knownMatchKeys
          ..clear()
          ..addAll(incomingKeys);
        _lastMatchesSyncAt = DateTime.now();
        _hasLoadedMatches = true;
        if (initialLoad || _selectedIndex == _notificationBadgeNavIndex) {
          _matchesBadgeCount = 0;
        } else if (newCount > 0) {
          _matchesBadgeCount += newCount;
        }
      });
    } on VacancyException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (_matches.isEmpty) {
          _matchesError = e.message;
        }
      });

      if (_matches.isNotEmpty) {
        _showFloatingNotification(
          e.message,
          icon: Icons.wifi_off_rounded,
          accentColor: JobSwipeTheme.errorRed,
        );
      }

      if (!initialLoad) {
        shouldRetry = true;
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (_matches.isEmpty) {
          _matchesError = 'No se pudieron cargar tus matches por ahora.';
        }
      });

      if (_matches.isNotEmpty) {
        _showFloatingNotification(
          'No se pudieron actualizar tus matches ahora.',
          icon: Icons.error_outline_rounded,
          accentColor: JobSwipeTheme.errorRed,
        );
      }

      if (!initialLoad) {
        shouldRetry = true;
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMatches = false;
        });
      }
    }

    if (shouldRetry && mounted) {
      Future<void>.delayed(const Duration(milliseconds: 800), () {
        if (!mounted || _isLoadingMatches) {
          return;
        }
        unawaited(_loadMatches(initialLoad: true));
      });
    }
  }

  Future<void> _loadConversations({
    bool initialLoad = false,
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        !initialLoad &&
        _hasLoadedConversations &&
        _lastConversationsSyncAt != null &&
        DateTime.now().difference(_lastConversationsSyncAt!) <
            _connectionsRefreshWindow) {
      return;
    }

    if (_conversationsLoadInFlight != null) {
      return _conversationsLoadInFlight!;
    }

    final Future<void> inFlight = _loadConversationsInternal(
      initialLoad: initialLoad,
      silent: silent,
    );
    _conversationsLoadInFlight = inFlight;

    try {
      await inFlight;
    } finally {
      if (_conversationsLoadInFlight == inFlight) {
        _conversationsLoadInFlight = null;
      }
    }
  }

  Future<void> _loadConversationsInternal({
    bool initialLoad = false,
    bool silent = false,
  }) async {
    try {
      final List<ConversationSummary> conversations =
          await _chatService.getConversations(jwt: widget.jwt);
      if (!mounted) {
        return;
      }

      final int previousUnread = _conversationUnreadCount;
      final int nextUnread = conversations.fold(
        0,
        (sum, item) => sum + item.unreadCount,
      );

      setState(() {
        _conversations = conversations;
        _conversationsError = null;
        _lastConversationsSyncAt = DateTime.now();
        _hasLoadedConversations = true;
      });

      if (!initialLoad &&
          !silent &&
          nextUnread > previousUnread &&
          _selectedIndex != _connectionsNavIndex) {
        _showFloatingNotification(
          nextUnread - previousUnread == 1
              ? 'Tienes 1 mensaje nuevo en tus conversaciones.'
              : 'Tienes ${nextUnread - previousUnread} mensajes nuevos en tus conversaciones.',
          icon: Icons.mark_chat_unread_rounded,
          accentColor: const Color(0xFF0EA5E9),
        );
      }
    } on ChatException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _conversationsError = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _conversationsError = 'No se pudieron cargar las conversaciones.';
      });
    }
  }

  Future<void> _loadCandidateApplications({
    bool initialLoad = false,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        !initialLoad &&
        _hasLoadedApplications &&
        _lastApplicationsSyncAt != null &&
        DateTime.now().difference(_lastApplicationsSyncAt!) <
            _connectionsRefreshWindow) {
      return;
    }

    if (_applicationsLoadInFlight != null) {
      return _applicationsLoadInFlight!;
    }

    final Future<void> inFlight = _loadCandidateApplicationsInternal(
      initialLoad: initialLoad,
    );
    _applicationsLoadInFlight = inFlight;

    try {
      await inFlight;
    } finally {
      if (_applicationsLoadInFlight == inFlight) {
        _applicationsLoadInFlight = null;
      }
    }
  }

  Future<void> _loadCandidateApplicationsInternal({
    bool initialLoad = false,
  }) async {
    if (_isLoadingApplications || !_isCandidateAccount) {
      return;
    }

    setState(() {
      _isLoadingApplications = true;
      _applicationsError = null;
    });

    try {
      final List<CandidateApplicationItem> applications =
          await _vacancyService.getCandidateApplications(
            jwt: widget.jwt,
            limit: 50,
          );

      if (!mounted) {
        return;
      }

        final Set<String> incomingDecisionKeys = applications
          .where((item) => item.isRejected)
          .map(_candidateDecisionSignalKey)
          .toSet();
      int newDecisionSignals = 0;
      if (!initialLoad) {
        for (final String key in incomingDecisionKeys) {
          if (!_knownCandidateDecisionKeys.contains(key)) {
            newDecisionSignals++;
            _unreadCandidateRejectionKeys.add(key);
          }
        }
      }

      setState(() {
        _candidateApplications = applications;
        _knownCandidateDecisionKeys
          ..clear()
          ..addAll(incomingDecisionKeys);
        _lastApplicationsSyncAt = DateTime.now();
        _hasLoadedApplications = true;
        if (!initialLoad &&
            _selectedIndex != _notificationBadgeNavIndex &&
            newDecisionSignals > 0) {
          _matchesBadgeCount += newDecisionSignals;
        }
      });

      if (!initialLoad &&
          _selectedIndex != _notificationBadgeNavIndex &&
          newDecisionSignals > 0) {
        _showFloatingNotification(
          newDecisionSignals == 1
              ? 'Tu proceso en 1 vacante tuvo una actualizacion.'
              : 'Tu proceso en $newDecisionSignals vacantes tuvo actualizaciones.',
          icon: Icons.mark_email_unread_rounded,
          accentColor: const Color(0xFF2563EB),
        );
      }
    } on VacancyException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (_candidateApplications.isEmpty || initialLoad) {
          _applicationsError = e.message;
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (_candidateApplications.isEmpty || initialLoad) {
          _applicationsError =
              'No se pudieron cargar tus postulaciones por ahora.';
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingApplications = false;
        });
      }
    }
  }

  Future<CompanyCandidateDecisionResult?> _handleCompanyCandidateDecision({
    required int vacancyId,
    required VacancyApplicant applicant,
    required SwipeDecision decision,
  }) async {
    try {
      CompanyDecisionPayload? payload;
      if (decision == SwipeDecision.dislike) {
        final VacancyFormData vacancyForm = await _getVacancyFormForDecision(
          vacancyId,
        );
        payload = await _promptCompanyRejectionFeedback(
          candidateName: applicant.candidateName,
          vacancyForm: vacancyForm,
          aiSummary: applicant.feedback,
        );
        if (payload == null) {
          return null;
        }
      }

      final CompanyCandidateDecisionResult result =
          await _submitCompanyDecisionWithSingleRetry(
            vacancyId: vacancyId,
            candidateId: applicant.candidateId,
            decision: decision,
            payload: payload,
          );

      if (!mounted) {
        return null;
      }

      unawaited(
        _loadMatches().catchError((_) {
          // Ignore transient sync errors after a successful decision save.
        }),
      );
      if (_isCompanyAccount) {
        unawaited(
          _loadCompanyDashboard(silent: true, forceRefresh: true).catchError((_) {
            // Ignore transient sync errors after a successful decision save.
          }),
        );
      }
      return result;
    } on VacancyException catch (e) {
      if (!mounted) {
        return null;
      }
      _showFloatingNotification(e.message);
      return null;
    } catch (_) {
      if (!mounted) {
        return null;
      }
      _showFloatingNotification(
        'No se pudo guardar la decision de la empresa.',
        icon: Icons.error_outline_rounded,
        accentColor: JobSwipeTheme.errorRed,
      );
      return null;
    }
  }

  Future<CompanyCandidateDecisionResult> _submitCompanyDecisionWithSingleRetry({
    required int vacancyId,
    required int candidateId,
    required SwipeDecision decision,
    CompanyDecisionPayload? payload,
  }) async {
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        return await _vacancyService.registerCompanyCandidateDecision(
          jwt: widget.jwt,
          vacancyId: vacancyId,
          candidateId: candidateId,
          decision: decision,
          payload: payload,
        );
      } on TimeoutException {
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 350));
          continue;
        }
        rethrow;
      } on VacancyException catch (e) {
        final bool shouldRetry =
            attempt == 0 && _isTransientCompanyDecisionError(e.message);
        if (shouldRetry) {
          await Future<void>.delayed(const Duration(milliseconds: 350));
          continue;
        }
        rethrow;
      }
    }

    throw const VacancyException('No se pudo guardar la decision de empresa.');
  }

  bool _isTransientCompanyDecisionError(String message) {
    final String normalized = message.toLowerCase();
    return normalized.contains('(404)') ||
        normalized.contains('(408)') ||
        normalized.contains('(429)') ||
        normalized.contains('(500)') ||
        normalized.contains('(502)') ||
        normalized.contains('(503)') ||
        normalized.contains('(504)') ||
        normalized.contains('timed out') ||
        normalized.contains('tiempo de espera') ||
        normalized.contains('error de red');
  }

  Future<VacancyFormData> _getVacancyFormForDecision(int vacancyId) {
    final VacancyFormData? cached = _vacancyFormCache[vacancyId];
    if (cached != null) {
      return Future.value(cached);
    }

    final Future<VacancyFormData>? pending = _vacancyFormInFlight[vacancyId];
    if (pending != null) {
      return pending;
    }

    final Future<VacancyFormData> load = _vacancyService
        .getVacancyById(jwt: widget.jwt, vacancyId: vacancyId)
        .then((value) {
          _vacancyFormCache[vacancyId] = value;
          return value;
        });

    _vacancyFormInFlight[vacancyId] = load;
    load.whenComplete(() {
      if (_vacancyFormInFlight[vacancyId] == load) {
        _vacancyFormInFlight.remove(vacancyId);
      }
    });

    return load;
  }

  Future<CompanyDecisionPayload?> _promptCompanyRejectionFeedback(
    {
    required String candidateName,
    required VacancyFormData vacancyForm,
    String? aiSummary,
  }
  ) async {
    if (_isShowingRejectionDialog) {
      return null;
    }

    _isShowingRejectionDialog = true;
    try {
      final CompanyDecisionPayload? payload = await Navigator.of(
        context,
        rootNavigator: true,
      ).push<CompanyDecisionPayload>(
        MaterialPageRoute<CompanyDecisionPayload>(
          fullscreenDialog: true,
          builder: (_) => CompanyRejectionScreen(
            candidateName: candidateName,
            vacancyForm: vacancyForm,
            aiSummary: aiSummary,
          ),
        ),
      );

      return payload;
    } finally {
      _isShowingRejectionDialog = false;
    }
  }

  Widget _buildChecklistSection({
    required String title,
    required List<String> options,
    required Set<String> selectedValues,
    required void Function(String value, bool enabled) onToggle,
    required String emptyText,
  }) {
    final List<String> cleanedOptions = options
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        if (cleanedOptions.isEmpty)
          Text(
            emptyText,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: cleanedOptions.map((option) {
              final bool selected = selectedValues.contains(option);
              return FilterChip(
                label: Text(option),
                selected: selected,
                onSelected: (enabled) => onToggle(option, enabled),
              );
            }).toList(growable: false),
          ),
      ],
    );
  }

  void _showFloatingNotification(
    String message, {
    IconData icon = Icons.check_circle_rounded,
    Color accentColor = const Color(0xFF6366F1),
  }) {
    if (!mounted) {
      return;
    }

    _topNoticeTimer?.cancel();
    _topNoticeEntry?.remove();

    final OverlayState overlayState = Overlay.of(context);

    _topNoticeEntry = OverlayEntry(
      builder: (context) {
        final double topInset = MediaQuery.of(context).viewPadding.top;
        return Positioned(
          top: topInset + 12,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accentColor.withValues(alpha: 0.25)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 16, color: accentColor),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    overlayState.insert(_topNoticeEntry!);
    _topNoticeTimer = Timer(const Duration(seconds: 2), () {
      _topNoticeEntry?.remove();
      _topNoticeEntry = null;
    });
  }

  void _pushImmediateMatchSignal({
    required int vacancyId,
    required String vacancyTitle,
    required VacancyApplicant applicant,
  }) {
    final UserMatchItem optimistic = UserMatchItem(
      vacancyId: vacancyId,
      vacancyTitle: vacancyTitle,
      counterpartId: applicant.candidateId,
      counterpartName: applicant.candidateName,
      matchedAt: DateTime.now(),
      compatibilityPercentage: applicant.compatibilityPercentage,
      compatibilityLevel: applicant.compatibilityLevel,
    );

    if (_knownMatchKeys.contains(optimistic.stableKey)) {
      return;
    }

    setState(() {
      _matches = <UserMatchItem>[optimistic, ..._matches];
      _knownMatchKeys.add(optimistic.stableKey);
      if (_selectedIndex != 1) {
        _matchesBadgeCount += 1;
      }
    });
  }

  Widget _buildMatches() {
    if (_isCandidateAccount) {
      return _buildCandidateConnectionsHub();
    }

    if (_isLoadingMatches && _matches.isEmpty) {
      return _buildMatchesLoadingState();
    }

    if (_matchesError != null && _matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 42),
              const SizedBox(height: 10),
              Text(
                _matchesError!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadMatches,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('Conexiones'),
          const SizedBox(height: 24),
          _buildStatsCards(matchesCount: _matches.length),
          const SizedBox(height: 28),
          _buildSectionTitle('Ultimas conexiones'),
          const SizedBox(height: 16),
          if (_matches.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                _isCompanyAccount
                    ? 'Aun no tienes conexiones. Da like a candidatos para cerrar una conexion mutua.'
                    : 'Aun no tienes conexiones. Cuando una empresa te de like, aparecera aqui.',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF475569),
                  height: 1.35,
                ),
              ),
            )
          else
            ..._matches.map(_buildMatchCard),
        ],
      ),
    );
  }

  Widget _buildCandidateConnectionsHub() {
    final List<CandidateApplicationItem> rejectedApplications =
        _candidateApplications
        .where((item) => item.isRejected)
        .toList(growable: false);
    final int rejectedCount = rejectedApplications.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('Conexiones'),
          const SizedBox(height: 24),
          _buildStatsCards(
            matchesCount: _matches.length,
            applicationsCount: rejectedCount,
            rejectedCount: rejectedCount,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildConnectionsTabButton(
                  label: 'Conexiones',
                  signalCount: _candidateConnectionsSignalCount,
                  selected: _connectionsSectionIndex == 0,
                  onTap: () {
                    setState(() {
                      _connectionsSectionIndex = 0;
                    });
                    _markCandidateConnectionsSignalsAsSeen();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildConnectionsTabButton(
                  label: 'Rechazos',
                  signalCount: _candidateRejectionsSignalCount,
                  selected: _connectionsSectionIndex == 1,
                  onTap: () {
                    setState(() {
                      _connectionsSectionIndex = 1;
                    });
                    _markCandidateRejectionSignalsAsSeen();
                    unawaited(_loadCandidateApplications());
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_connectionsSectionIndex == 0)
            _buildConnectionsSectionContent()
          else
            _buildApplicationsSectionContent(),
        ],
      ),
    );
  }

  Widget _buildConnectionsTabButton({
    required String label,
    required bool selected,
    int signalCount = 0,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? JobSwipeTheme.primaryIndigo
                  : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF334155),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          if (!selected && signalCount > 0)
            Positioned(
              right: 8,
              top: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: JobSwipeTheme.errorRed,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  signalCount > 9 ? '9+' : '$signalCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConnectionsSectionContent() {
    if (_isLoadingMatches && _matches.isEmpty) {
      return _buildMatchesLoadingState();
    }

    if (_matchesError != null && _matches.isEmpty) {
      return _buildInlineRetryCard(
        title: 'No se pudieron cargar tus conexiones',
        message: _matchesError!,
        onRetry: () => _loadMatches(),
      );
    }

    if (_matches.isEmpty) {
      return _buildInlineInfoCard(
        title: 'Aun no tienes conexiones',
        message:
            'Cuando una empresa te de like a una vacante que ya te gusto, veras la conexion aqui.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_conversations.isNotEmpty) ...[
          _buildActiveConversationsBanner(),
          const SizedBox(height: 12),
        ],
        ..._matches.map(_buildMatchCard),
      ],
    );
  }

  Widget _buildApplicationsSectionContent() {
    final List<CandidateApplicationItem> rejectedApplications =
        _candidateApplications
            .where((item) => item.isRejected)
            .toList(growable: false);

    if (_isLoadingApplications && _candidateApplications.isEmpty) {
      return _buildRejectionsLoadingState();
    }

    if (_applicationsError != null && _candidateApplications.isEmpty) {
      return _buildInlineRetryCard(
        title: 'No se pudieron cargar tus rechazos',
        message: _applicationsError!,
        onRetry: () => _loadCandidateApplications(),
      );
    }

    if (rejectedApplications.isEmpty) {
      return _buildInlineInfoCard(
        title: 'Sin rechazos por ahora',
        message:
            'Aqui solo veras las vacantes rechazadas con el detalle de por que no avanzaste.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rejectedApplications
          .map(_buildCandidateApplicationCard)
          .toList(growable: false),
    );
  }

  Widget _buildActiveConversationsBanner() {
    final ConversationSummary latest = _conversations.first;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.forum_rounded,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _conversationUnreadCount > 0
                      ? 'Tienes $_conversationUnreadCount mensaje${_conversationUnreadCount > 1 ? 's' : ''} nuevo${_conversationUnreadCount > 1 ? 's' : ''}'
                      : 'Conversaciones activas',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  latest.lastMessagePreview ??
                      'Tu conexion con ${latest.counterpartName} ya tiene un chat disponible.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineInfoCard({required String title, required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF475569),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineRetryCard({
    required String title,
    required String message,
    required Future<void> Function() onRetry,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => unawaited(onRetry()),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildCandidateApplicationCard(CandidateApplicationItem application) {
    final bool pending = application.isPending;
    final bool rejected = application.isRejected;
    final Color statusColor = pending
      ? const Color(0xFFF59E0B)
      : rejected
      ? const Color(0xFFDC2626)
      : const Color(0xFF10B981);
    final String statusLabel = pending
      ? 'Pendiente'
      : rejected
      ? 'No avanzaste'
      : 'Conectada';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Expanded(
                child: Text(
                  application.vacancyTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${application.companyName} • ${_formatRelativeTime(application.appliedAt)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => _openRejectedApplicationDetails(application),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 14,
                      color: Color(0xFF4F46E5),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Detalles',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4338CA),
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: Color(0xFF4338CA),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openRejectedApplicationDetails(
    CandidateApplicationItem application,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.78,
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  application.vacancyTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${application.companyName} • ${_formatRelativeTime(application.appliedAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 14),
                if ((application.rejectionReason ?? '').isNotEmpty)
                  _buildDetailBlock(
                    title: 'Motivo',
                    content: application.rejectionReason!,
                  ),
                if ((application.expectedExperienceLevel ?? '').isNotEmpty)
                  _buildDetailBlock(
                    title: 'Nivel de experiencia esperado',
                    content: application.expectedExperienceLevel!,
                  ),
                if (application.missingTechnologies.isNotEmpty)
                  _buildDetailBlock(
                    title: 'Tecnologias faltantes',
                    content: application.missingTechnologies.join(', '),
                  ),
                if (application.missingResponsibilities.isNotEmpty)
                  _buildDetailBlock(
                    title: 'Responsabilidades no cumplidas',
                    content: application.missingResponsibilities.join(', '),
                  ),
                if (application.missingTechnicalRequirements.isNotEmpty)
                  _buildDetailBlock(
                    title: 'Requisitos tecnicos no cumplidos',
                    content:
                        application.missingTechnicalRequirements.join(', '),
                  ),
                if ((application.aiSummary ?? '').isNotEmpty)
                  _buildDetailBlock(
                    title: 'Resumen IA',
                    content: application.aiSummary!,
                  ),
                if ((application.rejectionComment ?? '').isNotEmpty)
                  _buildDetailBlock(
                    title: 'Comentario adicional',
                    content: application.rejectionComment!,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailBlock({required String title, required String content}) {
    return Container(
      width: double.infinity,
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
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF0F172A),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesLoadingState() {
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
              Icons.favorite_rounded,
              size: 42,
              color: Color(0xFF7C3AED),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: 240,
              child: LinearProgressIndicator(
                minHeight: 8,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Buscando tus conexiones... 💜',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Estamos sincronizando empresas, vacantes y estado de conexion.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectionsLoadingState() {
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
              Icons.rule_folder_rounded,
              size: 42,
              color: Color(0xFF0EA5E9),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: 240,
              child: LinearProgressIndicator(
                minHeight: 8,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Cargando tus rechazos... 📄',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Estamos consultando feedback y motivos de cada vacante.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                height: 1.3,
              ),
            ),
          ],
        ),
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

  Widget _buildStatsCards({
    required int matchesCount,
    int? applicationsCount,
    int? rejectedCount,
  }) {
    final int resolvedApplications = applicationsCount ?? _matchesBadgeCount;
    final int resolvedRejected = rejectedCount ?? _matchesBadgeCount;

    return Row(
      spacing: 12,
      children: [
        Expanded(
          child: _buildStatCard(
            'Conexiones',
            '$matchesCount',
            Colors.blue.shade100,
          ),
        ),
        Expanded(
          child: _buildStatCard(
            _isCompanyAccount ? 'Candidatos' : 'Rechazos',
            '$resolvedApplications',
            Colors.green.shade100,
          ),
        ),
        Expanded(
          child: _buildStatCard(
            _isCompanyAccount ? 'Nuevos' : 'Rechazos',
            '$resolvedRejected',
            Colors.purple.shade100,
          ),
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

  Widget _buildMatchCard(UserMatchItem match) {
    final ConversationSummary? conversation = _findConversationForMatch(match);
    final bool hasConversation = conversation != null;
    final bool isOpeningChat = _openingChatMatchKeys.contains(match.stableKey);
    final int unreadCount = conversation?.unreadCount ?? 0;
    final String subtitle = _isCompanyAccount
        ? '${match.counterpartName} - ${_formatRelativeTime(match.matchedAt)}'
        : '${match.counterpartName} - ${_formatRelativeTime(match.matchedAt)}';
    final String statusLabel = match.compatibilityPercentage != null
        ? '${match.compatibilityPercentage!.toStringAsFixed(0)}%'
        : (match.compatibilityLevel ?? 'Match');

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
              Expanded(
                child: Text(
                  match.vacancyTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
              const SizedBox(width: 10),
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
                  'Conexion',
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
            subtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  ),
                  if (hasConversation)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        unreadCount > 0
                            ? '$unreadCount nuevo${unreadCount > 1 ? 's' : ''}'
                            : 'Chat activo',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0369A1),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isOpeningChat ? null : () => _handleOpenChat(match),
                  icon: isOpeningChat
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          hasConversation
                              ? Icons.chat_bubble_rounded
                              : _isCompanyAccount
                              ? Icons.forum_rounded
                              : Icons.schedule_send_rounded,
                        ),
                  label: Text(
                    isOpeningChat
                        ? 'Cargando...'
                        : hasConversation
                        ? 'Abrir chat'
                        : _isCompanyAccount
                        ? 'Iniciar chat'
                        : 'Esperando chat',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: hasConversation
                        ? const Color(0xFF0F172A)
                        : _isCompanyAccount
                        ? JobSwipeTheme.primaryIndigo
                        : const Color(0xFF64748B),
                    side: BorderSide(
                      color: hasConversation
                          ? const Color(0xFFBFDBFE)
                          : _isCompanyAccount
                          ? const Color(0xFFC7D2FE)
                          : const Color(0xFFE2E8F0),
                    ),
                    backgroundColor: hasConversation
                        ? const Color(0xFFF8FBFF)
                        : _isCompanyAccount
                        ? const Color(0xFFF5F3FF)
                        : const Color(0xFFF8FAFC),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (hasConversation && unreadCount > 0) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: JobSwipeTheme.errorRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  ConversationSummary? _findConversationForMatch(UserMatchItem match) {
    for (final ConversationSummary item in _conversations) {
      if (item.matchKey == match.stableKey) {
        return item;
      }
    }
    return null;
  }

  Future<void> _handleOpenChat(UserMatchItem match) async {
    if (_openingChatMatchKeys.contains(match.stableKey)) {
      return;
    }
    setState(() {
      _openingChatMatchKeys.add(match.stableKey);
    });

    ConversationSummary? conversation = _findConversationForMatch(match);

    if (conversation == null && !_isCompanyAccount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La empresa aun no ha iniciado la conversacion para esta conexion.',
          ),
        ),
      );
      setState(() {
        _openingChatMatchKeys.remove(match.stableKey);
      });
      return;
    }

    try {
      if (conversation == null) {
        try {
          final ConversationSummary createdConversation =
              await _chatService.startConversation(
            jwt: widget.jwt,
            vacancyId: match.vacancyId,
            candidateId: match.counterpartId,
          );
          conversation = createdConversation;
          if (!mounted) {
            return;
          }
          setState(() {
            _conversations = <ConversationSummary>[
              createdConversation,
              ..._conversations.where(
                (item) =>
                    item.conversationId != createdConversation.conversationId,
              ),
            ];
            _conversationsError = null;
          });
          unawaited(_loadConversations(silent: true));
        } on ChatException catch (error) {
          if (!mounted) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.message)),
          );
          return;
        }
      }

      if (!mounted) {
        return;
      }

      final ConversationSummary selectedConversation = conversation;

      _markConversationUnreadLocally(selectedConversation.conversationId);

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              ConversationChatScreen(
                jwt: widget.jwt,
                summary: selectedConversation,
              ),
        ),
      );

      if (!mounted) {
        return;
      }
      await _loadConversations(silent: true);
    } finally {
      if (mounted) {
        setState(() {
          _openingChatMatchKeys.remove(match.stableKey);
        });
      }
    }
  }

  void _markConversationUnreadLocally(int conversationId) {
    final int index = _conversations.indexWhere(
      (item) => item.conversationId == conversationId,
    );
    if (index == -1 || _conversations[index].unreadCount == 0) {
      return;
    }

    setState(() {
      final List<ConversationSummary> next = List<ConversationSummary>.of(
        _conversations,
      );
      final ConversationSummary current = next[index];
      next[index] = ConversationSummary(
        conversationId: current.conversationId,
        vacancyId: current.vacancyId,
        vacancyTitle: current.vacancyTitle,
        counterpartId: current.counterpartId,
        counterpartName: current.counterpartName,
        counterpartRole: current.counterpartRole,
        initiatedByUserId: current.initiatedByUserId,
        lastMessagePreview: current.lastMessagePreview,
        lastMessageAt: current.lastMessageAt,
        unreadCount: 0,
        createdAt: current.createdAt,
        updatedAt: current.updatedAt,
      );
      _conversations = next;
    });
  }

  int? _toNullableInt(dynamic value) {
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

  Widget _buildBottomNav() {
    // Construir tabs dinámicamente según el tipo de usuario
    final tabs = _isCompanyAccount
      ? const ['Explora', 'Conexiones', 'Perfil', 'Vacantes']
      : const ['Explora', 'Conexiones', 'Perfil'];

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
                badgeCount: index == _exploreNavIndex
                    ? _activityBadgeCount
                    : index == _notificationBadgeNavIndex
                        ? _connectionsBadgeCount
                        : 0,
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
    required int badgeCount,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? JobSwipeTheme.primaryIndigo
                    : Colors.grey.shade500,
                size: 24,
              ),
              if (badgeCount > 0 && !isSelected)
                Positioned(
                  right: -8,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: JobSwipeTheme.errorRed,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badgeCount > 9 ? '9+' : '$badgeCount',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
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
    if (index == _exploreNavIndex && _isCompanyAccount) {
      _loadCompanyDashboard(silent: true, forceRefresh: true);
    }

    if (index == _exploreNavIndex && _isCompanyAccount) {
      _activityBadgeCount = 0;
      _loadCompanyDashboard(silent: true, forceRefresh: true);
    }

    if (index == _connectionsNavIndex) {
      _loadMatches(forceRefresh: true);
      _loadConversations(silent: true, forceRefresh: true);
      if (_isCandidateAccount) {
        _loadCandidateApplications(forceRefresh: true);
      }
      if (_isCompanyAccount) {
        _loadCompanyDashboard(silent: true, forceRefresh: true);
      }
    }

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
    setState(() {
      _selectedIndex = index;
      if (index == _notificationBadgeNavIndex) {
        _matchesBadgeCount = 0;
      }
    });

    if (_isCandidateAccount && index == _connectionsNavIndex) {
      if (_connectionsSectionIndex == 0) {
        _markCandidateConnectionsSignalsAsSeen();
      } else {
        _markCandidateRejectionSignalsAsSeen();
      }
    }
  }

  void _markCandidateConnectionsSignalsAsSeen() {
    if (_unreadCandidateMatchKeys.isEmpty) {
      return;
    }
    setState(() {
      _unreadCandidateMatchKeys.clear();
    });
  }

  void _markCandidateRejectionSignalsAsSeen() {
    if (_unreadCandidateRejectionKeys.isEmpty) {
      return;
    }
    setState(() {
      _unreadCandidateRejectionKeys.clear();
    });
  }

  void _markCompanyVacancySignalsAsSeen(int vacancyId) {
    if (!_recentlyUpdatedPipelineVacancyIds.contains(vacancyId) &&
        !_recentPipelineDeltaByVacancy.containsKey(vacancyId) &&
        !_recentCompanyLikeKeys.any(
          (key) => key.startsWith('$vacancyId:'),
        )) {
      return;
    }

    setState(() {
      _recentlyUpdatedPipelineVacancyIds.remove(vacancyId);
      _recentPipelineDeltaByVacancy.remove(vacancyId);
      _recentCompanyLikeKeys.removeWhere(
        (key) => key.startsWith('$vacancyId:'),
      );
    });
  }

  void _decrementCompanyPipelineApplicantCount(int vacancyId) {
    final bool exists = _companyVacancyPipeline
        .any((item) => item.vacancyId == vacancyId);
    if (!exists) {
      return;
    }

    setState(() {
      _companyVacancyPipeline = _companyVacancyPipeline
          .map((item) {
            if (item.vacancyId != vacancyId) {
              return item;
            }
            return CompanyVacancyPipelineItem(
              vacancyId: item.vacancyId,
              vacancyTitle: item.vacancyTitle,
              applicantsCount: (item.applicantsCount - 1).clamp(0, 9999),
            );
          })
          .toList(growable: false);

      final int current = _lastPipelineApplicantsByVacancy[vacancyId] ?? 0;
      _lastPipelineApplicantsByVacancy[vacancyId] = (current - 1).clamp(0, 9999);
    });
  }

  void _incrementCompanyPipelineApplicantCount(int vacancyId) {
    final bool exists = _companyVacancyPipeline
        .any((item) => item.vacancyId == vacancyId);
    if (!exists) {
      return;
    }

    setState(() {
      _companyVacancyPipeline = _companyVacancyPipeline
          .map((item) {
            if (item.vacancyId != vacancyId) {
              return item;
            }
            return CompanyVacancyPipelineItem(
              vacancyId: item.vacancyId,
              vacancyTitle: item.vacancyTitle,
              applicantsCount: item.applicantsCount + 1,
            );
          })
          .toList(growable: false);

      final int current = _lastPipelineApplicantsByVacancy[vacancyId] ?? 0;
      _lastPipelineApplicantsByVacancy[vacancyId] = current + 1;
    });
  }

  Future<void> _loadPermissions() async {
    // Ya no se necesita cargar permisos especiales
    // El tipo de usuario se obtiene del UserProvider
  }

  String _companyLikeSignalKey(CompanyLikeActivity item) {
    return '${item.vacancyId}:${item.candidateId}:${item.likedAt?.toIso8601String() ?? 'na'}';
  }

  String _candidateDecisionSignalKey(CandidateApplicationItem item) {
    return '${item.vacancyId}:${item.companyId}:${item.decision ?? 'NA'}:${item.decisionAt?.toIso8601String() ?? 'na'}:${item.matched}';
  }

  void _startRealtimeSyncLoop() {
    _realtimeSyncTicker?.cancel();
    _realtimeSyncTicker = Timer.periodic(_realtimeSyncInterval, (_) {
      if (!mounted) {
        return;
      }
      unawaited(_runRealtimeSync());
    });
  }

  Future<void> _runRealtimeSync() async {
    if (!mounted || _isRealtimeSyncInFlight) {
      return;
    }

    _isRealtimeSyncInFlight = true;
    try {
      if (_isCompanyAccount) {
        await _loadCompanyDashboard(silent: true);
        await _loadMatches();
      } else {
        await _loadMatches();
        await _loadCandidateApplications();
        if (_selectedIndex == _exploreNavIndex && _shouldLightSyncExploreVacancies()) {
          await _refreshExploreVacanciesLight();
        }
      }

      await _loadConversations(silent: true);
    } finally {
      _isRealtimeSyncInFlight = false;
    }
  }

  bool _shouldLightSyncExploreVacancies() {
    if (!_isCandidateAccount || _selectedIndex != 0) {
      return false;
    }
    if (_isLoadingExplore || _exploreError != null) {
      return false;
    }

    final DateTime now = DateTime.now();
    if (_lastExploreSyncAt == null) {
      return true;
    }
    return now.difference(_lastExploreSyncAt!).inSeconds >= 45;
  }

  Future<void> _refreshExploreVacanciesLight() async {
    try {
      final List<VacancyModel> latest = await _vacancyService.getExploreVacancies(
        jwt: widget.jwt,
        limit: 20,
      );

      if (!mounted) {
        return;
      }

      final Map<int, VacancyModel> mergedById = <int, VacancyModel>{
        for (final VacancyModel item in _exploreVacancies) item.id: item,
      };
      for (final VacancyModel item in latest) {
        mergedById[item.id] = item;
      }

      _lastExploreSyncAt = DateTime.now();
      setState(() {
        _exploreVacancies = mergedById.values.toList(growable: false);
        if (_exploreVacancies.isNotEmpty) {
          _showingFallbackVacancies = false;
        }
      });
    } catch (_) {
      _lastExploreSyncAt = DateTime.now();
    }
  }

  bool _shouldAutoRefreshExploreVacancies() {
    return _isCandidateAccount &&
        _selectedIndex == 0 &&
        !_isLoadingExplore &&
        _exploreError == null &&
        _exploreVacancies.isEmpty;
  }

  void _startExploreEmptyAutoRefreshLoop() {
    _exploreEmptyAutoRefreshTicker?.cancel();
    _exploreEmptyAutoRefreshTicker = Timer.periodic(
      const Duration(seconds: 45),
      (_) {
        if (!mounted) {
          return;
        }
        if (_shouldAutoRefreshExploreVacancies()) {
          unawaited(_loadRecommendedVacancies());
        }
      },
    );
  }
}

class CompanyRejectionScreen extends StatefulWidget {
  const CompanyRejectionScreen({
    super.key,
    required this.candidateName,
    required this.vacancyForm,
    this.aiSummary,
  });

  final String candidateName;
  final VacancyFormData vacancyForm;
  final String? aiSummary;

  @override
  State<CompanyRejectionScreen> createState() => _CompanyRejectionScreenState();
}

class _CompanyRejectionScreenState extends State<CompanyRejectionScreen> {
  static const List<String> _reasonOptions = <String>[
    'Experiencia insuficiente',
    'Perfil tecnico incompleto',
    'No cumple habilidades blandas',
    'Desalineacion cultural',
    'Compensacion fuera de rango',
    'Otro',
  ];

  late String _selectedReason;
  late String _selectedExperienceLevel;
  final Set<String> _missingTechnologies = <String>{};
  final Set<String> _missingResponsibilities = <String>{};
  final Set<String> _missingTechnicalRequirements = <String>{};
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedReason = _reasonOptions.first;
    _selectedExperienceLevel = widget.vacancyForm.experienceLevel;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String aiSummaryValue = (widget.aiSummary ?? '').trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Registrar rechazo'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.candidateName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Selecciona solo lo que realmente no cumplio.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedReason,
                decoration: const InputDecoration(
                  labelText: 'Motivo principal',
                  border: OutlineInputBorder(),
                ),
                items: _reasonOptions
                    .map(
                      (reason) => DropdownMenuItem<String>(
                        value: reason,
                        child: Text(reason),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _selectedReason = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              _buildChecklistSection(
                title: 'Tecnologias faltantes',
                options: widget.vacancyForm.technologies,
                selectedValues: _missingTechnologies,
                onToggle: (value, enabled) {
                  setState(() {
                    if (enabled) {
                      _missingTechnologies.add(value);
                    } else {
                      _missingTechnologies.remove(value);
                    }
                  });
                },
                emptyText: 'La vacante no tiene tecnologias registradas.',
              ),
              const SizedBox(height: 12),
              _buildChecklistSection(
                title: 'Responsabilidades no cumplidas',
                options: widget.vacancyForm.responsibilities,
                selectedValues: _missingResponsibilities,
                onToggle: (value, enabled) {
                  setState(() {
                    if (enabled) {
                      _missingResponsibilities.add(value);
                    } else {
                      _missingResponsibilities.remove(value);
                    }
                  });
                },
                emptyText:
                    'La vacante no tiene responsabilidades registradas.',
              ),
              const SizedBox(height: 12),
              _buildChecklistSection(
                title: 'Requisitos tecnicos no cumplidos',
                options: widget.vacancyForm.technicalRequirements,
                selectedValues: _missingTechnicalRequirements,
                onToggle: (value, enabled) {
                  setState(() {
                    if (enabled) {
                      _missingTechnicalRequirements.add(value);
                    } else {
                      _missingTechnicalRequirements.remove(value);
                    }
                  });
                },
                emptyText: 'La vacante no tiene requisitos tecnicos registrados.',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedExperienceLevel,
                decoration: const InputDecoration(
                  labelText: 'Nivel de experiencia requerido',
                  border: OutlineInputBorder(),
                ),
                items: const <MapEntry<String, String>>[
                  MapEntry<String, String>('JUNIOR', 'Junior'),
                  MapEntry<String, String>('SEMI_SENIOR', 'Semi-Senior'),
                  MapEntry<String, String>('SENIOR', 'Senior'),
                ]
                    .map(
                      (entry) => DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _selectedExperienceLevel = value;
                  });
                },
              ),
              if (aiSummaryValue.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resumen IA de comparacion',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        aiSummaryValue,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1E3A8A),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Comentario adicional',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(
                          CompanyDecisionPayload(
                            rejectionReason: _selectedReason,
                            missingTechnologies: _missingTechnologies.toList(
                              growable: false,
                            ),
                            missingResponsibilities:
                                _missingResponsibilities.toList(
                              growable: false,
                            ),
                            missingTechnicalRequirements:
                                _missingTechnicalRequirements.toList(
                              growable: false,
                            ),
                            expectedExperienceLevel: _selectedExperienceLevel,
                            aiSummary: aiSummaryValue,
                            rejectionComment: _commentController.text.trim(),
                          ),
                        );
                      },
                      child: const Text('Guardar rechazo'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildChecklistSection({
  required String title,
  required List<String> options,
  required Set<String> selectedValues,
  required void Function(String value, bool enabled) onToggle,
  required String emptyText,
}) {
  final List<String> cleanedOptions = options
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList(growable: false);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF334155),
        ),
      ),
      const SizedBox(height: 8),
      if (cleanedOptions.isEmpty)
        Text(
          emptyText,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        )
      else
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: cleanedOptions.map((option) {
            final bool selected = selectedValues.contains(option);
            return FilterChip(
              label: Text(option),
              selected: selected,
              onSelected: (enabled) => onToggle(option, enabled),
            );
          }).toList(growable: false),
        ),
    ],
  );
}
