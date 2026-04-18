// services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cv_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Reference to user's CVs collection
  CollectionReference _cvsCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('cvs');
  }

  // ══════════════════════════════════════
  // 📝 CREATE - Save New CV
  // ══════════════════════════════════════
  Future<String> createCV(CVModel cv) async {
    try {
      DocumentReference docRef =
          _cvsCollection(cv.userId).doc(cv.id);
      await docRef.set(cv.toMap());
      return cv.id;
    } catch (e) {
      throw Exception('Failed to create CV: $e');
    }
  }

  // ══════════════════════════════════════
  // 📖 READ - Get All CVs for User
  // ══════════════════════════════════════
  Stream<List<CVModel>> getUserCVs(String userId) {
    return _cvsCollection(userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CVModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // ══════════════════════════════════════
  // 📖 READ - Get Single CV
  // ══════════════════════════════════════
  Future<CVModel?> getCVById(String userId, String cvId) async {
    try {
      DocumentSnapshot doc =
          await _cvsCollection(userId).doc(cvId).get();
      if (doc.exists) {
        return CVModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get CV: $e');
    }
  }

  // ══════════════════════════════════════
  // ✏️ UPDATE - Update Existing CV
  // ══════════════════════════════════════
  Future<void> updateCV(CVModel cv) async {
    try {
      await _cvsCollection(cv.userId).doc(cv.id).update(
        cv.toMap()..['updatedAt'] = FieldValue.serverTimestamp(),
      );
    } catch (e) {
      throw Exception('Failed to update CV: $e');
    }
  }

  // ══════════════════════════════════════
  // 🗑️ DELETE - Delete CV
  // ══════════════════════════════════════
  Future<void> deleteCV(String userId, String cvId) async {
    try {
      await _cvsCollection(userId).doc(cvId).delete();
    } catch (e) {
      throw Exception('Failed to delete CV: $e');
    }
  }

  // ══════════════════════════════════════
  // 📊 Get CV Count for User
  // ══════════════════════════════════════
  Future<int> getCVCount(String userId) async {
    AggregateQuerySnapshot snapshot =
        await _cvsCollection(userId).count().get();
    return snapshot.count ?? 0;
  }
}