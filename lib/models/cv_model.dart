// models/cv_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cv_builder/models/education_model.dart';
import 'package:cv_builder/models/experience_model.dart';
import 'package:cv_builder/models/project_model.dart';
import 'package:cv_builder/models/user_model.dart';

class CVModel {
  final String id;
  final String userId;
  final String cvTitle;
  final PersonalInfo personalInfo;
  final List<Education> education;
  final List<Experience> experience;
  final List<String> skills;
  final List<Project> projects;
  final String? summary;
  final String templateId; // 'classic' or 'modern'
  final DateTime createdAt;
  final DateTime updatedAt;

  CVModel({
    required this.id,
    required this.userId,
    required this.cvTitle,
    required this.personalInfo,
    required this.education,
    required this.experience,
    required this.skills,
    required this.projects,
    this.summary,
    required this.templateId,
    required this.createdAt,
    required this.updatedAt,
  });

  // ✅ Convert to Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'cvTitle': cvTitle,
      'personalInfo': personalInfo.toMap(),
      'education': education.map((e) => e.toMap()).toList(),
      'experience': experience.map((e) => e.toMap()).toList(),
      'skills': skills,
      'projects': projects.map((p) => p.toMap()).toList(),
      'summary': summary,
      'templateId': templateId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // ✅ Create from Firestore Document
  factory CVModel.fromMap(Map<String, dynamic> map) {
    return CVModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      cvTitle: map['cvTitle'] ?? '',
      personalInfo: PersonalInfo.fromMap(map['personalInfo']),
      education: (map['education'] as List)
          .map((e) => Education.fromMap(e))
          .toList(),
      experience: (map['experience'] as List)
          .map((e) => Experience.fromMap(e))
          .toList(),
      skills: List<String>.from(map['skills'] ?? []),
      projects: (map['projects'] as List)
          .map((p) => Project.fromMap(p))
          .toList(),
      summary: map['summary'],
      templateId: map['templateId'] ?? 'classic',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  // ✅ CopyWith for easy updates
  CVModel copyWith({
    String? cvTitle,
    PersonalInfo? personalInfo,
    List<Education>? education,
    List<Experience>? experience,
    List<String>? skills,
    List<Project>? projects,
    String? summary,
    String? templateId,
  }) {
    return CVModel(
      id: id,
      userId: userId,
      cvTitle: cvTitle ?? this.cvTitle,
      personalInfo: personalInfo ?? this.personalInfo,
      education: education ?? this.education,
      experience: experience ?? this.experience,
      skills: skills ?? this.skills,
      projects: projects ?? this.projects,
      summary: summary ?? this.summary,
      templateId: templateId ?? this.templateId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
