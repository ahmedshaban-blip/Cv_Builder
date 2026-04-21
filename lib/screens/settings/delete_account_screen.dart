// lib/screens/settings/delete_account_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/account_deletion_service.dart';
import '../auth/login_screen.dart';

class DeleteAccountScreen extends StatefulWidget {
  DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen>
    with SingleTickerProviderStateMixin {
  // ══════════════════════════════════
  // Services & State
  // ══════════════════════════════════
  final _deletionService = AccountDeletionService();
  final _auth = FirebaseAuth.instance;
  User? get _currentUser => _auth.currentUser;

  AccountDataSummary? _dataSummary;
  bool _isLoading = true;
  bool _isDeleting = false;
  int _currentStep = 0;
  // 0 = info, 1 = confirm, 2 = reauth, 3 = deleting

  // ══════════════════════════════════
  // Confirmation State
  // ══════════════════════════════════
  bool _confirmCheck1 = false;
  bool _confirmCheck2 = false;
  bool _confirmCheck3 = false;
  final _confirmTextController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  String? _errorMessage;

  bool get _allConfirmed =>
      _confirmCheck1 &&
      _confirmCheck2 &&
      _confirmCheck3 &&
      _confirmTextController.text.trim().toUpperCase() == 'DELETE';

  // ══════════════════════════════════
  // Animation
  // ══════════════════════════════════
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _fadeController.forward();
    _loadAccountData();
  }

  @override
  void dispose() {
    _confirmTextController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════
  // 📊 Load Account Data
  // ══════════════════════════════════════════
  Future<void> _loadAccountData() async {
    final summary = await _deletionService.getAccountDataSummary();
    setState(() {
      _dataSummary = summary;
      _isLoading = false;
    });
  }

  // ══════════════════════════════════════════
  // 🗑️ Execute Deletion
  // ══════════════════════════════════════════
  Future<void> _executeAccountDeletion() async {
    setState(() {
      _isDeleting = true;
      _currentStep = 3;
      _errorMessage = null;
    });

    // Attempt deletion
    final result = await _deletionService.deleteAccount();

    if (result.success) {
      if (mounted) {
        _showSuccessAndNavigate();
      }
    } else if (result.requiresReauth) {
      // Need re-authentication
      setState(() {
        _currentStep = 2;
        _isDeleting = false;
      });
    } else {
      setState(() {
        _errorMessage = result.error;
        _isDeleting = false;
        _currentStep = 1;
      });
    }
  }

  // ══════════════════════════════════════════
  // 🔐 Re-authenticate & Retry
  // ══════════════════════════════════════════
  Future<void> _reauthAndDelete() async {
    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    final authProvider = _dataSummary?.authProvider;

    ReauthResult reauthResult;

    if (authProvider == 'google') {
      reauthResult = await _deletionService.reauthenticateWithGoogle();
    } else {
      if (_passwordController.text.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter your password';
          _isDeleting = false;
        });
        return;
      }
      reauthResult = await _deletionService.reauthenticateWithEmail(
        _passwordController.text,
      );
    }

    if (!reauthResult.success) {
      setState(() {
        _errorMessage = reauthResult.error;
        _isDeleting = false;
      });
      return;
    }

    // Re-auth successful → retry deletion
    final deleteResult = await _deletionService.deleteAccount();

