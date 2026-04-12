/// Enum para los tipos de usuario
enum UserType {
  candidate, // Candidato/Persona que busca trabajo
  company,   // Empresa/Persona que crea vacantes
}

/// Modelo para el perfil del usuario
class UserProfile {
  final String id;
  final String name;
  final String email;
  final UserType userType;
  final String profileImageUrl;
  final String bannerImageUrl;
  final String description;
  final String? location; // Para candidatos
  final String? companyName; // Para empresas
  final String? website; // Para empresas
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.userType,
    required this.profileImageUrl,
    required this.bannerImageUrl,
    required this.description,
    this.location,
    this.companyName,
    this.website,
    required this.createdAt,
  });

  /// Copia el perfil con nuevos valores
  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    UserType? userType,
    String? profileImageUrl,
    String? bannerImageUrl,
    String? description,
    String? location,
    String? companyName,
    String? website,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      userType: userType ?? this.userType,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      description: description ?? this.description,
      location: location ?? this.location,
      companyName: companyName ?? this.companyName,
      website: website ?? this.website,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Cambia el tipo de usuario
  UserProfile switchUserType() {
    return copyWith(
      userType: userType == UserType.candidate 
        ? UserType.company 
        : UserType.candidate,
    );
  }

  /// Obtiene un perfil mock para desarrollo
  static UserProfile mockCandidateProfile() {
    return UserProfile(
      id: '1',
      name: 'Alison Valverde',
      email: 'alison@example.com',
      userType: UserType.candidate,
      profileImageUrl: 'https://via.placeholder.com/150?text=Alison',
      bannerImageUrl: 'https://via.placeholder.com/600x200?text=Banner',
      description: 'Ingeniero Flutter apasionado por crear apps increíbles',
      location: 'Medellín, Colombia',
      createdAt: DateTime.now(),
    );
  }

  static UserProfile mockCompanyProfile() {
    return UserProfile(
      id: '2',
      name: 'Tech Company Inc',
      email: 'hr@techcompany.com',
      userType: UserType.company,
      profileImageUrl: 'https://via.placeholder.com/150?text=Tech',
      bannerImageUrl: 'https://via.placeholder.com/600x200?text=CompanyBanner',
      description: 'Buscamos los mejores talentos en tecnología',
      companyName: 'Tech Company Inc',
      website: 'www.techcompany.com',
      createdAt: DateTime.now(),
    );
  }
}
