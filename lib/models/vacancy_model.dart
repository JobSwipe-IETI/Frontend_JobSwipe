/// Modelo de datos para una vacante
class VacancyModel {
  final int id;
  final String title;
  final String company;
  final String location;
  final String salary;
  final double? matchPercentage;
  final String badge;
  final String description;
  final String logo;
  final bool isActive;
  final DateTime? createdAt;

  VacancyModel({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.salary,
    required this.matchPercentage,
    required this.badge,
    required this.description,
    required this.logo,
    this.isActive = true,
    this.createdAt,
  });

  /// Crea una copia con valores modificados
  VacancyModel copyWith({
    int? id,
    String? title,
    String? company,
    String? location,
    String? salary,
    double? matchPercentage,
    bool clearMatchPercentage = false,
    String? badge,
    String? description,
    String? logo,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return VacancyModel(
      id: id ?? this.id,
      title: title ?? this.title,
      company: company ?? this.company,
      location: location ?? this.location,
      salary: salary ?? this.salary,
      matchPercentage: clearMatchPercentage
          ? null
          : (matchPercentage ?? this.matchPercentage),
      badge: badge ?? this.badge,
      description: description ?? this.description,
      logo: logo ?? this.logo,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
