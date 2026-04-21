// providers/cv_provider.dart
import 'package:cv_builder/models/education_model.dart';
import 'package:cv_builder/models/experience_model.dart';
import 'package:cv_builder/models/project_model.dart';
import 'package:cv_builder/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/cv_model.dart';
import '../services/firestore_service.dart';

class CVProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final Uuid _uuid = const Uuid();

  // ── Current CV being built/edited ──
  CVModel? _currentCV;
  CVModel? get currentCV => _currentCV;

  // ── All user CVs ──
  List<CVModel> _userCVs = [];
  List<CVModel> get userCVs => _userCVs;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ══════════════════════════════════════
  // 🆕 Start New CV
  // ══════════════════════════════════════
  void startNewCV(String userId) {
    _currentCV = CVModel(
      id: _uuid.v4(),
      userId: userId,
      cvTitle: 'My CV',
      personalInfo: PersonalInfo(fullName: '', email: '', phone: ''),
      education: [],
      experience: [],
      skills: [],
      projects: [],
      templateId: 'classic',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  // ══════════════════════════════════════
  // ✏️ Update Sections
  // ══════════════════════════════════════
  void updatePersonalInfo(PersonalInfo info) {
    _currentCV = _currentCV?.copyWith(personalInfo: info);
    notifyListeners();
  }

  void updateEducation(List<Education> education) {
    _currentCV = _currentCV?.copyWith(education: education);
    notifyListeners();
  }

  void updateExperience(List<Experience> experience) {
    _currentCV = _currentCV?.copyWith(experience: experience);
    notifyListeners();
  }

  void updateSkills(List<String> skills) {
    _currentCV = _currentCV?.copyWith(skills: skills);
    notifyListeners();
  }

  void updateProjects(List<Project> projects) {
    _currentCV = _currentCV?.copyWith(projects: projects);
    notifyListeners();
  }

  void updateSummary(String summary) {
    _currentCV = _currentCV?.copyWith(summary: summary);
    notifyListeners();
  }

  void updateTemplate(String templateId) {
    _currentCV = _currentCV?.copyWith(templateId: templateId);
    notifyListeners();
  }

  // ══════════════════════════════════════
  // 💾 Save to Firestore
  // ══════════════════════════════════════
  Future<void> saveCV() async {
    if (_currentCV == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      await _firestoreService.createCV(_currentCV!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ══════════════════════════════════════
  // 🔄 Update Existing CV
  // ══════════════════════════════════════
  Future<void> updateExistingCV() async {
    if (_currentCV == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      await _firestoreService.updateCV(_currentCV!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ══════════════════════════════════════
  // 📂 Load CV for Editing
  // ══════════════════════════════════════
  Future<void> loadCV(String userId, String cvId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentCV = await _firestoreService.getCVById(userId, cvId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ══════════════════════════════════════
  // 🗑️ Delete CV
  // ══════════════════════════════════════
  Future<void> deleteCV(String userId, String cvId) async {
    await _firestoreService.deleteCV(userId, cvId);
  }
}
