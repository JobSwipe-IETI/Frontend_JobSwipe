import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/vacancy_model.dart';
import '../services/vacancy_service.dart';
import '../screens/vacancy_detail_screen.dart';

class AllVacanciesWidget extends StatefulWidget {
  const AllVacanciesWidget({
    super.key,
    required this.jwt,
    this.isPremium = false,
  });

  final String jwt;
  final bool isPremium;

  @override
  State<AllVacanciesWidget> createState() => _AllVacanciesWidgetState();
}

class _AllVacanciesWidgetState extends State<AllVacanciesWidget>
    with AutomaticKeepAliveClientMixin<AllVacanciesWidget> {
  final VacancyService _vacancyService = VacancyService();

  List<VacancyModel> _allVacancies = const [];
  List<VacancyModel> _filteredVacancies = const [];
  bool _isLoading = false;
  String? _error;

  String? _selectedExperienceLevel;
  String? _selectedSector;
  String? _selectedWorkType;

  final List<String> _experienceLevels = [
    'Junior',
    'Semi-Senior',
    'Senior',
  ];

  final List<String> _sectors = [
    'Tecnología',
    'Finanzas',
    'Salud',
    'Educación',
    'Retail',
    'Manufactura',
    'Consultoría',
  ];

  final List<String> _workTypes = [
    'Remoto',
    'Híbrido',
    'Presencial',
  ];

  @override
  void initState() {
    super.initState();
    _loadAllVacancies();
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _loadAllVacancies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final vacancies = await _vacancyService.getExploreVacancies(
        jwt: widget.jwt,
        limit: 100,
      );

      setState(() {
        _allVacancies = vacancies;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    _filteredVacancies = _allVacancies.where((vacancy) {
      final String combinedText =
          '${vacancy.title} ${vacancy.description} ${vacancy.location}'
              .toLowerCase();
      if (_selectedExperienceLevel != null &&
          _selectedExperienceLevel!.isNotEmpty) {
        final String normalizedExperience =
            _selectedExperienceLevel!.toLowerCase();
        bool matchesExperience = false;
        if (normalizedExperience.contains('junior')) {
          matchesExperience =
              combinedText.contains('junior') ||
              combinedText.contains('jr');
        } else if (normalizedExperience.contains('semi')) {
          matchesExperience =
              combinedText.contains('semi-senior') ||
              combinedText.contains('semi senior') ||
              combinedText.contains('semisenior') ||
              combinedText.contains('mid');
        } else if (normalizedExperience.contains('senior')) {
          matchesExperience =
              combinedText.contains('senior') &&
              !combinedText.contains('semi-senior') &&
              !combinedText.contains('semi senior');
        }
        if (!matchesExperience) {
          return false;
        }
      }

      if (_selectedSector != null && _selectedSector!.isNotEmpty) {
        // we don't have a dedicated sector field in VacancyModel; match against description
        if (!vacancy.description
            .toLowerCase()
            .contains(_selectedSector!.toLowerCase())) {
          return false;
        }
      }

      if (_selectedWorkType != null && _selectedWorkType!.isNotEmpty) {
        final wt = _selectedWorkType!.toLowerCase();
        final loc = vacancy.location.toLowerCase();
        final desc = vacancy.description.toLowerCase();
        final title = vacancy.title.toLowerCase();
        final String modalityText = '$title $loc $desc';

        bool matches = false;
        if (wt.contains('remoto') || wt.contains('remote')) {
          matches =
              modalityText.contains('remoto') ||
              modalityText.contains('remote');
        } else if (wt.contains('híbr') || wt.contains('hybrid')) {
          matches =
              modalityText.contains('híbrido') ||
              modalityText.contains('hibrido') ||
              modalityText.contains('hybrid');
        } else if (wt.contains('presencial')) {
          matches =
              modalityText.contains('presencial') ||
              modalityText.contains('on site') ||
              modalityText.contains('on-site');
        }

        if (!matches) return false;
      }

      return true;
    }).toList();
  }

  void _updateExperienceFilter(String? value) {
    setState(() {
      _selectedExperienceLevel = value;
      _applyFilters();
    });
  }

  void _updateSectorFilter(String? value) {
    setState(() {
      _selectedSector = value;
      _applyFilters();
    });
  }

  void _updateWorkTypeFilter(String? value) {
    setState(() {
      _selectedWorkType = value;
      _applyFilters();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedExperienceLevel = null;
      _selectedSector = null;
      _selectedWorkType = null;
      _applyFilters();
    });
  }

  Widget _buildFilterDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String?>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              color: JobSwipeTheme.primaryBlue.withValues(alpha: 0.78),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        DropdownButtonFormField<String?>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: 'Selecciona',
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: JobSwipeTheme.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: JobSwipeTheme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: JobSwipeTheme.primaryIndigo,
                width: 1.2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: JobSwipeTheme.primaryBlue.withValues(alpha: 0.8),
          ),
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      color: Colors.grey.shade50,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  JobSwipeTheme.primaryIndigo.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: JobSwipeTheme.borderColor),
              boxShadow: [
                BoxShadow(
                  color: JobSwipeTheme.primaryIndigo.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: JobSwipeTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Todas las Vacantes',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: JobSwipeTheme.primaryBlue,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Filtra por experiencia, sector o tipo de trabajo.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (_selectedExperienceLevel != null ||
                        _selectedSector != null ||
                        _selectedWorkType != null)
                      TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text('Limpiar'),
                        style: TextButton.styleFrom(
                          foregroundColor: JobSwipeTheme.primaryIndigo,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final filters = [
                      Expanded(
                        child: _buildFilterDropdown(
                          label: 'Experiencia',
                          value: _selectedExperienceLevel,
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Todas'),
                            ),
                            ..._experienceLevels
                                .map(
                                  (e) => DropdownMenuItem<String?>(
                                    value: e,
                                    child: Text(e, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                )
                                .toList(),
                          ],
                          onChanged: _updateExperienceFilter,
                        ),
                      ),
                      Expanded(
                        child: _buildFilterDropdown(
                          label: 'Sector',
                          value: _selectedSector,
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Todos'),
                            ),
                            ..._sectors
                                .map(
                                  (e) => DropdownMenuItem<String?>(
                                    value: e,
                                    child: Text(e, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                )
                                .toList(),
                          ],
                          onChanged: _updateSectorFilter,
                        ),
                      ),
                      Expanded(
                        child: _buildFilterDropdown(
                          label: 'Tipo',
                          value: _selectedWorkType,
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Todos'),
                            ),
                            ..._workTypes
                                .map(
                                  (e) => DropdownMenuItem<String?>(
                                    value: e,
                                    child: Text(e, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                )
                                .toList(),
                          ],
                          onChanged: _updateWorkTypeFilter,
                        ),
                      ),
                    ];

                    if (constraints.maxWidth < 620) {
                      return Column(
                        children: [
                          _buildFilterDropdown(
                            label: 'Experiencia',
                            value: _selectedExperienceLevel,
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Todas'),
                              ),
                              ..._experienceLevels
                                  .map(
                                    (e) => DropdownMenuItem<String?>(
                                      value: e,
                                      child: Text(e, maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ),
                                  )
                                  .toList(),
                            ],
                            onChanged: _updateExperienceFilter,
                          ),
                          const SizedBox(height: 12),
                          _buildFilterDropdown(
                            label: 'Sector',
                            value: _selectedSector,
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Todos'),
                              ),
                              ..._sectors
                                  .map(
                                    (e) => DropdownMenuItem<String?>(
                                      value: e,
                                      child: Text(e, maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ),
                                  )
                                  .toList(),
                            ],
                            onChanged: _updateSectorFilter,
                          ),
                          const SizedBox(height: 12),
                          _buildFilterDropdown(
                            label: 'Tipo',
                            value: _selectedWorkType,
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Todos'),
                              ),
                              ..._workTypes
                                  .map(
                                    (e) => DropdownMenuItem<String?>(
                                      value: e,
                                      child: Text(e, maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ),
                                  )
                                  .toList(),
                            ],
                            onChanged: _updateWorkTypeFilter,
                          ),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        filters[0],
                        const SizedBox(width: 12),
                        filters[1],
                        const SizedBox(width: 12),
                        filters[2],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadAllVacancies,
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 320,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 360,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error cargando vacantes',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadAllVacancies,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (_filteredVacancies.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 320,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_rounded,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No se encontraron vacantes con estos filtros',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _filteredVacancies.length,
      itemBuilder: (context, index) {
        final vacancy = _filteredVacancies[index];
        return _buildVacancyCard(vacancy);
      },
    );
  }

  Widget _buildVacancyCard(VacancyModel vacancy) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 56,
                    height: 56,
                    color: Colors.grey.shade200,
                      child: vacancy.logo.isNotEmpty
                        ? Image.network(
                            vacancy.logo,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Icon(Icons.business,
                                    color: Colors.grey.shade600),
                          )
                        : Icon(Icons.business, color: Colors.grey.shade600),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              vacancy.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (widget.isPremium)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7E6),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.amber.shade200),
                              ),
                              child: Text(
                                'PREMIUM',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.amber.shade800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vacancy.company,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: JobSwipeTheme.primaryIndigo
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              vacancy.badge,
                              style: TextStyle(
                                fontSize: 10,
                                color: JobSwipeTheme.primaryIndigo,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              // show inferred work type from location/description
                              (vacancy.location.toLowerCase().contains('remote') || vacancy.description.toLowerCase().contains('remoto') || vacancy.description.toLowerCase().contains('remote')) ? 'Remoto' : 'On-site',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              vacancy.description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on_rounded,
                        size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      vacancy.location,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Text(
                  vacancy.salary,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: JobSwipeTheme.primaryIndigo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => VacancyDetailScreen(
                            vacancyId: vacancy.id,
                            jwt: widget.jwt,
                            initialVacancy: vacancy,
                          ),
                        ),
                      );
                    },
                    child: const Text('Ver Detalle'),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await _vacancyService.registerSwipeDecision(
                        jwt: widget.jwt,
                        vacancyId: vacancy.id,
                        decision: SwipeDecision.like,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Postulaste correctamente')),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al postular: $e')),
                      );
                    }
                  },
                  child: const Text('Postular'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
