// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:math';

import '../home/home_screen.dart';
import '../legal/privacy_policy_screen.dart';
import '../legal/terms_of_service_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  static const String routeName = '/register';

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  // ══════════════════════════════════
  // 📝 Form Controllers
  // ══════════════════════════════════
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // ══════════════════════════════════
  // 🔄 State Variables
  // ══════════════════════════════════
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _agreeToTerms = false;
  String? _errorMessage;
  int _currentPage = 0; // 0 = info, 1 = password

  // ══════════════════════════════════
  // 🎬 Animation Controllers
  // ══════════════════════════════════
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _buttonController;
  late AnimationController _particleController;

  late Animation<double> _fadeAnim;
  late Animation<Offset> _headerSlide;
  late Animation<Offset> _formSlide;
  late Animation<double> _buttonScale;

  // ══════════════════════════════════
  // 🔥 Firebase
  // ══════════════════════════════════
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _googleSignIn = GoogleSignIn.instance;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _passwordController.addListener(_onPasswordChanged);
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 900),
    );
    _buttonController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 700),
    );
    _particleController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 4),
    )..repeat();

    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _headerSlide = Tween<Offset>(begin: Offset(0, -0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _formSlide = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _buttonScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _slideController.forward();
    Future.delayed(Duration(milliseconds: 400), () {
      _buttonController.forward();
    });
  }

  void _onPasswordChanged() {
    setState(() {}); // Rebuild for password strength
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _buttonController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════
  // 📧 REGISTER WITH EMAIL
  // ══════════════════════════════════════════
  Future<void> _registerWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeToTerms) {
      _showSnackBar(
        '⚠️ Please agree to the Terms & Conditions',
        Color(0xFFFFA726),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Create Firebase User
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // 2. Update Display Name
      await credential.user!.updateDisplayName(_fullNameController.text.trim());

      // 3. Save User Data to Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'fullName': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'photoUrl': null,
        'createdAt': FieldValue.serverTimestamp(),
        'authProvider': 'email',
        'isProfileComplete': false,
      });

      // 4. Send Email Verification (Optional)
      await credential.user!.sendEmailVerification();

      if (mounted) {
        // ✅ Navigate to Home
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Registration failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ══════════════════════════════════════════
  // 🔵 REGISTER WITH GOOGLE
  // ══════════════════════════════════════════
  Future<void> _registerWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Google Sign-In Flow — ✅ authenticate() replaces signIn()
      final GoogleSignInAccount? googleUser = await _googleSignIn
          .authenticate();

      if (googleUser == null) {
        setState(() => _isGoogleLoading = false);
        return;
      }

      // 2. Get Auth Details — ✅ NO await (synchronous in v7)
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // 3. Create Credential — ✅ Only idToken, no accessToken
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase
      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // 5. Save user if new
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'fullName': userCredential.user!.displayName ?? '',
          'email': userCredential.user!.email ?? '',
          'photoUrl': userCredential.user!.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'authProvider': 'google',
          'isProfileComplete': true,
        });
      }

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Google Sign-Up failed. Try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  // ══════════════════════════════════════════
  // ⚠️ Error Messages
  // ══════════════════════════════════════════
  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password is too weak. Use 6+ characters';
      case 'invalid-email':
        return 'Please enter a valid email address';
      case 'operation-not-allowed':
        return 'Email registration is disabled';
      default:
        return 'Registration failed. Please try again';
    }
  }

  // ══════════════════════════════════════════
  // 🔒 Password Strength Calculator
  // ══════════════════════════════════════════
  double _getPasswordStrength(String password) {
    if (password.isEmpty) return 0;
    double strength = 0;

    if (password.length >= 6) strength += 0.15;
    if (password.length >= 8) strength += 0.1;
    if (password.length >= 12) strength += 0.1;
    if (password.contains(RegExp(r'[A-Z]'))) {
      strength += 0.15;
    }
    if (password.contains(RegExp(r'[a-z]'))) {
      strength += 0.1;
    }
    if (password.contains(RegExp(r'[0-9]'))) {
      strength += 0.2;
    }
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      strength += 0.2;
    }

    return strength.clamp(0.0, 1.0);
  }

  Color _getStrengthColor(double strength) {
    if (strength <= 0.25) return Color(0xFFEF5350);
    if (strength <= 0.5) return Color(0xFFFFA726);
    if (strength <= 0.75) return Color(0xFFFFEE58);
    return Color(0xFF66BB6A);
  }

  String _getStrengthText(double strength) {
    if (strength <= 0.25) return 'Weak';
    if (strength <= 0.5) return 'Fair';
    if (strength <= 0.75) return 'Good';
    return 'Strong';
  }

  IconData _getStrengthIcon(double strength) {
    if (strength <= 0.25) {
      return Icons.sentiment_very_dissatisfied;
    }
    if (strength <= 0.5) {
      return Icons.sentiment_dissatisfied;
    }
    if (strength <= 0.75) {
      return Icons.sentiment_satisfied;
    }
    return Icons.sentiment_very_satisfied;
  }

  // ══════════════════════════════════════════
  // ✅ Password Requirements Checker
  // ══════════════════════════════════════════
  bool get _hasMinLength => _passwordController.text.length >= 6;
  bool get _hasUpperCase => _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasLowerCase => _passwordController.text.contains(RegExp(r'[a-z]'));
  bool get _hasNumber => _passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecialChar =>
      _passwordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.all(16.r),
      ),
    );
  }

  // ══════════════════════════════════════════
  // 🏗️ BUILD
  // ══════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0E21), Color(0xFF1A1F38), Color(0xFF0D253F)],
          ),
        ),
        child: Stack(
          children: [
            // ── Background Particles ──
            _buildParticles(),

            // ── Main Content ──
            SafeArea(
              child: Column(
                children: [
                  // ── Top Bar ──
                  _buildTopBar(),

                  // ── Content ──
                  Expanded(
                    child: SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Column(
                        children: [
                          SizedBox(height: size.height * 0.02),

                          // ── Header ──
                          _buildHeader(),
                          SizedBox(height: 8.h),

                          // ── Step Indicator ──
                          _buildStepIndicator(),
                          SizedBox(height: 24.h),

                          // ── Error ──
                          if (_errorMessage != null) _buildErrorBanner(),

                          // ── Form ──
                          _buildForm(),
                          SizedBox(height: 24.h),

                          // ── Register Button ──
                          if (_currentPage == 1) ...[
                            // ── Terms ──
                            _buildTermsCheckbox(),
                            SizedBox(height: 16.h),
                          ],

                          _buildActionButton(),
                          SizedBox(height: 20.h),

                          // ── Divider ──
                          if (_currentPage == 0) ...[
                            _buildDivider(),
                            SizedBox(height: 20.h),

                            // ── Google ──
                            _buildGoogleButton(),
                            SizedBox(height: 24.h),
                          ],

                          // ── Login Link ──
                          _buildLoginLink(),
                          SizedBox(height: 30.h),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ╔══════════════════════════════╗
  // ║     TOP BAR                 ║
  // ╚══════════════════════════════╝
  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(8.w, 4.h, 16.w, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (_currentPage == 1) {
                setState(() => _currentPage = 0);
              } else {
                Navigator.pop(context);
              }
            },
            icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          Spacer(),
          Text(
            'Step ${_currentPage + 1} of 2',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    );
  }

  // ╔══════════════════════════════╗
  // ║     HEADER                  ║
  // ╚══════════════════════════════╝
  Widget _buildHeader() {
    return SlideTransition(
      position: _headerSlide,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [
            // Logo
            Container(
              width: 70.r,
              height: 70.r,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF2196F3).withOpacity(0.3),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.person_add_rounded,
                  color: Colors.white,
                  size: 32.sp,
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              _currentPage == 0 ? 'Create Account' : 'Set Password',
              style: TextStyle(
                fontSize: 26.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              _currentPage == 0
                  ? 'Enter your details to get started'
                  : 'Create a strong password for your account',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.white.withOpacity(0.45),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ╔══════════════════════════════╗
  // ║     STEP INDICATOR          ║
  // ╚══════════════════════════════╝
  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepDot(0, 'Info', Icons.person_outline),
        _buildStepLine(),
        _buildStepDot(1, 'Security', Icons.lock_outline),
      ],
    );
  }

  Widget _buildStepDot(int step, String label, IconData icon) {
    final isActive = _currentPage == step;
    final isCompleted = _currentPage > step;
    final color = Color(0xFF2196F3);

    return Column(
      children: [
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          width: 44.r,
          height: 44.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? color.withOpacity(0.15)
                : isCompleted
                ? color
                : Colors.white.withOpacity(0.06),
            border: Border.all(
              color: isActive
                  ? color
                  : isCompleted
                  ? color
                  : Colors.white.withOpacity(0.1),
              width: isActive ? 2 : 1,
            ),
          ),
          child: Center(
            child: isCompleted
                ? Icon(Icons.check_rounded, color: Colors.white, size: 20.sp)
                : Icon(
                    icon,
                    color: isActive ? color : Colors.white.withOpacity(0.3),
                    size: 20.sp,
                  ),
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          label,
          style: TextStyle(
            color: isActive
                ? color
                : isCompleted
                ? color.withOpacity(0.7)
                : Colors.white.withOpacity(0.3),
            fontSize: 11.sp,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine() {
    final isCompleted = _currentPage > 0;

    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        width: 60.w,
        height: 2.h,
        decoration: BoxDecoration(
          color: isCompleted
              ? Color(0xFF2196F3)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(1.r),
        ),
      ),
    );
  }

  // ╔══════════════════════════════╗
  // ║     ERROR BANNER            ║
  // ╚══════════════════════════════╝
  Widget _buildErrorBanner() {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Color(0xFFEF5350).withOpacity(0.1),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Color(0xFFEF5350).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFEF5350),
            size: 20.sp,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Color(0xFFEF5350),
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() => _errorMessage = null);
            },
            child: Icon(
              Icons.close_rounded,
              color: Color(0xFFEF5350).withOpacity(0.7),
              size: 18.sp,
            ),
          ),
        ],
      ),
    );
  }

  // ╔══════════════════════════════╗
  // ║     FORM (2 Pages)          ║
  // ╚══════════════════════════════╝
  Widget _buildForm() {
    return SlideTransition(
      position: _formSlide,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Form(
          key: _formKey,
          child: AnimatedSwitcher(
            duration: Duration(milliseconds: 400),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(0.1, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _currentPage == 0 ? _buildPage1() : _buildPage2(),
          ),
        ),
      ),
    );
  }

  // ── Page 1: Basic Info ──
  Widget _buildPage1() {
    return Column(
      key: ValueKey('page1'),
      children: [
        // Full Name
        _buildTextField(
          controller: _fullNameController,
          label: 'Full Name',
          hint: 'Enter your full name',
          icon: Icons.person_outline_rounded,
          textInputAction: TextInputAction.next,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Please enter your name';
            }
            if (v.trim().length < 2) {
              return 'Name must be at least 2 characters';
            }
            if (!RegExp(r'^[a-zA-Z\s\u0600-\u06FF]+$').hasMatch(v.trim())) {
              return 'Name can only contain letters';
            }
            return null;
          },
        ),
        SizedBox(height: 16.h),

        // Email
        _buildTextField(
          controller: _emailController,
          label: 'Email Address',
          hint: 'Enter your email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Please enter your email';
            }
            if (!RegExp(
              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
            ).hasMatch(v.trim())) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
      ],
    );
  }

  // ── Page 2: Password ──
  Widget _buildPage2() {
    final strength = _getPasswordStrength(_passwordController.text);
    final strengthColor = _getStrengthColor(strength);

    return Column(
      key: ValueKey('page2'),
      children: [
        // Password
        _buildTextField(
          controller: _passwordController,
          label: 'Password',
          hint: 'Create a strong password',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          isPasswordVisible: _isPasswordVisible,
          onToggleVisibility: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
          validator: (v) {
            if (v == null || v.isEmpty) {
              return 'Please enter a password';
            }
            if (v.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),

        // Password Strength
        if (_passwordController.text.isNotEmpty) ...[
          SizedBox(height: 12.h),
          _buildPasswordStrengthBar(strength, strengthColor),
          SizedBox(height: 12.h),
          _buildPasswordRequirements(),
        ],

        SizedBox(height: 16.h),

        // Confirm Password
        _buildTextField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          hint: 'Re-enter your password',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          isPasswordVisible: _isConfirmPasswordVisible,
          onToggleVisibility: () {
            setState(() {
              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
            });
          },
          validator: (v) {
            if (v == null || v.isEmpty) {
              return 'Please confirm your password';
            }
            if (v != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }

  // ╔══════════════════════════════╗
  // ║     TEXT FIELD               ║
  // ╚══════════════════════════════╝
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              ' *',
              style: TextStyle(color: Color(0xFFEF5350), fontSize: 14.sp),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          obscureText: isPassword && !isPasswordVisible,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          style: TextStyle(color: Colors.white, fontSize: 15.sp),
          cursorColor: Color(0xFF2196F3),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.2),
              fontSize: 14.sp,
            ),
            prefixIcon: Icon(
              icon,
              color: Colors.white.withOpacity(0.35),
              size: 20.sp,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: Colors.white.withOpacity(0.35),
                      size: 20.sp,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
            filled: true,
            fillColor: Colors.white.withOpacity(0.06),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(color: Color(0xFF2196F3), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(color: Color(0xFFEF5350)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(color: Color(0xFFEF5350), width: 1.5),
            ),
            errorStyle: TextStyle(color: Color(0xFFEF5350), fontSize: 11.sp),
          ),
        ),
      ],
    );
  }

  // ╔══════════════════════════════╗
  // ║     PASSWORD STRENGTH BAR   ║
  // ╚══════════════════════════════╝
  Widget _buildPasswordStrengthBar(double strength, Color color) {
    return Column(
      children: [
        // Bar
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: LinearProgressIndicator(
                  value: strength,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 5,
                ),
              ),
            ),
            SizedBox(width: 12.w),

            // Icon + Text
            Icon(_getStrengthIcon(strength), color: color, size: 18.sp),
            SizedBox(width: 6.w),
            Text(
              _getStrengthText(strength),
              style: TextStyle(
                color: color,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ╔══════════════════════════════╗
  // ║     PASSWORD REQUIREMENTS   ║
  // ╚══════════════════════════════╝
  Widget _buildPasswordRequirements() {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          _buildRequirement('At least 6 characters', _hasMinLength),
          _buildRequirement('Contains uppercase letter (A-Z)', _hasUpperCase),
          _buildRequirement('Contains lowercase letter (a-z)', _hasLowerCase),
          _buildRequirement('Contains number (0-9)', _hasNumber),
          _buildRequirement(
            'Contains special character (!@#\$...)',
            _hasSpecialChar,
          ),
        ],
      ),
    );
  }

  Widget _buildRequirement(String text, bool isMet) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            width: 18.r,
            height: 18.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMet
                  ? Color(0xFF66BB6A).withOpacity(0.15)
                  : Colors.white.withOpacity(0.06),
              border: Border.all(
                color: isMet
                    ? Color(0xFF66BB6A)
                    : Colors.white.withOpacity(0.15),
                width: 1.5,
              ),
            ),
            child: isMet
                ? Icon(
                    Icons.check_rounded,
                    color: Color(0xFF66BB6A),
                    size: 12.sp,
                  )
                : null,
          ),
          SizedBox(width: 10.w),
          Text(
            text,
            style: TextStyle(
              color: isMet ? Color(0xFF66BB6A) : Colors.white.withOpacity(0.4),
              fontSize: 12.sp,
              fontWeight: isMet ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ╔══════════════════════════════╗
  // ║     TERMS CHECKBOX          ║
  // ╚══════════════════════════════╝
  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Checkbox ──
        GestureDetector(
          onTap: () {
            setState(() => _agreeToTerms = !_agreeToTerms);
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            width: 22.r,
            height: 22.r,
            margin: EdgeInsets.only(top: 1.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6.r),
              color: _agreeToTerms ? Color(0xFF2196F3) : Colors.transparent,
              border: Border.all(
                color: _agreeToTerms
                    ? Color(0xFF2196F3)
                    : Colors.white.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: _agreeToTerms
                ? Icon(Icons.check_rounded, color: Colors.white, size: 14.sp)
                : null,
          ),
        ),
        SizedBox(width: 10.w),

        // ── Text with Clickable Links ──
        Expanded(
          child: Wrap(
            children: [
              Text(
                'I agree to the ',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12.sp,
                  height: 1.5,
                ),
              ),

              // ── Terms of Service Link ──
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TermsOfServiceScreen()),
                  );
                },
                child: Text(
                  'Terms of Service',
                  style: TextStyle(
                    color: Color(0xFF64B5F6),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF64B5F6),
                    height: 1.5,
                  ),
                ),
              ),

              Text(
                ' and ',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12.sp,
                  height: 1.5,
                ),
              ),

              // ── Privacy Policy Link ──
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PrivacyPolicyScreen()),
                  );
                },
                child: Text(
                  'Privacy Policy',
                  style: TextStyle(
                    color: Color(0xFF64B5F6),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF64B5F6),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ╔══════════════════════════════╗
  // ║     ACTION BUTTON           ║
  // ╚══════════════════════════════╝
  Widget _buildActionButton() {
    return ScaleTransition(
      scale: _buttonScale,
      child: SizedBox(
        width: double.infinity,
        height: 54.h,
        child: ElevatedButton(
          onPressed: _isLoading
              ? null
              : _currentPage == 0
              ? _goToNextPage
              : _registerWithEmail,
          style: ElevatedButton.styleFrom(
            backgroundColor: _currentPage == 1
                ? Color(0xFF4CAF50)
                : Color(0xFF2196F3),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Color(0xFF2196F3).withOpacity(0.5),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
          ),
          child: _isLoading
              ? SizedBox(
                  width: 24.r,
                  height: 24.r,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _currentPage == 0
                          ? Icons.arrow_forward_rounded
                          : Icons.person_add_rounded,
                      size: 20.sp,
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      _currentPage == 0 ? 'Continue' : 'Create Account',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _goToNextPage() {
    // Validate page 1
    if (_fullNameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter your full name');
      return;
    }
    if (_emailController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter your email');
      return;
    }
    if (!RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(_emailController.text.trim())) {
      setState(() => _errorMessage = 'Please enter a valid email');
      return;
    }

    setState(() {
      _errorMessage = null;
      _currentPage = 1;
    });
  }

  // ╔══════════════════════════════╗
  // ║     OR DIVIDER              ║
  // ╚══════════════════════════════╝
  Widget _buildDivider() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.white.withOpacity(0.15)],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: Text(
              'OR',
              style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white.withOpacity(0.15), Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ╔══════════════════════════════╗
  // ║     GOOGLE BUTTON           ║
  // ╚══════════════════════════════╝
  Widget _buildGoogleButton() {
    return ScaleTransition(
      scale: _buttonScale,
      child: SizedBox(
        width: double.infinity,
        height: 54.h,
        child: OutlinedButton(
          onPressed: _isGoogleLoading ? null : _registerWithGoogle,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white.withOpacity(0.12), width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
            backgroundColor: Colors.white.withOpacity(0.04),
          ),
          child: _isGoogleLoading
              ? SizedBox(
                  width: 24.r,
                  height: 24.r,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 24.r,
                      height: 24.r,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      padding: EdgeInsets.all(3.r),
                      child: Text(
                        'G',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4285F4),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'Sign up with Google',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ╔══════════════════════════════╗
  // ║     LOGIN LINK              ║
  // ╚══════════════════════════════╝
  Widget _buildLoginLink() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Already have an account? ',
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 14.sp,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Text(
              'Sign In',
              style: TextStyle(
                color: Color(0xFF64B5F6),
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ╔══════════════════════════════╗
  // ║     BACKGROUND PARTICLES    ║
  // ╚══════════════════════════════╝
  Widget _buildParticles() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _RegisterParticlePainter(
            progress: _particleController.value,
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════
// 🎨 Particle Painter
// ══════════════════════════════════════════════
class _RegisterParticlePainter extends CustomPainter {
  final double progress;

  _RegisterParticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);

    for (int i = 0; i < 18; i++) {
      final x = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final speed = random.nextDouble() * 0.2 + 0.05;
      final radius = random.nextDouble() * 2 + 0.5;
      final opacity = random.nextDouble() * 0.15 + 0.05;

      final y = (baseY + progress * speed * size.height) % size.height;

      final paint = Paint()
        ..color = Color(0xFF2196F3).withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
