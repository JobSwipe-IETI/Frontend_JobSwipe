import 'package:flutter/material.dart';
import '../models/vacancy_model.dart';
import '../controllers/swipe_controller.dart';
import 'swipe_card.dart';
import 'match_dialog.dart';

/// Callback cuando una tarjeta fue descartada
typedef OnCardSwiped = void Function(VacancyModel vacancy, SwipeResult result);

/// Widget principal que gestiona un stack de tarjetas con soporte para swipe
class SwipeCardsStack extends StatefulWidget {
  /// Lista de vacantes a mostrar
  final List<VacancyModel> vacancies;

  /// Callback cuando una tarjeta es descartada
  final OnCardSwiped? onCardSwiped;

  /// Callback cuando no hay más tarjetas
  final VoidCallback? onStackEmpty;

  /// Duración de la animación de regreso
  final Duration returnAnimationDuration;

  /// Duración de la animación de salida
  final Duration exitAnimationDuration;

  const SwipeCardsStack({
    super.key,
    required this.vacancies,
    this.onCardSwiped,
    this.onStackEmpty,
    this.returnAnimationDuration = const Duration(milliseconds: 400),
    this.exitAnimationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<SwipeCardsStack> createState() => _SwipeCardsStackState();
}

class _SwipeCardsStackState extends State<SwipeCardsStack>
    with TickerProviderStateMixin {
  late List<VacancyModel> _remainingVacancies;
  late SwipeController _swipeController;
  late AnimationController _exitAnimationController;
  late AnimationController _returnAnimationController;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _remainingVacancies = List.from(widget.vacancies);
    _swipeController = SwipeController();

    // Controlador para animación de salida rápida
    _exitAnimationController = AnimationController(
      duration: widget.exitAnimationDuration,
      vsync: this,
    );

    // Controlador para animación de regreso suave
    _returnAnimationController = AnimationController(
      duration: widget.returnAnimationDuration,
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(covariant SwipeCardsStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vacancies != widget.vacancies) {
      setState(() {
        _remainingVacancies = List.from(widget.vacancies);
      });
      _swipeController.reset();
      _exitAnimationController.reset();
      _returnAnimationController.reset();
      _isAnimating = false;
    }
  }

  @override
  void dispose() {
    _swipeController.dispose();
    _exitAnimationController.dispose();
    _returnAnimationController.dispose();
    super.dispose();
  }

  /// Maneja el movimiento del drag
  void _handleDragUpdate(DragUpdateDetails details) {
    _swipeController.updateDragOffset(
      _swipeController.dragOffset + details.delta,
    );
  }

  /// Maneja el final del drag
  void _handleDragEnd(DragEndDetails details) {
    if (_isAnimating) return;

    if (_swipeController.shouldSwipe) {
      _performSwipe(_swipeController.swipeResult);
    } else {
      _returnToPreviousPosition();
    }
  }

  /// Ejecuta el swipe (descarta la tarjeta)
  Future<void> _performSwipe(SwipeResult result) async {
    _isAnimating = true;

    if (_remainingVacancies.isEmpty) {
      _isAnimating = false;
      return;
    }

    final currentVacancy = _remainingVacancies.first;

    // Fuerza el offset final para animación de salida
    _swipeController.forceSwipe(result);

    // Anima la salida
    _exitAnimationController.forward().then((_) {
      if (mounted) {
        // Callback
        widget.onCardSwiped?.call(currentVacancy, result);

        // Elimina de la lista
        setState(() {
          _remainingVacancies.removeAt(0);
        });

        if (_remainingVacancies.isEmpty) {
          widget.onStackEmpty?.call();
        }

        // Resetea controllers
        _swipeController.reset();
        _exitAnimationController.reset();
        _isAnimating = false;

        // Muestra match dialog si es un like
        if (result == SwipeResult.like) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return MatchDialog(
                    vacancy: currentVacancy,
                    onGoToChat: () {
                      // TODO: Navegar a pantalla de chat
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('💬 Abriendo chat...'),
                          duration: Duration(milliseconds: 800),
                        ),
                      );
                    },
                    onContinueExploring: () {
                      // Ya está continuando el flujo normal
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('📂 Continuando con las siguientes tarjetas...'),
                          duration: Duration(milliseconds: 800),
                        ),
                      );
                    },
                  );
                },
              );
            }
          });
        }
      }
    });
  }

  /// Regresa la tarjeta a su posición original
  Future<void> _returnToPreviousPosition() async {
    _isAnimating = true;

    // Anima el regreso
    _returnAnimationController.forward().then((_) {
      if (mounted) {
        _swipeController.reset();
        _returnAnimationController.reset();
        _isAnimating = false;
      }
    }).catchError((_) {
      _isAnimating = false;
    });
  }

  /// Constructor de animación para el retorno
  Widget _buildReturnAnimation(BuildContext context, child) {
    final animation = Tween<Offset>(
      begin: _swipeController.dragOffset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _returnAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    final rotationAnimation = Tween<double>(
      begin: _swipeController.rotation,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _returnAnimationController,
        curve: Curves.easeOut,
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translate(animation.value.dx, animation.value.dy)
            ..rotateZ(rotationAnimation.value),
          child: child,
        );
      },
      child: child,
    );
  }

  /// Constructor de animación para la salida
  Widget _buildExitAnimation(BuildContext context, child) {
    final scaleAnimation = Tween<double>(begin: 1.0, end: 0.6).animate(
      CurvedAnimation(parent: _exitAnimationController, curve: Curves.easeInCubic),
    );

    final opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitAnimationController, curve: Curves.easeIn),
    );

    final rotationAnimation = Tween<double>(
      begin: _swipeController.rotation,
      end: _swipeController.dragOffset.dx > 0 ? 0.8 : -0.8,
    ).animate(
      CurvedAnimation(parent: _exitAnimationController, curve: Curves.easeInCubic),
    );

    return AnimatedBuilder(
      animation: _exitAnimationController,
      builder: (context, _) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translate(
              _swipeController.dragOffset.dx * (1 + _exitAnimationController.value),
              _swipeController.dragOffset.dy,
            )
            ..rotateZ(rotationAnimation.value),
          child: Transform.scale(
            scale: scaleAnimation.value,
            child: Opacity(
              opacity: opacityAnimation.value,
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }

  /// Muestra información detallada de la vacante
  void _showVacancyInfo(VacancyModel vacancy) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
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
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                              Text(
                                vacancy.company,
                                style: TextStyle(
                                  fontSize: 14,
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
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${vacancy.matchPercentage.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 1,
                      color: Colors.grey.shade200,
                    ),
                    const SizedBox(height: 20),
                    _buildInfoSection('📍 Ubicación', vacancy.location),
                    const SizedBox(height: 16),
                    _buildInfoSection('💰 Salario', vacancy.salary),
                    const SizedBox(height: 16),
                    _buildInfoSection('📋 Descripción', vacancy.description),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: Navigator.of(context).pop,
                            icon: const Icon(Icons.close_rounded),
                            label: const Text('Cerrar'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: Color(0xFFEF4444)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _performSwipe(SwipeResult.like);
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(Icons.favorite_rounded),
                            label: const Text('Aplicar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Widget helper para mostrar información
  Widget _buildInfoSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 13,
            height: 1.6,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    if (_remainingVacancies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay más vacantes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vuelve mañana para más oportunidades',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onPanUpdate: _handleDragUpdate,
      onPanEnd: _handleDragEnd,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Renderiza las tarjetas en reversa para que la primera esté al frente
          ..._remainingVacancies.asMap().entries.toList().reversed.map((entry) {
            final index = entry.key;
            final vacancy = entry.value;
            final isOnTop = index == 0;
            
            // Calcula el desplazamiento y escala para efecto de stack/baraja
            final offsetY = isOnTop ? 0.0 : (index * 12.0).toDouble();
            final scale = isOnTop ? 1.0 : (1.0 - (index * 0.04));
            final opacity = isOnTop ? 1.0 : (1.0 - (index * 0.08)).clamp(0.7, 1.0);

            return Positioned(
              top: offsetY,
              left: 20,
              right: 20,
              height: screenSize.height * 0.7,
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: isOnTop && _returnAnimationController.isAnimating
                      ? _buildReturnAnimation(
                          context,
                          _buildExitAnimation(
                            context,
                            SwipeCard(
                              key: ValueKey<String>('swipe-card-${vacancy.id}'),
                              vacancy: vacancy,
                              dragOffset: _swipeController.dragOffset,
                              rotation: _swipeController.rotation,
                              likeOpacity: _swipeController.likeOpacity,
                              dislikeOpacity: _swipeController.dislikeOpacity,
                              isOnTop: isOnTop,
                              onLike: () => _performSwipe(SwipeResult.like),
                              onDislike: () => _performSwipe(SwipeResult.dislike),
                              onInfo: isOnTop ? () => _showVacancyInfo(vacancy) : null,
                            ),
                          ),
                        )
                      : isOnTop && _exitAnimationController.isAnimating
                          ? _buildExitAnimation(
                              context,
                              SwipeCard(
                                key: ValueKey<String>('swipe-card-${vacancy.id}'),
                                vacancy: vacancy,
                                dragOffset: _swipeController.dragOffset,
                                rotation: _swipeController.rotation,
                                likeOpacity: _swipeController.likeOpacity,
                                dislikeOpacity: _swipeController.dislikeOpacity,
                                isOnTop: isOnTop,
                                onLike: () => _performSwipe(SwipeResult.like),
                                onDislike: () => _performSwipe(SwipeResult.dislike),
                                onInfo: isOnTop ? () => _showVacancyInfo(vacancy) : null,
                              ),
                            )
                          : SwipeCard(
                              key: ValueKey<String>('swipe-card-${vacancy.id}'),
                              vacancy: vacancy,
                              dragOffset: isOnTop ? _swipeController.dragOffset : Offset.zero,
                              rotation: isOnTop ? _swipeController.rotation : 0.0,
                              likeOpacity: isOnTop ? _swipeController.likeOpacity : 0.0,
                              dislikeOpacity: isOnTop ? _swipeController.dislikeOpacity : 0.0,
                              isOnTop: isOnTop,
                              onLike: () => _performSwipe(SwipeResult.like),
                              onDislike: () => _performSwipe(SwipeResult.dislike),
                              onInfo: isOnTop ? () => _showVacancyInfo(vacancy) : null,
                            ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
