import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../controllers/user_provider.dart';
import 'create_vacancy_screen.dart';
import 'employer_vacancies_screen.dart';

class EmployerVacanciesTabScreen extends StatefulWidget {
  const EmployerVacanciesTabScreen({
    super.key,
    required this.userProvider,
    required this.jwt,
    this.onVacancySaved,
  });

  final UserProvider userProvider;
  final String jwt;
  final VoidCallback? onVacancySaved;

  @override
  State<EmployerVacanciesTabScreen> createState() =>
      _EmployerVacanciesTabScreenState();
}

class _EmployerVacanciesTabScreenState extends State<EmployerVacanciesTabScreen>
    with
        SingleTickerProviderStateMixin,
    AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  int _misVacantesRefreshTick = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _requestMisVacantesRefresh() {
    if (!mounted) {
      return;
    }
    setState(() {
      _misVacantesRefreshTick++;
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            indicatorColor: JobSwipeTheme.primaryIndigo,
            labelColor: JobSwipeTheme.primaryIndigo,
            unselectedLabelColor: Colors.grey.shade600,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
            tabs: const [
              Tab(text: 'Nueva Vacante'),
              Tab(text: 'Mis Vacantes'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              CreateVacancySection(
                jwt: widget.jwt,
                userProvider: widget.userProvider,
                onVacancySaved: () {
                  if (!mounted) {
                    return;
                  }
                  _tabController.animateTo(1);
                  _requestMisVacantesRefresh();
                  widget.onVacancySaved?.call();
                },
              ),
              EmployerVacanciesScreen(
                userProvider: widget.userProvider,
                jwt: widget.jwt,
                refreshTick: _misVacantesRefreshTick,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
