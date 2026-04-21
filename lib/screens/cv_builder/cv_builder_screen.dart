// lib/screens/cv_builder/cv_builder_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

// ── Steps Screens ──
import '../preview/cv_preview_screen.dart';
import 'steps/personal_info_step.dart';
import 'steps/education_step.dart';
import 'steps/experience_step.dart';
import 'steps/skills_step.dart';
import 'steps/projects_step.dart';
import 'steps/summary_step.dart';
import 'steps/template_step.dart';

class CVBuilderScreen extends StatefulWidget {
  final String? cvId; // null = new, value = edit

  CVBuilderScreen({super.key, this.cvId});

  @override
  State<CVBuilderScreen> createState() => _CVBuilderScreenState();
}

class _CVBuilderScreenState extends State<CVBuilderScreen>
    with TickerProviderStateMixin {
  // ══════════════════════════════════
  // 🔥 Firebase
  // ══════════════════════════════════
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  User? get _currentUser => _auth.currentUser;

  // ══════════════════════════════════
  // 📊 State
  // ══════════════════════════════════
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isEditMode = false;

  // ══════════════════════════════════
  // 🎬 Animation
  // ══════════════════════════════════
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late PageController _pageController;

  // ══════════════════════════════════
  // 📝 CV Data
  // ══════════════════════════════════
  String _cvId = '';
  String _cvTitle = 'My CV';
  String _templateId = 'classic';

  // Personal Info
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _linkedInController = TextEditingController();
  final _githubController = TextEditingController();
  final _portfolioController = TextEditingController();

  // Summary
  final _summaryController = TextEditingController();

  // Education List
  List<Map<String, dynamic>> _educationList = [];

  // Experience List
  List<Map<String, dynamic>> _experienceList = [];

  // Skills
  List<String> _skillsList = [];

  // Projects
  List<Map<String, dynamic>> _projectsList = [];

  // ══════════════════════════════════
  // 📋 Steps Info
  // ══════════════════════════════════
  final List<Map<String, dynamic>> _steps = [
    {
      'title': 'Personal',
      'subtitle': 'Basic Info',
      'icon': Icons.person_outline_rounded,
      'color': Color(0xFF2196F3),
    },
    {
      'title': 'Education',
      'subtitle': 'Academic',
      'icon': Icons.school_outlined,
      'color': Color(0xFF66BB6A),
    },
    {
      'title': 'Experience',
      'subtitle': 'Work History',
      'icon': Icons.work_outline_rounded,
      'color': Color(0xFFFFA726),
    },
    {
      'title': 'Skills',
      'subtitle': 'Abilities',
      'icon': Icons.psychology_outlined,
      'color': Color(0xFF9C27B0),
    },
    {
      'title': 'Projects',
      'subtitle': 'Portfolio',
      'icon': Icons.folder_outlined,
      'color': Color(0xFF00BCD4),
    },
    {
      'title': 'Summary',
      'subtitle': 'Overview',
      'icon': Icons.text_snippet_outlined,
      'color': Color(0xFFFF7043),
    },
    {
      'title': 'Template',
      'subtitle': 'Design',
      'icon': Icons.palette_outlined,
      'color': Color(0xFFE91E63),
    },
  ];

  // ══════════════════════════════════
  // Form Keys
  // ══════════════════════════════════
  final _personalFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _initAnimations();

    _cvId = widget.cvId ?? Uuid().v4();
    _isEditMode = widget.cvId != null;

    if (_isEditMode) {
      _loadExistingCV();
    }
  }

  void _initAnimations() {
    _pageController = PageController();

    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _slideAnim = Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _jobTitleController.dispose();
    _linkedInController.dispose();
    _githubController.dispose();
    _portfolioController.dispose();
    _summaryController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════
  // 📂 LOAD EXISTING CV (Edit Mode)
  // ══════════════════════════════════════════
  Future<void> _loadExistingCV() async {
    setState(() => _isLoading = true);

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('cvs')
          .doc(widget.cvId)
          .get();

      if (!doc.exists) {
        if (mounted) Navigator.pop(context);
        return;
      }

      final data = doc.data() as Map<String, dynamic>;

      setState(() {
        _cvTitle = data['cvTitle'] ?? 'My CV';
        _templateId = data['templateId'] ?? 'classic';

        // Personal Info
        final pInfo = data['personalInfo'] as Map<String, dynamic>? ?? {};
        _fullNameController.text = pInfo['fullName'] ?? '';
        _emailController.text = pInfo['email'] ?? '';
        _phoneController.text = pInfo['phone'] ?? '';
        _addressController.text = pInfo['address'] ?? '';
        _jobTitleController.text = pInfo['jobTitle'] ?? '';
        _linkedInController.text = pInfo['linkedIn'] ?? '';
        _githubController.text = pInfo['github'] ?? '';
        _portfolioController.text = pInfo['portfolio'] ?? '';

        // Summary
        _summaryController.text = data['summary'] ?? '';

        // Education
        _educationList = List<Map<String, dynamic>>.from(
          (data['education'] as List? ?? []).map(
            (e) => Map<String, dynamic>.from(e),
          ),
        );

        // Experience
        _experienceList = List<Map<String, dynamic>>.from(
          (data['experience'] as List? ?? []).map(
            (e) => Map<String, dynamic>.from(e),
          ),
        );

        // Skills
        _skillsList = List<String>.from(data['skills'] ?? []);

        // Projects
        _projectsList = List<Map<String, dynamic>>.from(
          (data['projects'] as List? ?? []).map(
            (e) => Map<String, dynamic>.from(e),
          ),
        );
      });
    } catch (e) {
      if (mounted) {
        _showSnackBar('❌ Failed to load CV', Color(0xFFEF5350));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ══════════════════════════════════════════
  // 💾 SAVE CV TO FIRESTORE
  // ══════════════════════════════════════════
  Future<void> _saveCV() async {
    setState(() => _isSaving = true);

    try {
      final cvData = {
        'id': _cvId,
        'userId': _currentUser!.uid,
        'cvTitle': _cvTitle.isNotEmpty
            ? _cvTitle
            : _jobTitleController.text.isNotEmpty
            ? '${_jobTitleController.text} CV'
            : 'My CV',
        'templateId': _templateId,
        'personalInfo': {
          'fullName': _fullNameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'jobTitle': _jobTitleController.text.trim(),
          'linkedIn': _linkedInController.text.trim(),
          'github': _githubController.text.trim(),
          'portfolio': _portfolioController.text.trim(),
        },
        'education': _educationList,
        'experience': _experienceList,
        'skills': _skillsList,
        'projects': _projectsList,
        'summary': _summaryController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add createdAt only for new CVs
      if (!_isEditMode) {
        cvData['createdAt'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('cvs')
          .doc(_cvId)
          .set(cvData, SetOptions(merge: true));

      if (mounted) {
        _showSnackBar('✅ CV saved successfully!', Color(0xFF4CAF50));

        // Navigate to Preview
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => CVPreviewScreen(cvId: _cvId)),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('❌ Failed to save CV: $e', Color(0xFFEF5350));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ══════════════════════════════════════════
  // 🔀 NAVIGATION
  // ══════════════════════════════════════════
  void _nextStep() {
    // Validate current step
    if (_currentStep == 0) {
      if (!_personalFormKey.currentState!.validate()) {
        return;
      }

      // Auto-generate CV title
      if (_cvTitle == 'My CV' && _jobTitleController.text.isNotEmpty) {
        _cvTitle = '${_jobTitleController.text} CV';
      }
    }

    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

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
    return WillPopScope(
      onWillPop: () async {
        if (_currentStep > 0) {
          _previousStep();
          return false;
        }
        return await _showExitDialog() ?? false;
      },
      child: Scaffold(
        backgroundColor: Color(0xFF0A0E21),
        body: _isLoading
            ? _buildLoadingState()
            : SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      children: [
                        // ── App Bar ──
                        _buildAppBar(),

                        // ── Step Indicator ──
                        _buildStepIndicator(),

                        // ── Step Content ──
                        Expanded(child: _buildPageView()),

                        // ── Bottom Navigation ──
                        _buildBottomNav(),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  // ╔══════════════════════════════╗
  // ║     LOADING STATE           ║
  // ╚══════════════════════════════╝
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF2196F3)),
          SizedBox(height: 16.h),
          Text(
            'Loading CV...',
            style: TextStyle(color: Colors.white54, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }

  // ╔══════════════════════════════╗
  // ║     APP BAR                 ║
  // ╚══════════════════════════════╝
  Widget _buildAppBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(8.w, 8.h, 16.w, 0),
      child: Row(
        children: [
          // Back Button
          IconButton(
            onPressed: () async {
              if (_currentStep > 0) {
                _previousStep();
              } else {
                final exit = await _showExitDialog();
                if (exit == true && mounted) {
                  Navigator.pop(context);
                }
              }
            },
            icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditMode ? 'Edit CV' : 'Create CV',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Step ${_currentStep + 1} of ${_steps.length}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),

          // Save Draft Button
          GestureDetector(
            onTap: _isSaving ? null : _saveDraft,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.save_outlined,
                    color: Colors.white.withOpacity(0.6),
                    size: 16.sp,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'Draft',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDraft() async {
    setState(() => _isSaving = true);
    try {
      final cvData = {
        'id': _cvId,
        'userId': _currentUser!.uid,
        'cvTitle': _cvTitle,
        'templateId': _templateId,
        'personalInfo': {
          'fullName': _fullNameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'jobTitle': _jobTitleController.text.trim(),
          'linkedIn': _linkedInController.text.trim(),
          'github': _githubController.text.trim(),
          'portfolio': _portfolioController.text.trim(),
        },
        'education': _educationList,
        'experience': _experienceList,
        'skills': _skillsList,
        'projects': _projectsList,
        'summary': _summaryController.text.trim(),
        'isDraft': true,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('cvs')
          .doc(_cvId)
          .set(cvData, SetOptions(merge: true));

      if (mounted) {
        _showSnackBar('💾 Draft saved!', Color(0xFF2196F3));
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('❌ Failed to save draft', Color(0xFFEF5350));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ╔══════════════════════════════╗
  // ║     STEP INDICATOR          ║
  // ╚══════════════════════════════╝
  Widget _buildStepIndicator() {
    return Container(
      height: 90.h,
      margin: EdgeInsets.only(top: 12.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: _steps.length,
        itemBuilder: (context, index) {
          final step = _steps[index];
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          final color = step['color'] as Color;

          return GestureDetector(
            onTap: () => _goToStep(index),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              margin: EdgeInsets.only(right: 10.w),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: isActive
                    ? color.withOpacity(0.15)
                    : isCompleted
                    ? color.withOpacity(0.06)
                    : Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isActive
                      ? color.withOpacity(0.5)
                      : isCompleted
                      ? color.withOpacity(0.2)
                      : Colors.white.withOpacity(0.06),
                  width: isActive ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon with status
                  Stack(
                    children: [
                      Icon(
                        step['icon'] as IconData,
                        color: isActive
                            ? color
                            : isCompleted
                            ? color.withOpacity(0.7)
                            : Colors.white.withOpacity(0.3),
                        size: 24.sp,
                      ),
                      if (isCompleted)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 12.r,
                            height: 12.r,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 8.sp,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    step['title'] as String,
                    style: TextStyle(
                      color: isActive
                          ? color
                          : isCompleted
                          ? color.withOpacity(0.7)
                          : Colors.white.withOpacity(0.3),
                      fontSize: 11.sp,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ╔══════════════════════════════╗
  // ║     PAGE VIEW               ║
  // ╚══════════════════════════════╝
  Widget _buildPageView() {
    return PageView(
      controller: _pageController,
      physics: NeverScrollableScrollPhysics(),
      onPageChanged: (index) {
        setState(() => _currentStep = index);
      },
      children: [
        // Step 1: Personal Info
        PersonalInfoStep(
          formKey: _personalFormKey,
          fullNameController: _fullNameController,
          emailController: _emailController,
          phoneController: _phoneController,
          addressController: _addressController,
          jobTitleController: _jobTitleController,
          linkedInController: _linkedInController,
          githubController: _githubController,
          portfolioController: _portfolioController,
        ),

        // Step 2: Education
        EducationStep(
          educationList: _educationList,
          onUpdate: (list) {
            setState(() => _educationList = list);
          },
        ),

        // Step 3: Experience
        ExperienceStep(
          experienceList: _experienceList,
          onUpdate: (list) {
            setState(() => _experienceList = list);
          },
        ),

        // Step 4: Skills
        SkillsStep(
          skillsList: _skillsList,
          onUpdate: (list) {
            setState(() => _skillsList = list);
          },
        ),

        // Step 5: Projects
        ProjectsStep(
          projectsList: _projectsList,
          onUpdate: (list) {
            setState(() => _projectsList = list);
          },
        ),

        // Step 6: Summary
        SummaryStep(
          summaryController: _summaryController,
          jobTitle: _jobTitleController.text,
          skills: _skillsList,
        ),

        // Step 7: Template Selection
        TemplateStep(
          selectedTemplate: _templateId,
          onSelect: (id) {
            setState(() => _templateId = id);
          },
          cvData: _buildPreviewData(),
        ),
      ],
    );
  }

  Map<String, dynamic> _buildPreviewData() {
    return {
      'fullName': _fullNameController.text,
      'jobTitle': _jobTitleController.text,
      'email': _emailController.text,
      'phone': _phoneController.text,
      'skills': _skillsList,
      'experienceCount': _experienceList.length,
      'educationCount': _educationList.length,
    };
  }

  // ╔══════════════════════════════╗
  // ║     BOTTOM NAVIGATION       ║
  // ╚══════════════════════════════╝
  Widget _buildBottomNav() {
    final isLastStep = _currentStep == _steps.length - 1;
    final isFirstStep = _currentStep == 0;
    final stepColor = _steps[_currentStep]['color'] as Color;

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
      decoration: BoxDecoration(
        color: Color(0xFF0A0E21),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Row(
        children: [
          // ── Back Button ──
          if (!isFirstStep)
            Expanded(
              child: SizedBox(
                height: 52.h,
                child: OutlinedButton.icon(
                  onPressed: _previousStep,
                  icon: Icon(Icons.arrow_back_rounded, size: 18.sp),
                  label: Text('Back'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white.withOpacity(0.7),
                    side: BorderSide(color: Colors.white.withOpacity(0.15)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                ),
              ),
            ),

          if (!isFirstStep) SizedBox(width: 12.w),

          // ── Next / Save Button ──
          Expanded(
            flex: isFirstStep ? 1 : 1,
            child: SizedBox(
              height: 52.h,
              child: ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : isLastStep
                    ? _saveCV
                    : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLastStep ? Color(0xFF4CAF50) : stepColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: stepColor.withOpacity(0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: _isSaving
                    ? SizedBox(
                        width: 22.r,
                        height: 22.r,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLastStep ? 'Save & Preview' : 'Continue',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Icon(
                              isLastStep
                                  ? Icons.check_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 18.sp,
                            ),
                          ],
                        ),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ╔══════════════════════════════╗
  // ║     EXIT DIALOG             ║
  // ╚══════════════════════════════╝
  Future<bool?> _showExitDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1F38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Color(0xFFFFA726), size: 24.sp),
            SizedBox(width: 10.w),
            Text(
              'Discard Changes?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'You have unsaved changes.\n'
          'Do you want to save as draft or discard?',
          style: TextStyle(color: Colors.white.withOpacity(0.6), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Discard', style: TextStyle(color: Color(0xFFEF5350))),
          ),
          ElevatedButton(
            onPressed: () async {
              await _saveDraft();
              if (mounted) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2196F3),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Text('Save Draft'),
          ),
        ],
      ),
    );
  }
}
