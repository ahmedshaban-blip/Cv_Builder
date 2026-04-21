class Experience {
  final String id;
  final String company;
  final String position;
  final String startDate;
  final String? endDate;
  final bool isCurrently;
  final List<String> responsibilities;
  final String? location;

  Experience({
    required this.id,
    required this.company,
    required this.position,
    required this.startDate,
    this.endDate,
    this.isCurrently = false,
    required this.responsibilities,
    this.location,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'company': company,
    'position': position,
    'startDate': startDate,
    'endDate': endDate,
    'isCurrently': isCurrently,
    'responsibilities': responsibilities,
    'location': location,
  };

  factory Experience.fromMap(Map<String, dynamic> map) {
    return Experience(
      id: map['id'] ?? '',
      company: map['company'] ?? '',
      position: map['position'] ?? '',
      startDate: map['startDate'] ?? '',
      endDate: map['endDate'],
      isCurrently: map['isCurrently'] ?? false,
      responsibilities: List<String>.from(map['responsibilities'] ?? []),
      location: map['location'],
    );
  }
}
