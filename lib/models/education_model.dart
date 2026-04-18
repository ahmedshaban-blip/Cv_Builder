class Education {
  final String id;
  final String institution;
  final String degree;
  final String fieldOfStudy;
  final String startDate;
  final String? endDate;
  final bool isCurrently;
  final String? gpa;

  Education({
    required this.id,
    required this.institution,
    required this.degree,
    required this.fieldOfStudy,
    required this.startDate,
    this.endDate,
    this.isCurrently = false,
    this.gpa,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'institution': institution,
    'degree': degree,
    'fieldOfStudy': fieldOfStudy,
    'startDate': startDate,
    'endDate': endDate,
    'isCurrently': isCurrently,
    'gpa': gpa,
  };

  factory Education.fromMap(Map<String, dynamic> map) {
    return Education(
      id: map['id'] ?? '',
      institution: map['institution'] ?? '',
      degree: map['degree'] ?? '',
      fieldOfStudy: map['fieldOfStudy'] ?? '',
      startDate: map['startDate'] ?? '',
      endDate: map['endDate'],
      isCurrently: map['isCurrently'] ?? false,
      gpa: map['gpa'],
    );
  }
}