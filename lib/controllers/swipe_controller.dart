import 'package:flutter/material.dart';

/// Resultado del swipe de una tarjeta
enum SwipeResult {
  like,      // Swipe a la derecha
  dislike,   // Swipe a la izquierda
  superLike, // Swipe arriba (opcional)
  none,      // Sin acción
}

/// Controlador para gestionar la lógica de swipe de tarjetas
class SwipeController extends ChangeNotifier {
  /// Umbrales de distancia para activar acciones (en píxeles)
  static const double swipeThreshold = 100.0;
  static const double rotationFactor = 0.12;

  /// Offset del arrastre actual
  Offset _dragOffset = Offset.zero;

  /// Rotación actual en radianes
  double _rotation = 0.0;

  /// Opacidad para los indicadores (like/dislike)
  double _likeOpacity = 0.0;
  double _dislikeOpacity = 0.0;

  /// Getters públicos
  Offset get dragOffset => _dragOffset;
  double get rotation => _rotation;
  double get likeOpacity => _likeOpacity;
  double get dislikeOpacity => _dislikeOpacity;

  /// Calcula si se alcanzó el umbral para ejecutar la acción
  bool get shouldSwipe => dragOffset.distance > swipeThreshold;

  /// Determina el resultado del swipe basado en el offset
  SwipeResult get swipeResult {
    if (!shouldSwipe) return SwipeResult.none;
    if (dragOffset.dx > 0) return SwipeResult.like;
    return SwipeResult.dislike;
  }

  /// Actualiza el offset del arrastre y calcula animaciones relacionadas
  void updateDragOffset(Offset offset) {
    _dragOffset = offset;

    // Rotación leve basada en desplazamiento vertical
    _rotation = offset.dy * rotationFactor;

    // Calcula opacidad para indicadores based on horizontal offset
    final distance = offset.dx.abs();
    final opacity = (distance / (swipeThreshold * 1.5)).clamp(0.0, 1.0);

    if (offset.dx > 0) {
      _likeOpacity = opacity;
      _dislikeOpacity = 0.0;
    } else {
      _likeOpacity = 0.0;
      _dislikeOpacity = opacity;
    }

    notifyListeners();
  }

  /// Resetea el controlador a su estado inicial
  void reset() {
    _dragOffset = Offset.zero;
    _rotation = 0.0;
    _likeOpacity = 0.0;
    _dislikeOpacity = 0.0;
    notifyListeners();
  }

  /// Fuerza el resultado del swipe (útil para botones)
  void forceSwipe(SwipeResult result) {
    switch (result) {
      case SwipeResult.like:
        _dragOffset = const Offset(300, 0);
        break;
      case SwipeResult.dislike:
        _dragOffset = const Offset(-300, 0);
        break;
      case SwipeResult.superLike:
        _dragOffset = const Offset(0, -300);
        break;
      case SwipeResult.none:
        reset();
    }
    notifyListeners();
  }
}
