import 'package:flutter/material.dart';
import '../config/theme.dart';

class VacancyDetailScreen extends StatefulWidget {
  final int vacancyId;
  final String title;
  final String company;
  final String location;
  final String salary;
  final double matchPercentage;

  const VacancyDetailScreen({
    super.key,
    required this.vacancyId,
    required this.title,
    required this.company,
    required this.location,
    required this.salary,
    required this.matchPercentage,
  });

  @override
  State<VacancyDetailScreen> createState() => _VacancyDetailScreenState();
}

class _VacancyDetailScreenState extends State<VacancyDetailScreen> {
  bool isSaved = false;
  bool isLiked = false;

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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                                          widget.company,
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
                                          '${widget.matchPercentage.toStringAsFixed(0)}%',
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
                                  widthFactor: widget.matchPercentage / 100,
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
                                    widget.title,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.company,
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
                                        label: widget.location,
                                      ),
                                      _buildQuickTag(
                                        icon: Icons.home_work_rounded,
                                        label: '100% Remoto',
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
                                      widget.salary,
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
                                    'Únete al equipo de ingeniería de Google para construir interfaces de próxima generación usando React y TypeScript. Trabajarás en productos que impactan a millones de usuarios.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                      height: 1.6,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  // Key Requirements
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'REQUISITOS CLAVE',
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
                                        children: [
                                          _buildRequirementTag('React'),
                                          _buildRequirementTag('TypeScript'),
                                          _buildRequirementTag('3+ años'),
                                          _buildRequirementTag('GraphQL'),
                                          _buildRequirementTag('Node.js'),
                                        ],
                                      ),
                                    ],
                                  ),
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
              // Bottom Action Buttons
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    16 + MediaQuery.of(context).padding.bottom,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 24,
                    children: [
                      // Discard Button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFEF4444),
                              width: 3,
                            ),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            color: const Color(0xFFEF4444),
                            size: 32,
                          ),
                        ),
                      ),
                      // Like Button
                      GestureDetector(
                        onTap: () {
                          setState(() => isLiked = !isLiked);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isLiked ? '¡Te encanta esta oferta!' : 'Quitado de favoritos',
                              ),
                              backgroundColor: isLiked
                                  ? const Color(0xFF10B981)
                                  : Colors.grey.shade600,
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.all(16),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isLiked
                                ? const Color(0xFF10B981)
                                : const Color(0xFF10B981).withOpacity(0.1),
                          ),
                          child: Icon(
                            isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      // Info Button
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Más información disponible'),
                              behavior: SnackBarBehavior.floating,
                              margin: EdgeInsets.all(16),
                              duration: Duration(milliseconds: 800),
                            ),
                          );
                        },
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF06B6D4),
                              width: 3,
                            ),
                          ),
                          child: Icon(
                            Icons.info_outline_rounded,
                            color: const Color(0xFF06B6D4),
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
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
          _buildSectionTitle('Descripción Completa'),
          const SizedBox(height: 12),
          Text(
            'En esta posición, serás responsable de desarrollar y mantener aplicaciones web escalables utilizando tecnologías modernas. Trabajarás en un equipo colaborativo enfocado en la innovación y la excelencia técnica.\n\nBuscamos un profesional apasionado por la programación, con atención al detalle y capacidad de aprender tecnologías nuevas rápidamente. Serás parte de un equipo dinámico que valora la innovación.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.8,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 28),
          _buildSectionTitle('Beneficios'),
          const SizedBox(height: 12),
          _buildBenefitItem('Salario competitivo acorde a experiencia'),
          _buildBenefitItem('Seguro de salud integral'),
          _buildBenefitItem('Home office 100% con flexibilidad'),
          _buildBenefitItem('Capacitación continua'),
          _buildBenefitItem('Bono anual por desempeño'),
        ],
      ),
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
