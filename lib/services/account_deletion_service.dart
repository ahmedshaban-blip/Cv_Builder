// lib/services/account_deletion_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AccountDeletionService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _googleSignIn = GoogleSignIn.instance;

  User? get _currentUser => _auth.currentUser;

  // ══════════════════════════════════════════
  // 🗑️ DELETE ENTIRE ACCOUNT
  // ══════════════════════════════════════════
  Future<DeleteResult> deleteAccount() async {
    if (_currentUser == null) {
      return DeleteResult(
        success: false,
        error: 'No user is currently signed in',
      );
    }

    final uid = _currentUser!.uid;

    try {
      // Step 1: Delete all CVs (sub-collection)
      await _deleteAllCVs(uid);

      // Step 2: Delete user document
      await _deleteUserDocument(uid);

      // Step 3: Delete Firebase Auth account
      await _currentUser!.delete();

      // Step 4: Sign out from Google
      await _googleSignIn.signOut();

      return DeleteResult(success: true);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return DeleteResult(
          success: false,
          error: 'requires-recent-login',
          requiresReauth: true,
        );
      }
      return DeleteResult(
        success: false,
        error: e.message ?? 'Authentication error',
      );
    } catch (e) {
      return DeleteResult(
        success: false,
        error: 'Failed to delete account: $e',
      );
    }
  }

  // ══════════════════════════════════════════
  // 📄 Delete All CVs
  // ══════════════════════════════════════════
  Future<void> _deleteAllCVs(String uid) async {
    final cvsSnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('cvs')
        .get();

    // Batch delete for better performance
    final batch = _firestore.batch();

    for (final doc in cvsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    if (cvsSnapshot.docs.isNotEmpty) {
      await batch.commit();
    }
  }

  // ══════════════════════════════════════════
  // 👤 Delete User Document
  // ══════════════════════════════════════════
  Future<void> _deleteUserDocument(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }

  // ══════════════════════════════════════════
  // 🔐 Re-authenticate with Email/Password
  // ══════════════════════════════════════════
  Future<ReauthResult> reauthenticateWithEmail(
    String password,
  ) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: _currentUser!.email!,
        password: password,
      );

      await _currentUser!
          .reauthenticateWithCredential(credential);

      return ReauthResult(success: true);
    } on FirebaseAuthException catch (e) {
      String errorMsg;
      switch (e.code) {
        case 'wrong-password':
          errorMsg = 'Incorrect password. Please try again.';
          break;
        case 'invalid-credential':
          errorMsg = 'Invalid credentials. Please try again.';
          break;
        case 'too-many-requests':
          errorMsg = 'Too many attempts. Please try later.';
          break;
        default:
          errorMsg = e.message ?? 'Authentication failed';
      }
      return ReauthResult(success: false, error: errorMsg);
    }
  }

  // ══════════════════════════════════════════
  // 🔐 Re-authenticate with Google
  // ══════════════════════════════════════════

Future<ReauthResult> reauthenticateWithGoogle() async {
  try {
    // ✅ authenticate() throws if cancelled — no null check needed
    final googleUser = await _googleSignIn.authenticate();

    // ✅ Synchronous, no await
    final googleAuth = googleUser.authentication;

    // ✅ Only idToken
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    await _currentUser!.reauthenticateWithCredential(credential);

    return ReauthResult(success: true);
  } catch (e) {
    // ✅ This now handles BOTH cancellation and failures
    return ReauthResult(
      success: false,
      error: 'Google re-authentication failed',
    );
  }
}  // ══════════════════════════════════════════
  // 📊 Get Account Data Summary
  // ══════════════════════════════════════════
  Future<AccountDataSummary> getAccountDataSummary() async {
    if (_currentUser == null) {
      return AccountDataSummary(cvCount: 0);
    }

    final uid = _currentUser!.uid;

    try {
      final cvsSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('cvs')
          .get();

      final userDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      String? authProvider;
      DateTime? createdAt;

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        authProvider = data['authProvider'] as String?;
        final ts = data['createdAt'] as Timestamp?;
        createdAt = ts?.toDate();
      }

      return AccountDataSummary(
        cvCount: cvsSnapshot.docs.length,
        authProvider: authProvider ?? 'unknown',
        email: _currentUser!.email ?? '',
        displayName: _currentUser!.displayName ?? '',
        createdAt: createdAt,
      );
    } catch (e) {
      return AccountDataSummary(cvCount: 0);
    }
  }
}

// ══════════════════════════════════════════════
// 📦 Result Models
// ══════════════════════════════════════════════
class DeleteResult {
  final bool success;
  final String? error;
  final bool requiresReauth;

  DeleteResult({
    required this.success,
    this.error,
    this.requiresReauth = false,
  });
}

class ReauthResult {
  final bool success;
  final String? error;

  ReauthResult({
    required this.success,
    this.error,
  });
}

class AccountDataSummary {
  final int cvCount;
  final String? authProvider;
  final String? email;
  final String? displayName;
  final DateTime? createdAt;

  AccountDataSummary({
    required this.cvCount,
    this.authProvider,
    this.email,
    this.displayName,
    this.createdAt,
  });
}