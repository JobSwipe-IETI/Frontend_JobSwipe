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
  final String? professionalTitle;
  final String profileImageUrl;
  final String bannerImageUrl;
  final String description;
  final String? phoneNumber;
  final String? skills;
  final String? experience;
  final String? education;
  final String? location; // Para candidatos
  final String? nationality;
  final String? languages;
  final double? expectedSalary;
  final String? availability;
  final String? portfolioUrl;
  final String? cvUrl;
  final String? companyName; // Para empresas
  final String? companyDescription;
  final String? legalId;
  final String? industry;
  final String? companySize;
  final String? website; // Para empresas
  final String? headquartersLocation;
  final String? hiringContactName;
  final String? hiringContactEmail;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.userType,
    this.professionalTitle,
    required this.profileImageUrl,
    required this.bannerImageUrl,
    required this.description,
    this.phoneNumber,
    this.skills,
    this.experience,
    this.education,
    this.location,
    this.nationality,
    this.languages,
    this.expectedSalary,
    this.availability,
    this.portfolioUrl,
    this.cvUrl,
    this.companyName,
    this.companyDescription,
    this.legalId,
    this.industry,
    this.companySize,
    this.website,
    this.headquartersLocation,
    this.hiringContactName,
    this.hiringContactEmail,
    required this.createdAt,
  });

  /// Copia el perfil con nuevos valores
  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    UserType? userType,
    String? professionalTitle,
    String? profileImageUrl,
    String? bannerImageUrl,
    String? description,
    String? phoneNumber,
    String? skills,
    String? experience,
    String? education,
    String? location,
    String? nationality,
    String? languages,
    double? expectedSalary,
    String? availability,
    String? portfolioUrl,
    String? cvUrl,
    String? companyName,
    String? companyDescription,
    String? legalId,
    String? industry,
    String? companySize,
    String? website,
    String? headquartersLocation,
    String? hiringContactName,
    String? hiringContactEmail,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      userType: userType ?? this.userType,
      professionalTitle: professionalTitle ?? this.professionalTitle,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      description: description ?? this.description,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      skills: skills ?? this.skills,
      experience: experience ?? this.experience,
      education: education ?? this.education,
      location: location ?? this.location,
      nationality: nationality ?? this.nationality,
      languages: languages ?? this.languages,
      expectedSalary: expectedSalary ?? this.expectedSalary,
      availability: availability ?? this.availability,
      portfolioUrl: portfolioUrl ?? this.portfolioUrl,
      cvUrl: cvUrl ?? this.cvUrl,
      companyName: companyName ?? this.companyName,
      companyDescription: companyDescription ?? this.companyDescription,
      legalId: legalId ?? this.legalId,
      industry: industry ?? this.industry,
      companySize: companySize ?? this.companySize,
      website: website ?? this.website,
      headquartersLocation: headquartersLocation ?? this.headquartersLocation,
      hiringContactName: hiringContactName ?? this.hiringContactName,
      hiringContactEmail: hiringContactEmail ?? this.hiringContactEmail,
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

  static UserProfile mockCompanyProfile() {
    return UserProfile(
      id: '2',
      name: 'Tech Company Inc',
      email: 'hr@techcompany.com',
      userType: UserType.company,
      professionalTitle: 'Tech Company Inc',
      profileImageUrl: 'https://via.placeholder.com/150?text=Tech',
      bannerImageUrl: 'https://via.placeholder.com/600x200?text=CompanyBanner',
      description: 'Buscamos los mejores talentos en tecnología',
      nationality: 'Colombia',
      companyName: 'Tech Company Inc',
      companyDescription: 'Empresa de tecnología y desarrollo de software',
      legalId: '900123456-7',
      industry: 'Software',
      companySize: '120 colaboradores',
      website: 'www.techcompany.com',
      headquartersLocation: 'Bogotá, Colombia',
      hiringContactName: 'Ana HR',
      hiringContactEmail: 'hr@techcompany.com',
      createdAt: DateTime.now(),
    );
  }
}
