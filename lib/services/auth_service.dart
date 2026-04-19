// services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance; // ✅ Singleton
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


    // ✅ MUST be called before using Google Sign-In (e.g., in main.dart)
  static Future<void> initializeGoogleSignIn({
    String? clientId,
    String? serverClientId,
  }) async {
    await GoogleSignIn.instance.initialize(
      clientId: clientId,
      serverClientId: serverClientId,
    );
  }
  // ✅ Current User Stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ✅ Get Current User
  User? get currentUser => _auth.currentUser;

  // ══════════════════════════════════════
  // 📧 Email & Password Registration
  // ══════════════════════════════════════
  Future<UserCredential?> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save user data to Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'fullName': fullName,
        'email': email,
        'photoUrl': null,
        'createdAt': FieldValue.serverTimestamp(),
        'authProvider': 'email',
      });

      // Update display name
      await credential.user!.updateDisplayName(fullName);

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ══════════════════════════════════════
  // 📧 Email & Password Login
  // ══════════════════════════════════════
  Future<UserCredential?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ══════════════════════════════════════
  // 🔵 Google Sign In
  // ══════════════════════════════════════
    Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. Trigger Google Sign-In flow — ✅ authenticate() replaces signIn()
      final GoogleSignInAccount? googleUser =
          await _googleSignIn.authenticate();

      if (googleUser == null) return null; // User cancelled

      // 2. Get auth details — ✅ Now SYNCHRONOUS (no await!)
      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      // 3. Create credential — ✅ Only idToken needed
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase
      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // 5. Save new user to Firestore
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'uid': userCredential.user!.uid,
          'fullName': userCredential.user!.displayName,
          'email': userCredential.user!.email,
          'photoUrl': userCredential.user!.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'authProvider': 'google',
        });
      }

      return userCredential;
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }


  // ══════════════════════════════════════
  // 🔑 Forgot Password
  // ══════════════════════════════════════
 Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ══════════════════════════════════════
  // 🚪 Sign Out
  // ══════════════════════════════════════
   Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.disconnect()]);
  }

  // ══════════════════════════════════════
  // ⚠️ Error Handling
  // ══════════════════════════════════════
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً';
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم بالفعل';
      case 'user-not-found':
        return 'لا يوجد حساب بهذا البريد الإلكتروني';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صالح';
      default:
        return 'حدث خطأ غير متوقع: ${e.message}';
    }
  }
}
