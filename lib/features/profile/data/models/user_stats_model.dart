class UserStatsModel {
  final int totalSignalements;
  final int totalFelicitations;
  final int totalResolus;
  final int enAttente;
  final int enCours;
  final int resolus;

  UserStatsModel({
    required this.totalSignalements,
    required this.totalFelicitations,
    required this.totalResolus,
    required this.enAttente,
    required this.enCours,
    required this.resolus,
  });

  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    return UserStatsModel(
      totalSignalements: json['totalSignalements'] ?? 0,
      totalFelicitations: json['totalFelicitations'] ?? 0,
      totalResolus: json['totalResolus'] ?? 0,
      enAttente: json['enAttente'] ?? 0,
      enCours: json['enCours'] ?? 0,
      resolus: json['resolus'] ?? 0,
    );
  }
}