    if (deleteResult.success) {
      if (mounted) _showSuccessAndNavigate();
    } else {
      setState(() {
        _errorMessage = deleteResult.error;
        _isDeleting = false;
      });
    }
  }

  // ══════════════════════════════════════════
  // ✅ Success → Navigate to Login
  // ══════════════════════════════════════════
  void _showSuccessAndNavigate() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1F38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10.h),
            Container(
              width: 64.r,
              height: 64.r,
              decoration: BoxDecoration(
                color: Color(0xFF4CAF50).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF4CAF50),
                size: 40.sp,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Account Deleted',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Your account and all associated data\n'
              'have been permanently deleted.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 13.sp,
                height: 1.5,
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );

    // Navigate after delay
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
          (route) => false,
        );
      }
    });
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
    return Scaffold(
      backgroundColor: Color(0xFF0A0E21),
      body: SafeArea(
        child: _isLoading
            ? _buildLoading()
            : FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    _buildAppBar(),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(20, 8, 20, 40),
                        child: _buildCurrentStep(),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(child: CircularProgressIndicator(color: Color(0xFFEF5350)));
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildInfoStep();
      case 1:
        return _buildConfirmStep();
      case 2:
        return _buildReauthStep();
      case 3:
        return _buildDeletingStep();
      default:
        return _buildInfoStep();
    }
  }

  // ╔══════════════════════════════╗
  // ║     APP BAR                 ║
  // ╚══════════════════════════════╝
  Widget _buildAppBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(8.w, 8.h, 16.w, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: _isDeleting
                ? null
                : () {
                    if (_currentStep > 0 && _currentStep < 3) {
                      setState(() => _currentStep--);
                    } else {
                      Navigator.pop(context);
                    }
                  },
            icon: Icon(
              Icons.arrow_back_rounded,
              color: _isDeleting ? Colors.white.withOpacity(0.3) : Colors.white,
            ),
          ),
          Expanded(
            child: Text(
              'Delete Account',
              style: TextStyle(
                color: Color(0xFFEF5350),
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Step indicator
          if (_currentStep < 3)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Color(0xFFEF5350).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'Step ${_currentStep + 1}/3',
                style: TextStyle(
                  color: Color(0xFFEF5350),
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ╔══════════════════════════════╗
  // ║   STEP 0: INFO              ║
  // ╚══════════════════════════════╝
  Widget _buildInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Warning Header ──
        _buildWarningHeader(),
        SizedBox(height: 24.h),

        // ── Account Summary ──
        _buildAccountSummary(),
        SizedBox(height: 24.h),

        // ── What Will Be Deleted ──
        _buildDeletionDetails(),
        SizedBox(height: 24.h),

        // ── Important Notice ──
        _buildImportantNotice(),
        SizedBox(height: 32.h),

        // ── Proceed Button ──
        SizedBox(
          width: double.infinity,
          height: 52.h,
          child: ElevatedButton(
            onPressed: () {
              setState(() => _currentStep = 1);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFEF5350).withOpacity(0.15),
              foregroundColor: Color(0xFFEF5350),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
                side: BorderSide(color: Color(0xFFEF5350).withOpacity(0.3)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'I Understand, Continue',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(Icons.arrow_forward_rounded, size: 18.sp),
              ],
            ),
          ),
        ),
        SizedBox(height: 12.h),

        // ── Cancel Button ──
        SizedBox(
          width: double.infinity,
          height: 52.h,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withOpacity(0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
            child: Text(
              'Cancel, Keep My Account',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWarningHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEF5350).withOpacity(0.12),
            Color(0xFFC62828).withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Color(0xFFEF5350).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            width: 64.r,
            height: 64.r,
            decoration: BoxDecoration(
              color: Color(0xFFEF5350).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_rounded,
              color: Color(0xFFEF5350),
              size: 34.sp,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Delete Your Account?',
            style: TextStyle(
              color: Color(0xFFEF5350),
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'This action is permanent and cannot be undone.\n'
            'All your data will be permanently removed.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13.sp,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSummary() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_circle_outlined,
                color: Colors.white.withOpacity(0.5),
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Account Summary',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          _buildSummaryRow('👤', 'Name', _dataSummary?.displayName ?? 'N/A'),
          _buildSummaryRow('📧', 'Email', _dataSummary?.email ?? 'N/A'),
          _buildSummaryRow(
            '🔑',
            'Auth Method',
            _dataSummary?.authProvider == 'google'
                ? 'Google Sign-In'
                : 'Email & Password',
          ),
          _buildSummaryRow(
            '📄',
            'Total CVs',
            '${_dataSummary?.cvCount ?? 0} CVs will be deleted',
          ),
          if (_dataSummary?.createdAt != null)
            _buildSummaryRow(
              '📅',
              'Member Since',
              _formatDate(_dataSummary!.createdAt!),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String emoji, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 14.sp)),
          SizedBox(width: 10.w),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12.sp,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeletionDetails() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Color(0xFFEF5350).withOpacity(0.04),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Color(0xFFEF5350).withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.delete_forever_rounded,
                color: Color(0xFFEF5350),
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'What Will Be Deleted',
                style: TextStyle(
                  color: Color(0xFFEF5350),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          _buildDeleteItem('Your account and login credentials'),
          _buildDeleteItem('All ${_dataSummary?.cvCount ?? 0} CVs you created'),
          _buildDeleteItem('Personal information (name, email, phone)'),
          _buildDeleteItem('Professional data (education, experience, skills)'),
          _buildDeleteItem('All saved drafts and templates preferences'),
          _buildDeleteItem('Profile data and settings'),
        ],
      ),
    );
  }

  Widget _buildDeleteItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Icon(
              Icons.close_rounded,
              color: Color(0xFFEF5350),
              size: 14.sp,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13.sp,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportantNotice() {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Color(0xFFFFA726).withOpacity(0.06),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Color(0xFFFFA726).withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Color(0xFFFFA726),
                size: 18.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Before You Delete',
                style: TextStyle(
                  color: Color(0xFFFFA726),
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            '• Download any CVs you want to keep as PDF\n'
            '• This action cannot be reversed\n'
            '• You can create a new account later,\n'
            '  but your data will not be recovered',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12.sp,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ╔══════════════════════════════╗
  // ║   STEP 1: CONFIRM           ║
  // ╚══════════════════════════════╝
  Widget _buildConfirmStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──
        Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Color(0xFFEF5350).withOpacity(0.06),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Color(0xFFEF5350).withOpacity(0.12)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.checklist_rounded,
                color: Color(0xFFEF5350),
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confirm Deletion',
                      style: TextStyle(
                        color: Color(0xFFEF5350),
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Please confirm each item below',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24.h),

        // ── Error Banner ──
        if (_errorMessage != null) ...[_buildError(), SizedBox(height: 16.h)],

        // ── Confirmation Checkboxes ──
        _buildConfirmCheckbox(
          value: _confirmCheck1,
          text:
              'I understand that all my CVs and personal data '
              'will be permanently deleted',
          onChanged: (v) {
            setState(() => _confirmCheck1 = v ?? false);
          },
        ),
        SizedBox(height: 12.h),

        _buildConfirmCheckbox(
          value: _confirmCheck2,
          text: 'I have downloaded any CVs I want to keep',
          onChanged: (v) {
            setState(() => _confirmCheck2 = v ?? false);
          },
        ),
        SizedBox(height: 12.h),

        _buildConfirmCheckbox(
          value: _confirmCheck3,
          text:
              'I understand this action cannot be undone '
              'and my account cannot be recovered',
          onChanged: (v) {
            setState(() => _confirmCheck3 = v ?? false);
          },
        ),
        SizedBox(height: 24.h),

        // ── Type DELETE ──
        Text(
          'Type "DELETE" to confirm',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: _confirmTextController,
          onChanged: (_) => setState(() {}),
          textCapitalization: TextCapitalization.characters,
          style: TextStyle(
            color: Color(0xFFEF5350),
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
          ),
          cursorColor: Color(0xFFEF5350),
          decoration: InputDecoration(
            hintText: 'DELETE',
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.15),
              fontSize: 18.sp,
              letterSpacing: 4,
            ),
            filled: true,
            fillColor: Color(0xFFEF5350).withOpacity(0.04),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(
                color: Color(0xFFEF5350).withOpacity(0.15),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(
                color: Color(0xFFEF5350).withOpacity(0.15),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(color: Color(0xFFEF5350), width: 1.5),
            ),
          ),
        ),
        SizedBox(height: 32.h),

        // ── Delete Button ──
        SizedBox(
          width: double.infinity,
          height: 54.h,
          child: ElevatedButton(
            onPressed: _allConfirmed ? _executeAccountDeletion : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFEF5350),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Color(0xFFEF5350).withOpacity(0.2),
              disabledForegroundColor: Colors.white.withOpacity(0.3),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_forever_rounded, size: 20.sp),
                SizedBox(width: 10.w),
                Text(
                  'Permanently Delete Account',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 12.h),

        // ── Cancel ──
        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmCheckbox({
    required bool value,
    required String text,
    required ValueChanged<bool?> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: value
              ? Color(0xFFEF5350).withOpacity(0.06)
              : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: value
                ? Color(0xFFEF5350).withOpacity(0.25)
                : Colors.white.withOpacity(0.06),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 200),
              width: 22.r,
              height: 22.r,
              margin: EdgeInsets.only(top: 1.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6.r),
                color: value ? Color(0xFFEF5350) : Colors.transparent,
                border: Border.all(
                  color: value
                      ? Color(0xFFEF5350)
                      : Colors.white.withOpacity(0.25),
                  width: 1.5,
                ),
              ),
              child: value
                  ? Icon(Icons.check_rounded, color: Colors.white, size: 14.sp)
                  : null,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: value
                      ? Colors.white.withOpacity(0.8)
                      : Colors.white.withOpacity(0.5),
                  fontSize: 13.sp,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ╔══════════════════════════════╗
  // ║   STEP 2: RE-AUTH           ║
  // ╚══════════════════════════════╝
  Widget _buildReauthStep() {
    final isGoogle = _dataSummary?.authProvider == 'google';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──
        Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Color(0xFFFFA726).withOpacity(0.06),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Color(0xFFFFA726).withOpacity(0.12)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFFFFA726),
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verify Your Identity',
                      style: TextStyle(
                        color: Color(0xFFFFA726),
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'For security, please verify your identity',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24.h),

        // ── Error ──
        if (_errorMessage != null) ...[_buildError(), SizedBox(height: 16.h)],

        if (isGoogle) ...[
          // ── Google Re-auth ──
          Text(
            'You signed in with Google.\nPlease verify by signing in again.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14.sp,
              height: 1.5,
            ),
          ),
          SizedBox(height: 24.h),

          SizedBox(
            width: double.infinity,
            height: 54.h,
            child: OutlinedButton(
              onPressed: _isDeleting ? null : _reauthAndDelete,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.15)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: _isDeleting
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
                          'Verify with Google',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ] else ...[
          // ── Email Re-auth ──
          Text(
            'Enter your password to verify:',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 12.h),

          // Email display
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.email_outlined,
                  color: Colors.white.withOpacity(0.4),
                  size: 18.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  _dataSummary?.email ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),

          // Password
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            style: TextStyle(color: Colors.white, fontSize: 15.sp),
            cursorColor: Color(0xFFEF5350),
            decoration: InputDecoration(
              hintText: 'Enter your password',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
              prefixIcon: Icon(
                Icons.lock_outline_rounded,
                color: Colors.white.withOpacity(0.35),
                size: 20.sp,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: Colors.white.withOpacity(0.35),
                  size: 20.sp,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
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
                borderSide: BorderSide(color: Color(0xFFEF5350), width: 1.5),
              ),
            ),
          ),
          SizedBox(height: 24.h),

          // Verify & Delete Button
          SizedBox(
            width: double.infinity,
            height: 54.h,
            child: ElevatedButton(
              onPressed: _isDeleting ? null : _reauthAndDelete,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFEF5350),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Color(0xFFEF5350).withOpacity(0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: _isDeleting
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
                        Icon(Icons.delete_forever_rounded, size: 20.sp),
                        SizedBox(width: 10.w),
                        Text(
                          'Verify & Delete Account',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],

        SizedBox(height: 12.h),

        // Cancel
        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: TextButton(
            onPressed: _isDeleting ? null : () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ╔══════════════════════════════╗
  // ║   STEP 3: DELETING          ║
  // ╚══════════════════════════════╝
  Widget _buildDeletingStep() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 60.r,
              height: 60.r,
              child: CircularProgressIndicator(
                color: Color(0xFFEF5350),
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Deleting Your Account...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Please wait while we remove all your data.\n'
              'This may take a few moments.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 13.sp,
                height: 1.5,
              ),
            ),
            SizedBox(height: 24.h),
            _buildDeletionProgress(),
          ],
        ),
      ),
    );
  }

  Widget _buildDeletionProgress() {
    return Column(
      children: [
        _buildProgressItem('Deleting CVs...', true),
        _buildProgressItem('Removing personal data...', true),
        _buildProgressItem('Deleting account...', true),
        _buildProgressItem('Cleaning up...', false),
      ],
    );
  }

  Widget _buildProgressItem(String text, bool done) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          done
              ? Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF4CAF50),
                  size: 18.sp,
                )
              : SizedBox(
                  width: 18.r,
                  height: 18.r,
                  child: CircularProgressIndicator(
                    color: Colors.white.withOpacity(0.3),
                    strokeWidth: 2,
                  ),
                ),
          SizedBox(width: 10.w),
          Text(
            text,
            style: TextStyle(
              color: done
                  ? Colors.white.withOpacity(0.6)
                  : Colors.white.withOpacity(0.3),
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    );
  }

  // ╔══════════════════════════════╗
  // ║   ERROR WIDGET              ║
  // ╚══════════════════════════════╝
  Widget _buildError() {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Color(0xFFEF5350).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
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
              style: TextStyle(color: Color(0xFFEF5350), fontSize: 13.sp),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() => _errorMessage = null);
            },
            child: Icon(
              Icons.close_rounded,
              color: Color(0xFFEF5350),
              size: 18.sp,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
