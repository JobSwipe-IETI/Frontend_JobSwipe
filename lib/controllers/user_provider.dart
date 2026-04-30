import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

/// Provider para gestionar el estado del usuario
class UserProvider extends ChangeNotifier {
  UserProfile _currentUser;

  UserProvider({required UserProfile initialUser}) : _currentUser = initialUser;

  /// Obtiene el usuario actual
  UserProfile get currentUser => _currentUser;

  /// Obtiene el tipo de usuario actual
  UserType get userType => _currentUser.userType;

  /// Obtiene si el usuario actual es un candidato
  bool get isCandidate => _currentUser.userType == UserType.candidate;

  /// Obtiene si el usuario actual es una empresa
  bool get isCompany => _currentUser.userType == UserType.company;

  /// Reemplaza el perfil actual con datos cargados desde backend
  void setUser(UserProfile user) {
    _currentUser = user;
    notifyListeners();
  }

  /// Actualiza datos del perfil (nombre, descripción, etc)
  void updateProfile({
    required String name,
    required String description,
    String? location,
    String? companyName,
    String? website,
    String? profileImageUrl,
    String? bannerImageUrl,
  }) {
    _currentUser = _currentUser.copyWith(
      name: name,
      description: description,
      location: location,
      companyName: companyName,
      website: website,
      profileImageUrl: profileImageUrl,
      bannerImageUrl: bannerImageUrl,
    );
    notifyListeners();
  }

  /// Actualiza solo la foto de perfil
  void updateProfileImage(String imageUrl) {
    _currentUser = _currentUser.copyWith(profileImageUrl: imageUrl);
    notifyListeners();
  }

  /// Actualiza solo el banner
  void updateBannerImage(String imageUrl) {
    _currentUser = _currentUser.copyWith(bannerImageUrl: imageUrl);
    notifyListeners();
  }

  /// Obtiene un resumen del perfil para visualización
  String get displayName => _currentUser.userType == UserType.candidate
      ? _currentUser.name
      : _currentUser.companyName ?? _currentUser.name;

  /// Obtiene la descripción del perfil
  String get displayDescription => _currentUser.description;

  /// Obtiene la ubicación o website dependiendo del tipo
  String? get displayLocation =>
      _currentUser.userType == UserType.candidate
          ? _currentUser.location
          : _currentUser.website;

  /// Actualiza el estado premium del usuario
  void updateUserPremiumStatus(bool isPremium) {
    _currentUser = _currentUser.copyWith(isPremium: isPremium);
    notifyListeners();
  }
}
