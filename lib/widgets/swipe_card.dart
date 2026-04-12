import 'package:flutter/material.dart';
import '../models/vacancy_model.dart';

/// Widget que representa una tarjeta individual de vacante
class SwipeCard extends StatelessWidget {
  final VacancyModel vacancy;
  final Offset dragOffset;
  final double rotation;
  final double likeOpacity;
  final double dislikeOpacity;
  final bool isOnTop;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;
  final VoidCallback? onInfo;

  const SwipeCard({
    super.key,
    required this.vacancy,
    required this.dragOffset,
    required this.rotation,
    required this.likeOpacity,
    required this.dislikeOpacity,
    this.isOnTop = false,
    this.onLike,
    this.onDislike,
    this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    final _BadgeStyle badgeStyle = _badgeStyle(vacancy.badge);

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..translate(dragOffset.dx, dragOffset.dy)
        ..setEntry(3, 2, 0.001)
        ..rotateZ(rotation),
      child: Opacity(
        opacity: isOnTop ? 1.0 : 0.8,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Título y compatibilidad
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      vacancy.title,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      vacancy.company,
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: badgeStyle.background,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: badgeStyle.border,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      vacancy.badge,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: badgeStyle.foreground,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${vacancy.matchPercentage.toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: badgeStyle.foreground,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Ubicación, Tipo y Salario
                          Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            children: [
                              _buildInfoChip(
                                icon: Icons.location_on_rounded,
                                label: vacancy.location,
                                color: const Color(0xFF3B82F6),
                              ),
                              _buildInfoChip(
                                icon: Icons.business_rounded,
                                label: 'Presencial',
                                color: const Color(0xFF10B981),
                              ),
                              _buildInfoChip(
                                icon: Icons.attach_money_rounded,
                                label: vacancy.salary,
                                color: const Color(0xFFEC4899),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(height: 1, color: Colors.grey.shade200),
                          const SizedBox(height: 16),

                          // Descripción
                          Text(
                            'Descripción',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6B7280),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            vacancy.description,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Requisitos/Tags
                          Text(
                            'REQUISITOS CLAVE',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6B7280),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildTag('Product Strategy'),
                              _buildTag('Data Analysis'),
                              _buildTag('Agile'),
                              _buildTag('5+ años'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.96),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: isOnTop ? onDislike : null,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFFEF2F2),
                                border: Border.all(
                                  color: const Color(0xFFEF4444),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Color(0xFFEF4444),
                                size: 28,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: isOnTop ? onInfo : null,
                            child: Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFEFFCFD),
                                border: Border.all(
                                  color: const Color(0xFF06B6D4),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.info_rounded,
                                color: Color(0xFF06B6D4),
                                size: 26,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: isOnTop ? onLike : null,
                            child: Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF1A237E), Color(0xFF7C4DFF)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF7C4DFF).withValues(alpha: 0.28),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.favorite_rounded,
                                color: Colors.white,
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

              // Indicador MATCH (arriba a la derecha)
              Positioned(
                top: 24,
                right: 24,
                child: AnimatedScale(
                  scale: likeOpacity,
                  duration: const Duration(milliseconds: 200),
                  child: AnimatedOpacity(
                    opacity: likeOpacity,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF10B981),
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'MATCH',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF10B981),
                          letterSpacing: 2.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Indicador SKIP (arriba a la izquierda)
              Positioned(
                top: 24,
                left: 24,
                child: AnimatedScale(
                  scale: dislikeOpacity,
                  duration: const Duration(milliseconds: 200),
                  child: AnimatedOpacity(
                    opacity: dislikeOpacity,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFEF4444),
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'SKIP',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFEF4444),
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  /// Widget helper para crear chips informativos
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          Icon(icon, size: 14, color: color),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Widget helper para crear tags
  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.25)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6366F1),
        ),
      ),
    );
  }

  _BadgeStyle _badgeStyle(String badge) {
    final String normalized = badge.toLowerCase();
    if (normalized.contains('alta')) {
      return const _BadgeStyle(
        background: Color(0x1A059669),
        border: Color(0xFF34D399),
        foreground: Color(0xFF047857),
      );
    }

    if (normalized.contains('recomendada')) {
      return const _BadgeStyle(
        background: Color(0x1A2563EB),
        border: Color(0xFF60A5FA),
        foreground: Color(0xFF1D4ED8),
      );
    }

    return const _BadgeStyle(
      background: Color(0x1AF59E0B),
      border: Color(0xFFFBBF24),
      foreground: Color(0xFFB45309),
    );
  }
}

class _BadgeStyle {
  const _BadgeStyle({
    required this.background,
    required this.border,
    required this.foreground,
  });

  final Color background;
  final Color border;
  final Color foreground;
}
