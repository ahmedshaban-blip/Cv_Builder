// lib/screens/settings/delete_account_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/account_deletion_service.dart';
import '../auth/login_screen.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState
    extends State<DeleteAccountScreen>
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
      _confirmTextController.text.trim().toUpperCase() ==
          'DELETE';

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
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeIn,
      ),
    );
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
    final summary =
        await _deletionService.getAccountDataSummary();
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
      reauthResult =
          await _deletionService.reauthenticateWithGoogle();
    } else {
      if (_passwordController.text.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter your password';
          _isDeleting = false;
        });
        return;
      }
      reauthResult =
          await _deletionService.reauthenticateWithEmail(
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
    final deleteResult =
        await _deletionService.deleteAccount();

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
        backgroundColor: const Color(0xFF1A1F38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50)
                    .withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF4CAF50),
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Account Deleted',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your account and all associated data\n'
              'have been permanently deleted.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );

    // Navigate after delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          ),
          (route) => false,
        );
      }
    });
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
        child: _isLoading
            ? _buildLoading()
            : FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    _buildAppBar(),
                    Expanded(
                      child: SingleChildScrollView(
                        physics:
                            const BouncingScrollPhysics(),
                        padding:
                            const EdgeInsets.fromLTRB(
                          20, 8, 20, 40,
                        ),
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
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFFEF5350),
      ),
    );
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
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: _isDeleting
                ? null
                : () {
                    if (_currentStep > 0 &&
                        _currentStep < 3) {
                      setState(() => _currentStep--);
                    } else {
                      Navigator.pop(context);
                    }
                  },
            icon: Icon(
              Icons.arrow_back_rounded,
              color: _isDeleting
                  ? Colors.white.withOpacity(0.3)
                  : Colors.white,
            ),
          ),
          const Expanded(
            child: Text(
              'Delete Account',
              style: TextStyle(
                color: Color(0xFFEF5350),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Step indicator
          if (_currentStep < 3)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFEF5350)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Step ${_currentStep + 1}/3',
                style: const TextStyle(
                  color: Color(0xFFEF5350),
                  fontSize: 11,
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
        const SizedBox(height: 24),

        // ── Account Summary ──
        _buildAccountSummary(),
        const SizedBox(height: 24),

        // ── What Will Be Deleted ──
        _buildDeletionDetails(),
        const SizedBox(height: 24),

        // ── Important Notice ──
        _buildImportantNotice(),
        const SizedBox(height: 32),

        // ── Proceed Button ──
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              setState(() => _currentStep = 1);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFFEF5350).withOpacity(0.15),
              foregroundColor: const Color(0xFFEF5350),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: const Color(0xFFEF5350)
                      .withOpacity(0.3),
                ),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'I Understand, Continue',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Cancel Button ──
        SizedBox(
          width: double.infinity,
          height: 52,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withOpacity(0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Cancel, Keep My Account',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWarningHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFEF5350).withOpacity(0.12),
            const Color(0xFFC62828).withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFEF5350).withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFEF5350)
                  .withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: Color(0xFFEF5350),
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Delete Your Account?',
            style: TextStyle(
              color: Color(0xFFEF5350),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This action is permanent and cannot be undone.\n'
            'All your data will be permanently removed.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_circle_outlined,
                color: Colors.white.withOpacity(0.5),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Account Summary',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildSummaryRow(
            '👤',
            'Name',
            _dataSummary?.displayName ?? 'N/A',
          ),
          _buildSummaryRow(
            '📧',
            'Email',
            _dataSummary?.email ?? 'N/A',
          ),
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

  Widget _buildSummaryRow(
    String emoji,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEF5350).withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEF5350).withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.delete_forever_rounded,
                color: Color(0xFFEF5350),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'What Will Be Deleted',
                style: TextStyle(
                  color: Color(0xFFEF5350),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildDeleteItem(
            'Your account and login credentials',
          ),
          _buildDeleteItem(
            'All ${_dataSummary?.cvCount ?? 0} CVs you created',
          ),
          _buildDeleteItem(
            'Personal information (name, email, phone)',
          ),
          _buildDeleteItem(
            'Professional data (education, experience, skills)',
          ),
          _buildDeleteItem(
            'All saved drafts and templates preferences',
          ),
          _buildDeleteItem(
            'Profile data and settings',
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.close_rounded,
              color: Color(0xFFEF5350),
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFA726).withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFA726).withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Color(0xFFFFA726),
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Before You Delete',
                style: TextStyle(
                  color: Color(0xFFFFA726),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '• Download any CVs you want to keep as PDF\n'
            '• This action cannot be reversed\n'
            '• You can create a new account later,\n'
            '  but your data will not be recovered',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEF5350).withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFEF5350)
                  .withOpacity(0.12),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.checklist_rounded,
                color: Color(0xFFEF5350),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Confirm Deletion',
                      style: TextStyle(
                        color: Color(0xFFEF5350),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Please confirm each item below',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Error Banner ──
        if (_errorMessage != null) ...[
          _buildError(),
          const SizedBox(height: 16),
        ],

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
        const SizedBox(height: 12),

        _buildConfirmCheckbox(
          value: _confirmCheck2,
          text:
              'I have downloaded any CVs I want to keep',
          onChanged: (v) {
            setState(() => _confirmCheck2 = v ?? false);
          },
        ),
        const SizedBox(height: 12),

        _buildConfirmCheckbox(
          value: _confirmCheck3,
          text:
              'I understand this action cannot be undone '
              'and my account cannot be recovered',
          onChanged: (v) {
            setState(() => _confirmCheck3 = v ?? false);
          },
        ),
        const SizedBox(height: 24),

        // ── Type DELETE ──
        Text(
          'Type "DELETE" to confirm',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _confirmTextController,
          onChanged: (_) => setState(() {}),
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(
            color: Color(0xFFEF5350),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
          ),
          cursorColor: const Color(0xFFEF5350),
          decoration: InputDecoration(
            hintText: 'DELETE',
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.15),
              fontSize: 18,
              letterSpacing: 4,
            ),
            filled: true,
            fillColor: const Color(0xFFEF5350)
                .withOpacity(0.04),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: const Color(0xFFEF5350)
                    .withOpacity(0.15),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: const Color(0xFFEF5350)
                    .withOpacity(0.15),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFEF5350),
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // ── Delete Button ──
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _allConfirmed
                ? _executeAccountDeletion
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF5350),
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  const Color(0xFFEF5350).withOpacity(0.2),
              disabledForegroundColor:
                  Colors.white.withOpacity(0.3),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_forever_rounded,
                    size: 20),
                SizedBox(width: 10),
                Text(
                  'Permanently Delete Account',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Cancel ──
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: value
              ? const Color(0xFFEF5350).withOpacity(0.06)
              : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value
                ? const Color(0xFFEF5350).withOpacity(0.25)
                : Colors.white.withOpacity(0.06),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: value
                    ? const Color(0xFFEF5350)
                    : Colors.transparent,
                border: Border.all(
                  color: value
                      ? const Color(0xFFEF5350)
                      : Colors.white.withOpacity(0.25),
                  width: 1.5,
                ),
              ),
              child: value
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: value
                      ? Colors.white.withOpacity(0.8)
                      : Colors.white.withOpacity(0.5),
                  fontSize: 13,
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
    final isGoogle =
        _dataSummary?.authProvider == 'google';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFA726).withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFFA726)
                  .withOpacity(0.12),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFFFFA726),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Verify Your Identity',
                      style: TextStyle(
                        color: Color(0xFFFFA726),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'For security, please verify your identity',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Error ──
        if (_errorMessage != null) ...[
          _buildError(),
          const SizedBox(height: 16),
        ],

        if (isGoogle) ...[
          // ── Google Re-auth ──
          Text(
            'You signed in with Google.\nPlease verify by signing in again.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton(
              onPressed:
                  _isDeleting ? null : _reauthAndDelete,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: Colors.white.withOpacity(0.15),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isDeleting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(6),
                          ),
                          padding:
                              const EdgeInsets.all(3),
                          child: const Text(
                            'G',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4285F4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Verify with Google',
                          style: TextStyle(
                            fontSize: 15,
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
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),

          // Email display
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.email_outlined,
                  color: Colors.white.withOpacity(0.4),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _dataSummary?.email ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Password
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
            cursorColor: const Color(0xFFEF5350),
            decoration: InputDecoration(
              hintText: 'Enter your password',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.2),
              ),
              prefixIcon: Icon(
                Icons.lock_outline_rounded,
                color: Colors.white.withOpacity(0.35),
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: Colors.white.withOpacity(0.35),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible =
                        !_isPasswordVisible;
                  });
                },
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFFEF5350),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Verify & Delete Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed:
                  _isDeleting ? null : _reauthAndDelete,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF5350),
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    const Color(0xFFEF5350)
                        .withOpacity(0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isDeleting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete_forever_rounded,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Verify & Delete Account',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],

        const SizedBox(height: 12),

        // Cancel
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton(
            onPressed: _isDeleting
                ? null
                : () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
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
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                color: Color(0xFFEF5350),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Deleting Your Account...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we remove all your data.\n'
              'This may take a few moments.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          done
              ? const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF4CAF50),
                  size: 18,
                )
              : SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white.withOpacity(0.3),
                    strokeWidth: 2,
                  ),
                ),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              color: done
                  ? Colors.white.withOpacity(0.6)
                  : Colors.white.withOpacity(0.3),
              fontSize: 13,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEF5350).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEF5350).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFEF5350),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Color(0xFFEF5350),
                fontSize: 13,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() => _errorMessage = null);
            },
            child: const Icon(
              Icons.close_rounded,
              color: Color(0xFFEF5350),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}