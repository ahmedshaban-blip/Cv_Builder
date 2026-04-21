class Project {
  final String id;
  final String title;
  final String description;
  final String? link;
  final List<String> technologies;

  Project({
    required this.id,
    required this.title,
    required this.description,
    this.link,
    required this.technologies,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'link': link,
    'technologies': technologies,
  };

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      link: map['link'],
      technologies: List<String>.from(map['technologies'] ?? []),
    );
  }
}
