import 'dart:async';

import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../controllers/user_provider.dart';
import '../models/vacancy_model.dart';
import '../services/vacancy_service.dart';
import 'create_vacancy_screen.dart';

class EmployerVacanciesScreen extends StatefulWidget {
  const EmployerVacanciesScreen({
    super.key,
    required this.userProvider,
    required this.jwt,
    this.refreshTick = 0,
  });

  final UserProvider userProvider;
  final String jwt;
  final int refreshTick;

  @override
  State<EmployerVacanciesScreen> createState() =>
      _EmployerVacanciesScreenState();
}

class _EmployerVacanciesScreenState extends State<EmployerVacanciesScreen>
    with AutomaticKeepAliveClientMixin {
  final VacancyService _vacancyService = VacancyService();

  List<VacancyModel> _vacancies = const [];
  List<VacancyModel> _filteredVacancies = const [];
  bool _isLoading = true;
  final Set<int> _deletingVacancyIds = <int>{};
  String? _error;
  int _loadingStep = 0;
  Timer? _loadingTicker;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const List<String> _loadingMessages = <String>[
    'Cargando tus vacantes...',
    'Organizando tus publicaciones...',
    'Preparando la lista para edición...',
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadVacancies();
  }

  @override
  void didUpdateWidget(covariant EmployerVacanciesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshTick != oldWidget.refreshTick) {
      unawaited(_loadVacancies());
    }
  }

  @override
  void dispose() {
    _loadingTicker?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _startLoadingAnimation() {
    _loadingTicker?.cancel();
    _loadingStep = 0;
    _loadingTicker = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted || !_isLoading) return;
      setState(() {
        _loadingStep = (_loadingStep + 1) % _loadingMessages.length;
      });
    });
  }

  Future<void> _loadVacancies() async {
    _startLoadingAnimation();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final vacancies = await _vacancyService.getCompanyVacancies(
        jwt: widget.jwt,
      );

      if (!mounted) return;

      setState(() {
        _vacancies = vacancies;
        _applyFilters();
        _isLoading = false;
      });
    } on VacancyException catch (error) {
      if (!mounted) return;

      if (_isEmptyVacanciesScenario(error.message)) {
        setState(() {
          _vacancies = const <VacancyModel>[];
          _filteredVacancies = const <VacancyModel>[];
          _error = null;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _error = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'No se pudieron cargar tus vacantes en este momento.';
        _isLoading = false;
      });
    } finally {
      _loadingTicker?.cancel();
      _loadingTicker = null;
    }
  }

  bool _isEmptyVacanciesScenario(String message) {
    final String normalized = message.toLowerCase();
    return normalized.contains('404') ||
        normalized.contains('not found') ||
        normalized.contains('no hay') ||
        normalized.contains('sin vacantes') ||
        normalized.contains('vacante no fue encontrada');
  }

  void _applyFilters() {
    final String query = _searchQuery.trim().toLowerCase();

    _filteredVacancies = _vacancies.where((vacancy) {
      if (query.isNotEmpty) {
        final String haystack =
            '${vacancy.title} ${vacancy.company} ${vacancy.location} ${vacancy.description}'
                .toLowerCase();
        if (!haystack.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList(growable: false);
  }

  void _updateSearchQuery(String value) {
    setState(() {
      _searchQuery = value;
      _applyFilters();
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _applyFilters();
    });
  }

  Widget _buildFilterPanel() {
    final bool hasFilters = _searchQuery.isNotEmpty;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: JobSwipeTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: JobSwipeTheme.primaryIndigo.withValues(alpha: 0.05),
            blurRadius: 14,
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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: JobSwipeTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.manage_search_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filtros de vacantes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: JobSwipeTheme.primaryBlue,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Busca por nombre entre tus vacantes publicadas.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ],
                ),
              ),
              if (hasFilters)
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Limpiar'),
                ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              return _buildFilterTextField(
                label: 'Buscar por nombre',
                controller: _searchController,
                onChanged: _updateSearchQuery,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTextField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
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
        TextField(
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Escribe el cargo o palabra clave',
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
            ),
            prefixIcon: const Icon(Icons.search_rounded),
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
              borderSide: BorderSide(color: JobSwipeTheme.primaryIndigo, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _editVacancy(VacancyModel vacancy) async {
    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
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
                  'Cargando vacante...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Estamos trayendo todos los datos para abrir el editor listo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      final VacancyFormData vacancyData = await _vacancyService.getVacancyById(
        jwt: widget.jwt,
        vacancyId: vacancy.id,
      );

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: JobSwipeTheme.lightBg,
            appBar: AppBar(
              title: const Text('Editar Vacante'),
              centerTitle: true,
            ),
            body: SafeArea(
              child: CreateVacancySection(
                editingVacancyId: vacancy.id,
                initialVacancyData: vacancyData,
                jwt: widget.jwt,
                userProvider: widget.userProvider,
              ),
            ),
          ),
        ),
      );

      if (result == true && mounted) {
        await _loadVacancies();
      }
    } catch (error) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cargar la vacante: $error')),
      );
    }
  }

  Future<void> _deleteVacancy(VacancyModel vacancy) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar vacante'),
        content: Text(
          '¿Estás seguro de que deseas eliminar la vacante "${vacancy.title}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: JobSwipeTheme.errorRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (_deletingVacancyIds.contains(vacancy.id)) {
      return;
    }

    setState(() {
      _deletingVacancyIds.add(vacancy.id);
    });

    try {
      await _vacancyService.deleteVacancy(
        jwt: widget.jwt,
        vacancyId: vacancy.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vacante eliminada exitosamente.')),
        );
        await _loadVacancies();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _deletingVacancyIds.remove(vacancy.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: JobSwipeTheme.lightBg,
      appBar: AppBar(
        toolbarHeight: 0,
        elevation: 0,
        backgroundColor: JobSwipeTheme.lightBg,
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _loadVacancies,
        child: Builder(
          builder: (context) {
            if (_isLoading) {
              final String loadingMessage =
                  _loadingMessages[_loadingStep % _loadingMessages.length];
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildHeaderBanner(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.62,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 42,
                            height: 42,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            loadingMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Estamos preparando tus vacantes para mostrarlas sin interrupciones.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            if (_error != null) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildHeaderBanner(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.62,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: JobSwipeTheme.errorRed,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error al cargar vacantes',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _loadVacancies,
                            child: const Text('Intentar de nuevo'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            if (_vacancies.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildHeaderBanner(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.62,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.work_outline,
                            size: 64,
                            color: JobSwipeTheme.primaryIndigo.withOpacity(0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tienes vacantes aún',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Crea tu primera vacante para atraer candidatos',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
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
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildHeaderBanner(),
                  ),
                  _buildFilterPanel(),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.48,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 64,
                            color: JobSwipeTheme.primaryIndigo.withValues(alpha: 0.35),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay coincidencias con esos filtros',
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Prueba otro nombre o limpia la búsqueda.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount: _filteredVacancies.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildHeaderBanner(),
                  );
                }

                if (index == 1) {
                  return _buildFilterPanel();
                }

                return _buildVacancyCard(context, _filteredVacancies[index - 2]);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildVacancyCard(BuildContext context, VacancyModel vacancy) {
    final bool isDeleting = _deletingVacancyIds.contains(vacancy.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: JobSwipeTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: JobSwipeTheme.primaryIndigo.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vacancy.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: JobSwipeTheme.primaryIndigo,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: JobSwipeTheme.primaryIndigo,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      vacancy.location,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.attach_money_outlined,
                      size: 16,
                      color: JobSwipeTheme.successGreen,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      vacancy.salary,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: JobSwipeTheme.successGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(color: JobSwipeTheme.borderColor, height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editVacancy(vacancy),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: JobSwipeTheme.primaryIndigo,
                      side: const BorderSide(
                        color: JobSwipeTheme.primaryIndigo,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isDeleting ? null : () => _deleteVacancy(vacancy),
                    icon: isDeleting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline),
                    label: Text(isDeleting ? 'Eliminando...' : 'Eliminar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: JobSwipeTheme.errorRed,
                      side: const BorderSide(color: JobSwipeTheme.errorRed),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: JobSwipeTheme.primaryIndigo.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: JobSwipeTheme.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: JobSwipeTheme.primaryIndigo.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.view_list_rounded,
              color: JobSwipeTheme.primaryIndigo,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Administrar vacantes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: JobSwipeTheme.primaryIndigo,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Revisa, edita o elimina tus publicaciones sin salir del estilo visual de la app.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
