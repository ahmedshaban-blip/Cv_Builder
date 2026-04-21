// lib/screens/home/home_screen.dart
import 'package:cv_builder/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:math';

import '../cv_builder/cv_builder_screen.dart';
import '../preview/cv_preview_screen.dart';
import '../settings/delete_account_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  static const String routeName = '/home';
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // ══════════════════════════════════
  // 🔥 Firebase
  // ══════════════════════════════════
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  User? get _currentUser => _auth.currentUser;

  // ══════════════════════════════════
  // 🎬 Animations
  // ══════════════════════════════════
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _fabController;

  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fabScale;

  // ══════════════════════════════════
  // 🔄 State
  // ══════════════════════════════════
  int _selectedFilter = 0; // 0=All, 1=Classic, 2=Modern
  final List<String> _filters = ['All CVs', 'Classic', 'Modern'];

  @override
  void initState() {
    super.initState();
    _initAnimations();

    // ✅ رجّع الـ System UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 900),
    );
    _fabController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );

    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _slideAnim = Tween<Offset>(begin: Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fabScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _slideController.forward();
    Future.delayed(Duration(milliseconds: 500), () {
      _fabController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════
  // 🗑️ DELETE CV
  // ══════════════════════════════════════════
  Future<void> _deleteCV(String cvId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildDeleteDialog(),
    );

    if (confirmed == true) {
      try {
        await _firestore
            .collection('users')
            .doc(_currentUser!.uid)
            .collection('cvs')
            .doc(cvId)
            .delete();

        if (mounted) {
          _showSnackBar('✅ CV deleted successfully', Color(0xFF4CAF50));
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('❌ Failed to delete CV', Color(0xFFEF5350));
        }
      }
    }
  }

  // ══════════════════════════════════════════
  // 🚪 SIGN OUT
  // ══════════════════════════════════════════
  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildSignOutDialog(),
    );

    if (confirmed == true) {
      await _auth.signOut();
      await GoogleSignIn.instance.signOut();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontWeight: FontWeight.w500)),
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
    return Scaffold(
      backgroundColor: Color(0xFF0A0E21),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: CustomScrollView(
              physics: BouncingScrollPhysics(),
              slivers: [
                // ── App Bar / Header ──
                SliverToBoxAdapter(child: _buildHeader()),

                // ── Stats Cards ──
                SliverToBoxAdapter(child: _buildStatsSection()),

                // ── Quick Actions ──
                SliverToBoxAdapter(child: _buildQuickActions()),

                // ── Filter Chips ──
                SliverToBoxAdapter(child: _buildFilterChips()),

                // ── CV List Title ──
                SliverToBoxAdapter(child: _buildSectionTitle()),

                // ── CV List (from Firestore) ──
                _buildCVList(),

                // ── Bottom Padding ──
                SliverToBoxAdapter(child: SizedBox(height: 100.h)),
              ],
            ),
          ),
        ),
      ),

      // ── FAB: Create New CV ──
      floatingActionButton: _buildFAB(),
    );
  }

  // ══════════════════════════════════════════════
  // 🎨 UI COMPONENTS
  // ══════════════════════════════════════════════

  // ╔══════════════════════════════╗
  // ║     HEADER / APP BAR        ║
  // ╚══════════════════════════════╝
  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
      child: Row(
        children: [
          // ── Avatar ──
          GestureDetector(
            onTap: () => _showProfileSheet(),
            child: Container(
              width: 48.r,
              height: 48.r,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                gradient: LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF2196F3).withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: _currentUser?.photoURL != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: Image.network(
                        _currentUser!.photoURL!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildAvatarText(),
                      ),
                    )
                  : _buildAvatarText(),
            ),
          ),

          SizedBox(width: 14.w),

          // ── Welcome Text ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  _currentUser?.displayName ?? 'User',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // ── Notification Bell ──
          _buildIconButton(
            Icons.notifications_outlined,
            onTap: () {
              _showSnackBar('🔔 No new notifications', Color(0xFF2196F3));
            },
          ),

          SizedBox(width: 8.w),

          // ── Settings / Sign Out ──
          _buildIconButton(Icons.logout_rounded, onTap: _signOut),
        ],
      ),
    );
  }

  Widget _buildAvatarText() {
    String initials = 'U';
    if (_currentUser?.displayName != null &&
        _currentUser!.displayName!.isNotEmpty) {
      final parts = _currentUser!.displayName!.split(' ');
      initials = parts[0][0].toUpperCase();
      if (parts.length > 1) {
        initials += parts[1][0].toUpperCase();
      }
    }
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42.r,
        height: 42.r,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Icon(icon, color: Colors.white.withOpacity(0.6), size: 20.sp),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 👋';
    if (hour < 17) return 'Good Afternoon 👋';
    return 'Good Evening 👋';
  }

  // ╔══════════════════════════════╗
  // ║     STATS SECTION           ║
  // ╚══════════════════════════════╝
  Widget _buildStatsSection() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 0),
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .doc(_currentUser!.uid)
            .collection('cvs')
            .snapshots(),
        builder: (context, snapshot) {
          int totalCVs = 0;
          int classicCount = 0;
          int modernCount = 0;

          if (snapshot.hasData) {
            totalCVs = snapshot.data!.docs.length;
            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              if (data['templateId'] == 'classic') {
                classicCount++;
              } else {
                modernCount++;
              }
            }
          }

          return Row(
            children: [
              _buildStatCard(
                'Total CVs',
                '$totalCVs',
                Icons.description_outlined,
                Color(0xFF2196F3),
              ),
              SizedBox(width: 12.w),
              _buildStatCard(
                'Classic',
                '$classicCount',
                Icons.article_outlined,
                Color(0xFF66BB6A),
              ),
              SizedBox(width: 12.w),
              _buildStatCard(
                'Modern',
                '$modernCount',
                Icons.auto_awesome_outlined,
                Color(0xFFFFA726),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22.sp),
            SizedBox(height: 10.h),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ╔══════════════════════════════╗
  // ║     QUICK ACTIONS           ║
  // ╚══════════════════════════════╝
  Widget _buildQuickActions() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 0),
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF1565C0).withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Text Section ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create Your\nProfessional CV',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'ATS-friendly templates that\nget you noticed',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12.sp,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── Create Button ──
                  GestureDetector(
                    onTap: () {
                      // ✅ Navigate to CV Builder
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CVBuilderScreen()),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            color: Color(0xFF1565C0),
                            size: 18.sp,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'New CV',
                            style: TextStyle(
                              color: Color(0xFF1565C0),
                              fontWeight: FontWeight.w700,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Illustration ──
            Container(
              width: 90.w,
              height: 120.h,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_rounded,
                    color: Colors.white.withOpacity(0.8),
                    size: 40.sp,
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    width: 40.w,
                    height: 3.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Container(
                    width: 50.w,
                    height: 3.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Container(
                    width: 35.w,
                    height: 3.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2.r),
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
  // ║     FILTER CHIPS            ║
  // ╚══════════════════════════════╝
  Widget _buildFilterChips() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 0),
      child: Row(
        children: List.generate(_filters.length, (index) {
          final isSelected = _selectedFilter == index;
          return Padding(
            padding: EdgeInsets.only(right: 10.w),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedFilter = index);
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Color(0xFF2196F3)
                      : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isSelected
                        ? Color(0xFF2196F3)
                        : Colors.white.withOpacity(0.1),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Color(0xFF2196F3).withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  _filters[index],
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                    fontSize: 13.sp,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ╔══════════════════════════════╗
  // ║     SECTION TITLE           ║
  // ╚══════════════════════════════╝
  Widget _buildSectionTitle() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'My Resumes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Swipe to delete →',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }

  // ╔══════════════════════════════╗
  // ║     CV LIST (Firestore)     ║
  // ╚══════════════════════════════╝
  Widget _buildCVList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getCVStream(),
      builder: (context, snapshot) {
        // ── Loading ──
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(top: 60.h),
                child: CircularProgressIndicator(color: Color(0xFF2196F3)),
              ),
            ),
          );
        }

        // ── Error ──
        if (snapshot.hasError) {
          return SliverToBoxAdapter(child: _buildErrorWidget());
        }

        // ── Empty ──
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SliverToBoxAdapter(child: _buildEmptyState());
        }

        // ── CV Cards ──
        final docs = snapshot.data!.docs;
        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return _buildCVCard(data, index);
            }, childCount: docs.length),
          ),
        );
      },
    );
  }

  Stream<QuerySnapshot> _getCVStream() {
    var query = _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('cvs')
        .orderBy('updatedAt', descending: true);

    // Apply filter
    if (_selectedFilter == 1) {
      query = _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('cvs')
          .where('templateId', isEqualTo: 'classic')
          .orderBy('updatedAt', descending: true);
    } else if (_selectedFilter == 2) {
      query = _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('cvs')
          .where('templateId', isEqualTo: 'modern')
          .orderBy('updatedAt', descending: true);
    }

    return query.snapshots();
  }

  // ╔══════════════════════════════╗
  // ║     CV CARD                 ║
  // ╚══════════════════════════════╝
  Widget _buildCVCard(Map<String, dynamic> data, int index) {
    final cvId = data['id'] ?? '';
    final title = data['cvTitle'] ?? 'Untitled CV';
    final templateId = data['templateId'] ?? 'classic';
    final personalInfo = data['personalInfo'] as Map<String, dynamic>?;
    final jobTitle = personalInfo?['jobTitle'] ?? '';
    final skillsList = List<String>.from(data['skills'] ?? []);
    final updatedAt = data['updatedAt'] as Timestamp?;
    final dateStr = updatedAt != null
        ? _formatDate(updatedAt.toDate())
        : 'Just now';

    final isClassic = templateId == 'classic';
    final templateColor = isClassic ? Color(0xFF66BB6A) : Color(0xFFFFA726);

    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Dismissible(
        key: Key(cvId),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => _deleteCV(cvId),
        confirmDismiss: (_) async {
          return await showDialog<bool>(
            context: context,
            builder: (_) => _buildDeleteDialog(),
          );
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 24.w),
          decoration: BoxDecoration(
            color: Color(0xFFEF5350).withOpacity(0.2),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFEF5350),
                size: 28.sp,
              ),
              SizedBox(height: 4.h),
              Text(
                'Delete',
                style: TextStyle(
                  color: Color(0xFFEF5350),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        child: GestureDetector(
          onTap: () {
            // ✅ Navigate to CV Preview / Edit
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CVPreviewScreen(cvId: cvId)),
            );
          },
          child: Container(
            padding: EdgeInsets.all(18.r),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // ── CV Icon ──
                    Container(
                      width: 52.w,
                      height: 64.h,
                      decoration: BoxDecoration(
                        color: templateColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: templateColor.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isClassic
                                ? Icons.article_outlined
                                : Icons.auto_awesome_outlined,
                            color: templateColor,
                            size: 24.sp,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            isClassic ? 'Classic' : 'Modern',
                            style: TextStyle(
                              color: templateColor,
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 14.w),

                    // ── CV Info ──
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (jobTitle.isNotEmpty) ...[
                            SizedBox(height: 3.h),
                            Text(
                              jobTitle,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12.sp,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          SizedBox(height: 6.h),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                color: Colors.white.withOpacity(0.3),
                                size: 12.sp,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                dateStr,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.3),
                                  fontSize: 11.sp,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── Actions ──
                    Column(
                      children: [
                        // Edit Button
                        _buildCardAction(
                          Icons.edit_outlined,
                          Color(0xFF2196F3),
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CVBuilderScreen(cvId: cvId),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 8.h),
                        // More Button
                        _buildCardAction(
                          Icons.more_vert_rounded,
                          Colors.white.withOpacity(0.4),
                          () => _showCVOptions(cvId, title),
                        ),
                      ],
                    ),
                  ],
                ),

                // ── Skills Preview ──
                if (skillsList.isNotEmpty) ...[
                  SizedBox(height: 14.h),
                  SizedBox(
                    height: 28.h,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: skillsList.length > 4 ? 4 : skillsList.length,
                      separatorBuilder: (_, __) => SizedBox(width: 6.w),
                      itemBuilder: (_, i) {
                        if (i == 3 && skillsList.length > 4) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              '+${skillsList.length - 3}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 11.sp,
                              ),
                            ),
                          );
                        }
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFF2196F3).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: Color(0xFF2196F3).withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            skillsList[i],
                            style: TextStyle(
                              color: Color(0xFF64B5F6),
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardAction(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34.r,
        height: 34.r,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(icon, color: color, size: 16.sp),
      ),
    );
  }

  // ╔══════════════════════════════╗
  // ║     EMPTY STATE             ║
  // ╚══════════════════════════════╝
  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 60.h),
      child: Column(
        children: [
          // ── Icon ──
          Container(
            width: 100.r,
            height: 100.r,
            decoration: BoxDecoration(
              color: Color(0xFF2196F3).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.description_outlined,
              color: Color(0xFF2196F3).withOpacity(0.5),
              size: 44.sp,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'No CVs Yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Create your first professional CV\n'
            'and stand out from the crowd!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 14.sp,
              height: 1.5,
            ),
          ),
          SizedBox(height: 28.h),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CVBuilderScreen()),
              );
            },
            icon: Icon(Icons.add_rounded, size: 20.sp),
            label: Text(
              'Create CV',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2196F3),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ╔══════════════════════════════╗
  // ║     ERROR WIDGET            ║
  // ╚══════════════════════════════╝
  Widget _buildErrorWidget() {
    return Padding(
      padding: EdgeInsets.all(40.r),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFEF5350).withOpacity(0.7),
            size: 48.sp,
          ),
          SizedBox(height: 16.h),
          Text(
            'Something went wrong',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Please try again later',
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
  // ║     FAB                     ║
  // ╚══════════════════════════════╝
  Widget _buildFAB() {
    return ScaleTransition(
      scale: _fabScale,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF2196F3).withOpacity(0.4),
              blurRadius: 16,
              spreadRadius: 2,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CVBuilderScreen()),
            );
          },
          backgroundColor: Color(0xFF2196F3),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.r),
          ),
          icon: Icon(Icons.add_rounded),
          label: Text(
            'New CV',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15.sp,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }

  // ╔══════════════════════════════╗
  // ║     DIALOGS & SHEETS        ║
  // ╚══════════════════════════════╝

  // ── Delete Dialog ──
  Widget _buildDeleteDialog() {
    return AlertDialog(
      backgroundColor: Color(0xFF1A1F38),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Row(
        children: [
          Icon(Icons.warning_rounded, color: Color(0xFFEF5350), size: 24.sp),
          SizedBox(width: 10.w),
          Text(
            'Delete CV',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      content: Text(
        'Are you sure you want to delete this CV?\nThis action cannot be undone.',
        style: TextStyle(color: Colors.white.withOpacity(0.6), height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFEF5350),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
          child: Text('Delete'),
        ),
      ],
    );
  }

  // ── Sign Out Dialog ──
  Widget _buildSignOutDialog() {
    return AlertDialog(
      backgroundColor: Color(0xFF1A1F38),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Row(
        children: [
          Icon(Icons.logout_rounded, color: Color(0xFFFFA726), size: 24.sp),
          SizedBox(width: 10.w),
          Text(
            'Sign Out',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      content: Text(
        'Are you sure you want to sign out?',
        style: TextStyle(color: Colors.white.withOpacity(0.6)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFFFA726),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
          child: Text('Sign Out'),
        ),
      ],
    );
  }

  // ── CV Options Bottom Sheet ──
  void _showCVOptions(String cvId, String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          top: 24.h,
          left: 24.w,
          right: 24.w,
          bottom: MediaQuery.of(context).viewPadding.bottom + 15,
        ),
        decoration: BoxDecoration(
          color: Color(0xFF1A1F38),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),

            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 20.h),

            // ── Edit ──
            _buildOptionTile(
              Icons.edit_outlined,
              'Edit CV',
              Color(0xFF2196F3),
              () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CVBuilderScreen(cvId: cvId),
                  ),
                );
              },
            ),

            // ── Preview ──
            _buildOptionTile(
              Icons.visibility_outlined,
              'Preview CV',
              Color(0xFF66BB6A),
              () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CVPreviewScreen(cvId: cvId),
                  ),
                );
              },
            ),

            // ── Duplicate ──
            _buildOptionTile(
              Icons.copy_outlined,
              'Duplicate CV',
              Color(0xFFFFA726),
              () {
                Navigator.pop(context);
                _duplicateCV(cvId);
              },
            ),

            // ── Share ──
            _buildOptionTile(
              Icons.share_outlined,
              'Share as PDF',
              Color(0xFF9C27B0),
              () {
                Navigator.pop(context);
                // Share functionality
              },
            ),
            // ── Delete ──
            _buildOptionTile(
              Icons.delete_outline_rounded,
              'Delete CV',
              Color(0xFFEF5350),
              () {
                Navigator.pop(context);
                _deleteCV(cvId);
              },
            ),

            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40.r,
        height: 40.r,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(icon, color: color, size: 20.sp),
      ),
      title: Text(
        label,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: Colors.white.withOpacity(0.3),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
    );
  }

  // ── Profile Bottom Sheet ──
  void _showProfileSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          top: 24.h,
          bottom: MediaQuery.of(context).viewPadding.bottom,
          left: 24,
          right: 24,
        ),
        decoration: BoxDecoration(
          color: Color(0xFF1A1F38),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 24.h),

            // Avatar
            Container(
              width: 80.r,
              height: 80.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF2196F3).withOpacity(0.3),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: _currentUser?.photoURL != null
                  ? ClipOval(
                      child: Image.network(
                        _currentUser!.photoURL!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            _currentUser!.displayName
                                    ?.substring(0, 1)
                                    .toUpperCase() ??
                                'U',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        _currentUser?.displayName
                                ?.substring(0, 1)
                                .toUpperCase() ??
                            'U',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
            SizedBox(height: 16.h),

            // Name
            Text(
              _currentUser?.displayName ?? 'User',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4.h),

            // Email
            Text(
              _currentUser?.email ?? '',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 24.h),

            // Sign Out Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _signOut();
                },
                icon: Icon(Icons.logout_rounded, size: 18.sp),
                label: Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFEF5350).withOpacity(0.15),
                  foregroundColor: Color(0xFFEF5350),
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),

            // ── Delete Account Button ──
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Close sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DeleteAccountScreen()),
                  );
                },
                icon: Icon(Icons.delete_forever_rounded, size: 18.sp),
                label: Text('Delete Account'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white.withOpacity(0.4),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // 📋 DUPLICATE CV
  // ══════════════════════════════════════════
  Future<void> _duplicateCV(String cvId) async {
    try {
      // 1. Get original CV
      final doc = await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('cvs')
          .doc(cvId)
          .get();

      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;

      // 2. Create new CV with new ID
      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      data['id'] = newId;
      data['cvTitle'] = '${data['cvTitle']} (Copy)';
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      // 3. Save
      await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('cvs')
          .doc(newId)
          .set(data);

      if (mounted) {
        _showSnackBar('✅ CV duplicated successfully', Color(0xFF4CAF50));
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('❌ Failed to duplicate CV', Color(0xFFEF5350));
      }
    }
  }

  // ══════════════════════════════════════════
  // 📅 Format Date
  // ══════════════════════════════════════════
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';

    return '${date.day}/${date.month}/${date.year}';
  }
}
