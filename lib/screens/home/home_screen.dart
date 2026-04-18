// lib/screens/home/home_screen.dart
import 'package:cv_builder/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:math';

import '../cv_builder/cv_builder_screen.dart';
import '../preview/cv_preview_screen.dart';

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
      duration: const Duration(milliseconds: 800),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fabScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _slideController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
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
          _showSnackBar('✅ CV deleted successfully', const Color(0xFF4CAF50));
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('❌ Failed to delete CV', const Color(0xFFEF5350));
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
      await GoogleSignIn().signOut();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ══════════════════════════════════════════
  // 🏗️ BUILD
  // ══════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
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
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          // ── Avatar ──
          GestureDetector(
            onTap: () => _showProfileSheet(),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2196F3).withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: _currentUser?.photoURL != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        _currentUser!.photoURL!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildAvatarText(),
                      ),
                    )
                  : _buildAvatarText(),
            ),
          ),

          const SizedBox(width: 14),

          // ── Welcome Text ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _currentUser?.displayName ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
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
              _showSnackBar('🔔 No new notifications', const Color(0xFF2196F3));
            },
          ),

          const SizedBox(width: 8),

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
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Icon(icon, color: Colors.white.withOpacity(0.6), size: 20),
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
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
                const Color(0xFF2196F3),
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Classic',
                '$classicCount',
                Icons.article_outlined,
                const Color(0xFF66BB6A),
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Modern',
                '$modernCount',
                Icons.auto_awesome_outlined,
                const Color(0xFFFFA726),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 11,
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1565C0).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
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
                  const Text(
                    'Create Your\nProfessional CV',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ATS-friendly templates that\nget you noticed',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Create Button ──
                  GestureDetector(
                    onTap: () {
                      // ✅ Navigate to CV Builder
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CVBuilderScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            color: Color(0xFF1565C0),
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'New CV',
                            style: TextStyle(
                              color: Color(0xFF1565C0),
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
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
              width: 90,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_rounded,
                    color: Colors.white.withOpacity(0.8),
                    size: 40,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 40,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 50,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 35,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Row(
        children: List.generate(_filters.length, (index) {
          final isSelected = _selectedFilter == index;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedFilter = index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2196F3)
                      : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF2196F3)
                        : Colors.white.withOpacity(0.1),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF2196F3).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
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
                    fontSize: 13,
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'My Resumes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Swipe to delete →',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 11,
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
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(top: 60),
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
          padding: const EdgeInsets.symmetric(horizontal: 20),
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
    final templateColor = isClassic
        ? const Color(0xFF66BB6A)
        : const Color(0xFFFFA726);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
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
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: const Color(0xFFEF5350).withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFEF5350),
                size: 28,
              ),
              SizedBox(height: 4),
              Text(
                'Delete',
                style: TextStyle(
                  color: Color(0xFFEF5350),
                  fontSize: 12,
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
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // ── CV Icon ──
                    Container(
                      width: 52,
                      height: 64,
                      decoration: BoxDecoration(
                        color: templateColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
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
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isClassic ? 'Classic' : 'Modern',
                            style: TextStyle(
                              color: templateColor,
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 14),

                    // ── CV Info ──
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (jobTitle.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              jobTitle,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                color: Colors.white.withOpacity(0.3),
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                dateStr,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.3),
                                  fontSize: 11,
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
                          const Color(0xFF2196F3),
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CVBuilderScreen(cvId: cvId),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
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
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 28,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: skillsList.length > 4 ? 4 : skillsList.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (_, i) {
                        if (i == 3 && skillsList.length > 4) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '+${skillsList.length - 3}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 11,
                              ),
                            ),
                          );
                        }
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF2196F3).withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            skillsList[i],
                            style: const TextStyle(
                              color: Color(0xFF64B5F6),
                              fontSize: 11,
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
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }

  // ╔══════════════════════════════╗
  // ║     EMPTY STATE             ║
  // ╚══════════════════════════════╝
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Column(
        children: [
          // ── Icon ──
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.description_outlined,
              color: const Color(0xFF2196F3).withOpacity(0.5),
              size: 44,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No CVs Yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first professional CV\n'
            'and stand out from the crowd!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CVBuilderScreen()),
              );
            },
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
              'Create CV',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
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
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: const Color(0xFFEF5350).withOpacity(0.7),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please try again later',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 13,
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
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2196F3).withOpacity(0.4),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CVBuilderScreen()),
            );
          },
          backgroundColor: const Color(0xFF2196F3),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'New CV',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
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
      backgroundColor: const Color(0xFF1A1F38),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.warning_rounded, color: Color(0xFFEF5350), size: 24),
          SizedBox(width: 10),
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
            backgroundColor: const Color(0xFFEF5350),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }

  // ── Sign Out Dialog ──
  Widget _buildSignOutDialog() {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1F38),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.logout_rounded, color: Color(0xFFFFA726), size: 24),
          SizedBox(width: 10),
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
            backgroundColor: const Color(0xFFFFA726),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Sign Out'),
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
          top: 24,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewPadding.bottom + 15,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1F38),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),

            // ── Edit ──
            _buildOptionTile(
              Icons.edit_outlined,
              'Edit CV',
              const Color(0xFF2196F3),
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
              const Color(0xFF66BB6A),
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
              const Color(0xFFFFA726),
              () {
                Navigator.pop(context);
                _duplicateCV(cvId);
              },
            ),

            // ── Share ──
            _buildOptionTile(
              Icons.share_outlined,
              'Share as PDF',
              const Color(0xFF9C27B0),
              () {
                Navigator.pop(context);
                // Share functionality
              },
            ),

            // ── Delete ──
            _buildOptionTile(
              Icons.delete_outline_rounded,
              'Delete CV',
              const Color(0xFFEF5350),
              () {
                Navigator.pop(context);
                _deleteCV(cvId);
              },
            ),

            const SizedBox(height: 10),
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
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: Colors.white.withOpacity(0.3),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  // ── Profile Bottom Sheet ──
  void _showProfileSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1F38),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2196F3).withOpacity(0.3),
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // Name
            Text(
              _currentUser?.displayName ?? 'User',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),

            // Email
            Text(
              _currentUser?.email ?? '',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Sign Out Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _signOut();
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF5350).withOpacity(0.15),
                  foregroundColor: const Color(0xFFEF5350),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
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
        _showSnackBar('✅ CV duplicated successfully', const Color(0xFF4CAF50));
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('❌ Failed to duplicate CV', const Color(0xFFEF5350));
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
