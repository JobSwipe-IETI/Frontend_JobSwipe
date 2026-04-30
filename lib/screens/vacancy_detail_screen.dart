import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/vacancy_model.dart';
import '../services/vacancy_service.dart';

class VacancyDetailScreen extends StatefulWidget {
  final int vacancyId;
  final String jwt;
  final VacancyModel? initialVacancy;

  const VacancyDetailScreen({
    super.key,
    required this.vacancyId,
    required this.jwt,
    this.initialVacancy,
  });

  @override
  State<VacancyDetailScreen> createState() => _VacancyDetailScreenState();
}

class _VacancyDetailScreenState extends State<VacancyDetailScreen> {
  bool isSaved = false;
  bool isLiked = false;
  final VacancyService _vacancyService = VacancyService();
  VacancyFormData? _vacancy;
  bool _isLoading = true;
  bool _isApplying = false;
  bool _applied = false;

  bool get _showAiActive =>
      widget.initialVacancy?.logo == 'recommended';

  double? get _displayMatchPercentage => widget.initialVacancy?.matchPercentage;

  String get _displayMatchLabel {
    final double? score = _displayMatchPercentage;
    if (score != null) {
      return '${score.toStringAsFixed(0)}%';
    }
    if (_showAiActive) {
      return 'Analizando';
    }
    return '—';
  }

  double get _displayMatchProgress {
    final double? score = _displayMatchPercentage;
    if (score == null) {
      return _showAiActive ? 0.18 : 0.0;
    }
    return (score / 100).clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _loadVacancy();
  }

  String get _displayCompany =>
      _vacancy?.sector ?? widget.initialVacancy?.company ?? 'Empresa';

  String get _displayTitle =>
      _vacancy?.title ?? widget.initialVacancy?.title ?? 'Cargando vacante...';

  String get _displayLocation =>
      _vacancy?.location ?? widget.initialVacancy?.location ?? '';

  String get _displaySector => _vacancy?.sector ?? 'Otro';

  String get _displayModality => _mapModality(_vacancy?.modality);

  String get _displayEmploymentType =>
      _mapEmploymentType(_vacancy?.employmentType);

  String get _displayExperienceLevel =>
      _mapExperienceLevel(_vacancy?.experienceLevel);

  String get _displayDescription =>
      _vacancy?.description ??
      widget.initialVacancy?.description ??
      'Estamos cargando más información sobre esta vacante.';

  String get _displaySalary {
    if (_vacancy != null && _vacancy!.minSalary > 0) {
      return '\$${_vacancy!.minSalary.toStringAsFixed(0)} - \$${_vacancy!.maxSalary.toStringAsFixed(0)}';
    }
    return widget.initialVacancy?.salary ?? 'Salario no especificado';
  }

  bool get _hasInitialVacancy => widget.initialVacancy != null;

  List<String> get _displayTechnologies => _vacancy?.technologies ?? const [];

  List<String> get _displaySoftSkills => _vacancy?.softSkills ?? const [];

  List<String> get _displayResponsibilities =>
      _vacancy?.responsibilities ?? const [];

  List<String> get _displayTechnicalRequirements =>
      _vacancy?.technicalRequirements ?? const [];

  List<String> get _displayBenefits => _vacancy?.benefits ?? const [];

  String _mapModality(String? value) {
    switch (value) {
      case 'REMOTE':
        return 'Remoto';
      case 'HYBRID':
        return 'Híbrido';
      case 'ON_SITE':
        return 'Presencial';
      default:
        return 'Modalidad por definir';
    }
  }

  String _mapEmploymentType(String? value) {
    switch (value) {
      case 'FULL_TIME':
        return 'Tiempo completo';
      case 'PART_TIME':
        return 'Medio tiempo';
      case 'FREELANCE':
        return 'Freelance';
      case 'PROJECT_BASED':
        return 'Por proyecto';
      case 'IMMEDIATE':
        return 'Inmediata';
      case 'IN_15_DAYS':
        return 'En 15 días';
      case 'IN_30_DAYS':
        return 'En 30 días';
      default:
        return 'Tipo por definir';
    }
  }

  String _mapExperienceLevel(String? value) {
    switch (value) {
      case 'JUNIOR':
        return 'Junior';
      case 'SEMI_SENIOR':
        return 'Semi-Senior';
      case 'SENIOR':
        return 'Senior';
      default:
        return 'Experiencia por definir';
    }
  }

