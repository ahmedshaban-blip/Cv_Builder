// lib/screens/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:math';

import '../auth/login_screen.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  static const String routeName = '/splash';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ══════════════════════════════════
  // 🎬 Animation Controllers
  // ══════════════════════════════════
  late AnimationController _logoController;
  late AnimationController _contentController;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late AnimationController _particleController;
  Timer? _navigationTimer;

  // ══════════════════════════════════
  // 🎭 Animations
  // ══════════════════════════════════
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _logoOpacity;
  late Animation<double> _titleSlide;
  late Animation<double> _titleOpacity;
  late Animation<double> _subtitleSlide;
  late Animation<double> _subtitleOpacity;
  late Animation<double> _taglineOpacity;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _bottomOpacity;

  @override
  void initState() {
    super.initState();

    // ✅ شاشة كاملة بدون Status Bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    _initAnimations();
    _startNavigation();
  }

  // ══════════════════════════════════
  // 🎬 Initialize All Animations
  // ══════════════════════════════════
  void _initAnimations() {
    // ── Logo Animation Controller ──
    _logoController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );

    // ── Content Animation Controller ──
    _contentController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    // ── Pulse Animation Controller ──
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // ── Progress Bar Controller ──
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2500),
    );

    // ── Particle Controller ──
    _particleController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    )..repeat();

    // ════════════════════════════════
    // 🎭 Define Animations
    // ════════════════════════════════

    // Logo Scale: 0 → 1.2 → 1.0 (bounce effect)
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.2,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.2,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
    ]).animate(_logoController);

    // Logo Rotation
    _logoRotation = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    // Logo Opacity
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Title Slide & Opacity
    _titleSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Subtitle Slide & Opacity
    _subtitleSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: Interval(0.3, 0.7, curve: Curves.easeIn),
      ),
    );

    // Tagline Opacity
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    // Pulse
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Progress Bar
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // Bottom Opacity
    _bottomOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    // ════════════════════════════════
    // ▶️ Start Animation Sequence
    // ════════════════════════════════
    _logoController.forward().then((_) {
      _contentController.forward();
      _progressController.forward();
    });
  }

  // ══════════════════════════════════
  // 🧭 Navigation Logic
  // ══════════════════════════════════
  void _startNavigation() {
    _navigationTimer = Timer(Duration(seconds: 6), () {
      _navigateToNextScreen();
    });
  }

  void _navigateToNextScreen() {
    if (!mounted) return;
    final user = FirebaseAuth.instance.currentUser;

    // ✅ لو مسجل دخول → روح Home
    // ❌ لو مش مسجل → روح Login
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return user != null
              ? HomeScreen() // ← غيّرها باسم شاشتك
              : LoginScreen(); // ← غيّرها باسم شاشتك
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _logoController.dispose();
    _contentController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    _particleController.dispose();

    // ✅ رجّع الـ System UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ══════════════════════════════════
  // 🏗️ BUILD
  // ══════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0A0E21), // Dark Navy
                Color(0xFF1A1F38), // Deep Blue
                Color(0xFF0D253F), // Dark Teal
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // ── Background Particles ──
              _buildParticles(),

              // ── Background Glow ──
              _buildBackgroundGlow(),

              // ── Main Content ──
              SafeArea(
                child: Column(
                  children: [
                    Spacer(flex: 2),

                    // ── Logo Section ──
                    _buildLogo(),

                    SizedBox(height: 32.h),

                    // ── Title ──
                    _buildTitle(),

                    SizedBox(height: 12.h),

                    // ── Subtitle ──
                    _buildSubtitle(),

                    SizedBox(height: 20.h),

                    // ── Tagline ──
                    _buildTagline(),

                    Spacer(flex: 2),

                    // ── Progress Bar ──
                    _buildProgressBar(),

                    SizedBox(height: 24.h),

                    // ── Bottom Text ──
                    _buildBottomText(),

                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════
  // 🎨 WIDGETS
  // ══════════════════════════════════

  // ── Background Floating Particles ──
  Widget _buildParticles() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          size: Size(
            MediaQuery.of(context).size.width,
            MediaQuery.of(context).size.height,
          ),
          painter: ParticlePainter(progress: _particleController.value),
        );
      },
    );
  }

  // ── Background Glow Effect ──
  Widget _buildBackgroundGlow() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Center(
          child: Container(
            width: 250.w * _pulseAnimation.value,
            height: 250.h * _pulseAnimation.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(0xFF2196F3).withOpacity(0.1),
                  Color(0xFF2196F3).withOpacity(0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Logo ──
  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return Opacity(
          opacity: _logoOpacity.value,
          child: Transform.scale(
            scale: _logoScale.value,
            child: Transform.rotate(
              angle: _logoRotation.value,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: child,
                  );
                },
                child: Container(
                  width: 120.r,
                  height: 120.r,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30.r),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF2196F3),
                        Color(0xFF1565C0),
                        Color(0xFF0D47A1),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF2196F3).withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                      BoxShadow(
                        color: Color(0xFF0D47A1).withOpacity(0.3),
                        blurRadius: 60,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.description_rounded,
                          color: Colors.white,
                          size: 48.sp,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'CV',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Title ──
  Widget _buildTitle() {
    return AnimatedBuilder(
      animation: _contentController,
      builder: (context, child) {
        return Opacity(
          opacity: _titleOpacity.value,
          child: Transform.translate(
            offset: Offset(0, _titleSlide.value),
            child: ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  colors: [Colors.white, Color(0xFF64B5F6)],
                ).createShader(bounds);
              },
              child: Text(
                'ATS CV Builder',
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Subtitle ──
  Widget _buildSubtitle() {
    return AnimatedBuilder(
      animation: _contentController,
      builder: (context, child) {
        return Opacity(
          opacity: _subtitleOpacity.value,
          child: Transform.translate(
            offset: Offset(0, _subtitleSlide.value),
            child: Text(
              'Build Professional Resumes\nThat Beat ATS Systems',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                color: Color(0xFF90CAF9),
                fontWeight: FontWeight.w400,
                height: 1.5,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Tagline Chips ──
  Widget _buildTagline() {
    return AnimatedBuilder(
      animation: _contentController,
      builder: (context, child) {
        return Opacity(
          opacity: _taglineOpacity.value,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildChip('📄 ATS Friendly'),
              SizedBox(width: 12.w),
              _buildChip('⚡ Fast & Easy'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChip(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white70,
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ── Progress Bar ──
  Widget _buildProgressBar() {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, child) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 60.w),
          child: Column(
            children: [
              // Progress Bar
              Container(
                height: 4.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2.r),
                  color: Colors.white.withOpacity(0.1),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progressAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2.r),
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF2196F3),
                          Color(0xFF64B5F6),
                          Color(0xFF42A5F5),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF2196F3).withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),

              // Loading Text
              Text(
                _getLoadingText(_progressAnimation.value),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getLoadingText(double progress) {
    if (progress < 0.3) return 'Initializing...';
    if (progress < 0.6) return 'Loading resources...';
    if (progress < 0.9) return 'Almost ready...';
    return 'Welcome! ✨';
  }

  // ── Bottom Text ──
  Widget _buildBottomText() {
    return AnimatedBuilder(
      animation: _contentController,
      builder: (context, child) {
        return Opacity(
          opacity: _bottomOpacity.value,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified_rounded,
                    color: Colors.white.withOpacity(0.3),
                    size: 14.sp,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'Trusted by thousands of job seekers',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                'v1.0.0',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.2),
                  fontSize: 10.sp,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════
// 🎨 Particle Painter (Background Effect)
// ══════════════════════════════════════
class ParticlePainter extends CustomPainter {
  final double progress;
  final List<ParticleData> particles;

  ParticlePainter({required this.progress})
    : particles = List.generate(
        25,
        (index) => ParticleData(
          x: Random(index).nextDouble(),
          y: Random(index * 3).nextDouble(),
          radius: Random(index * 5).nextDouble() * 2 + 1,
          speed: Random(index * 7).nextDouble() * 0.3 + 0.1,
          opacity: Random(index * 11).nextDouble() * 0.3 + 0.1,
        ),
      );

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = Color(0xFF2196F3).withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;

      double x = particle.x * size.width;
      double y = (particle.y + progress * particle.speed) % 1.0 * size.height;

      canvas.drawCircle(Offset(x, y), particle.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ParticleData {
  final double x;
  final double y;
  final double radius;
  final double speed;
  final double opacity;

  ParticleData({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.opacity,
  });
}