  Future<void> _loadVacancy() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final data = await _vacancyService.getVacancyById(
        jwt: widget.jwt,
        vacancyId: widget.vacancyId,
      );
      if (!mounted) return;
      setState(() {
        _vacancy = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando vacante: $e')),
      );
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
              JobSwipeTheme.primaryIndigo.withOpacity(0.04),
              const Color(0xFF1E3A8A).withOpacity(0.02),
              Colors.white,
            ],
            stops: const [0, 0.5, 1],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isLoading && _hasInitialVacancy) ...[
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: const LinearProgressIndicator(minHeight: 4),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Header Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              color: JobSwipeTheme.primaryIndigo,
                            ),
                          ),
                        ),
                        if (_showAiActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: JobSwipeTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              spacing: 6,
                              children: [
                                const Icon(
                                  Icons.bolt_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const Text(
                                  'IA activa',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Main Card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: JobSwipeTheme.primaryIndigo.withOpacity(0.12),
                              blurRadius: 25,
                              spreadRadius: 2,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Gradient Header
                            Container(
                              height: 120,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    JobSwipeTheme.primaryIndigo,
                                    JobSwipeTheme.primaryBlue,
                                  ],
                                ),
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Company Logo and Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.business_rounded,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _displayCompany,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Match Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFF10B981).withOpacity(0.4),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _displayMatchLabel,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF10B981),
                                          ),
                                        ),
                                        Text(
                                          'Compatibilidad',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF10B981).withOpacity(0.8),
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Progress Bar
                            Container(
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: FractionallySizedBox(
                                  widthFactor: _displayMatchProgress,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFF10B981),
                                          const Color(0xFF059669),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Content
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title
                                  Text(
                                    _displayTitle,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _displayCompany,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Quick Info Tags
                                  Row(
                                    spacing: 8,
                                    children: [
                                      _buildQuickTag(
                                        icon: Icons.location_on_rounded,
                                        label: _displayLocation,
                                      ),
                                      _buildQuickTag(
                                        icon: Icons.home_work_rounded,
                                        label: _displayModality,
                                      ),
                                      _buildQuickTag(
                                        icon: Icons.category_outlined,
                                        label: _displaySector,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Salary
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _displaySalary,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF92400E),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  // Description Preview
                                  Text(
                                    _displayDescription,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                      height: 1.6,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  _buildMetadataBlock(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Additional Details Section
                    _buildDetailSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickTag({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: JobSwipeTheme.primaryIndigo.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        spacing: 4,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: JobSwipeTheme.primaryIndigo,
            size: 14,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: JobSwipeTheme.primaryIndigo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: JobSwipeTheme.primaryIndigo.withOpacity(0.3),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: JobSwipeTheme.primaryIndigo,
        ),
      ),
    );
  }

  Widget _buildDetailSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: JobSwipeTheme.primaryIndigo.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Descripción completa'),
          const SizedBox(height: 12),
          Text(
            _displayDescription,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.8,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 28),
          _buildInfoListSection(
            title: 'Tecnologías requeridas',
            items: _displayTechnologies,
            emptyText: 'Esta vacante no tiene tecnologías registradas.',
          ),
          const SizedBox(height: 24),
          _buildInfoListSection(
            title: 'Habilidades blandas',
            items: _displaySoftSkills,
            emptyText: 'Esta vacante no tiene habilidades blandas registradas.',
          ),
          const SizedBox(height: 24),
          _buildInfoListSection(
            title: 'Responsabilidades',
            items: _displayResponsibilities,
            emptyText: 'Esta vacante no tiene responsabilidades registradas.',
            useBenefitStyle: true,
          ),
          const SizedBox(height: 24),
          _buildInfoListSection(
            title: 'Requisitos técnicos',
            items: _displayTechnicalRequirements,
            emptyText: 'Esta vacante no tiene requisitos técnicos registrados.',
            useBenefitStyle: true,
          ),
          const SizedBox(height: 24),
          _buildInfoListSection(
            title: 'Beneficios',
            items: _displayBenefits,
            emptyText: 'Esta vacante no tiene beneficios registrados.',
            useBenefitStyle: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataBlock() {
    final items = <String>[
      _displayEmploymentType,
      _displayExperienceLevel,
      _displaySector,
    ].where((item) => item.trim().isNotEmpty).toList(growable: false);

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DETALLES DE LA VACANTE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Colors.grey.shade600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map(_buildRequirementTag).toList(growable: false),
        ),
      ],
    );
  }

  Widget _buildInfoListSection({
    required String title,
    required List<String> items,
    required String emptyText,
    bool useBenefitStyle = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Text(
            emptyText,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          )
        else if (useBenefitStyle)
          ...items.map(_buildBenefitItem)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map(_buildRequirementTag).toList(growable: false),
          ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Color(0xFF6366F1),
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: const Color(0xFF10B981),
            size: 20,
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
