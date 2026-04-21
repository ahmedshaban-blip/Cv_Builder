// lib/screens/preview/cv_preview_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';

import '../cv_builder/cv_builder_screen.dart';

class CVPreviewScreen extends StatefulWidget {
  final String? cvId;

  const CVPreviewScreen({super.key, this.cvId});
  static const routeName = '/cv_preview';

  @override
  State<CVPreviewScreen> createState() => _CVPreviewScreenState();
}

class _CVPreviewScreenState extends State<CVPreviewScreen>
    with SingleTickerProviderStateMixin {
  // ══════════════════════════════════
  // 🔥 Firebase
  // ══════════════════════════════════
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  User? get _currentUser => _auth.currentUser;

  // ══════════════════════════════════
  // 🔄 State
  // ══════════════════════════════════
  Map<String, dynamic>? _cvData;
  bool _isLoading = true;
  bool _isGenerating = false;
  String? _errorMessage;
  Uint8List? _pdfBytes;

  // ══════════════════════════════════
  // 🎬 Animation
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
    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoading && _cvData == null && _errorMessage == null) {
      _loadCV();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════
  // 📂 LOAD CV DATA
  // ══════════════════════════════════════════
  Future<void> _loadCV() async {
    final String? id =
        widget.cvId ?? ModalRoute.of(context)?.settings.arguments as String?;

    if (id == null) {
      setState(() {
        _errorMessage = 'No CV ID provided';
        _isLoading = false;
      });
      return;
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('cvs')
          .doc(id)
          .get();

      if (!doc.exists) {
        setState(() {
          _errorMessage = 'CV not found';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _cvData = doc.data() as Map<String, dynamic>;
        _isLoading = false;
      });

      _fadeController.forward();

      // Generate PDF
      await _generatePDF();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load CV: $e';
        _isLoading = false;
      });
    }
  }

  // ══════════════════════════════════════════
  // 📄 GENERATE PDF
  // ══════════════════════════════════════════
  Future<void> _generatePDF() async {
    if (_cvData == null) return;

    setState(() => _isGenerating = true);

    try {
      final templateId = _cvData!['templateId'] ?? 'classic';

      pw.Document pdf;
      if (templateId == 'classic') {
        pdf = await _generateClassicPDF();
      } else {
        pdf = await _generateModernPDF();
      }

      final bytes = await pdf.save();
      setState(() {
        _pdfBytes = bytes;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _errorMessage = 'Failed to generate PDF';
      });
    }
  }

  // ══════════════════════════════════════════
  // 📄 CLASSIC TEMPLATE PDF
  // ══════════════════════════════════════════
  Future<pw.Document> _generateClassicPDF() async {
    final pdf = pw.Document();
    final personalInfo =
        _cvData!['personalInfo'] as Map<String, dynamic>? ?? {};
    final education = List<Map<String, dynamic>>.from(
      _cvData!['education'] ?? [],
    );
    final experience = List<Map<String, dynamic>>.from(
      _cvData!['experience'] ?? [],
    );
    final skills = List<String>.from(_cvData!['skills'] ?? []);
    final projects = List<Map<String, dynamic>>.from(
      _cvData!['projects'] ?? [],
    );
    final summary = _cvData!['summary'] ?? '';

    // Load font
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();
    final fontSemiBold = await PdfGoogleFonts.nunitoSemiBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(40.r),
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (context) => [
          // ═══════════════════════
          // HEADER
          // ═══════════════════════
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  (personalInfo['fullName'] ?? '').toString().toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 22.sp,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                if (personalInfo['jobTitle'] != null &&
                    personalInfo['jobTitle'].toString().isNotEmpty)
                  pw.Padding(
                    padding: pw.EdgeInsets.only(top: 2.h),
                    child: pw.Text(
                      personalInfo['jobTitle'],
                      style: pw.TextStyle(
                        fontSize: 12.sp,
                        color: PdfColors.grey700,
                        font: fontSemiBold,
                      ),
                    ),
                  ),
                pw.SizedBox(height: 6.h),
                pw.Text(
                  _buildContactLine(personalInfo),
                  style: pw.TextStyle(fontSize: 9.sp, color: PdfColors.grey600),
                  textAlign: pw.TextAlign.center,
                ),
                if (_buildLinksLine(personalInfo).isNotEmpty)
                  pw.Padding(
                    padding: pw.EdgeInsets.only(top: 2.h),
                    child: pw.Text(
                      _buildLinksLine(personalInfo),
                      style: pw.TextStyle(
                        fontSize: 8.sp,
                        color: PdfColors.blue800,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 4.h),
          pw.Divider(thickness: 1.5),
          pw.SizedBox(height: 8.h),

          // ═══════════════════════
          // SUMMARY
          // ═══════════════════════
          if (summary.toString().isNotEmpty) ...[
            _classicSectionTitle('PROFESSIONAL SUMMARY'),
            pw.SizedBox(height: 4.h),
            pw.Text(
              summary,
              style: pw.TextStyle(fontSize: 10.sp, lineSpacing: 2),
            ),
            pw.SizedBox(height: 12.h),
          ],

          // ═══════════════════════
          // EXPERIENCE
          // ═══════════════════════
          if (experience.isNotEmpty) ...[
            _classicSectionTitle('WORK EXPERIENCE'),
            pw.SizedBox(height: 4.h),
            ...experience.map((exp) => _classicExperience(exp)),
            pw.SizedBox(height: 8.h),
          ],

          // ═══════════════════════
          // EDUCATION
          // ═══════════════════════
          if (education.isNotEmpty) ...[
            _classicSectionTitle('EDUCATION'),
            pw.SizedBox(height: 4.h),
            ...education.map((edu) => _classicEducation(edu)),
            pw.SizedBox(height: 8.h),
          ],

          // ═══════════════════════
          // SKILLS
          // ═══════════════════════
          if (skills.isNotEmpty) ...[
            _classicSectionTitle('SKILLS'),
            pw.SizedBox(height: 4.h),
            pw.Text(
              skills.join('  •  '),
              style: pw.TextStyle(fontSize: 10.sp, lineSpacing: 3),
            ),
            pw.SizedBox(height: 8.h),
          ],

          // ═══════════════════════
          // PROJECTS
          // ═══════════════════════
          if (projects.isNotEmpty) ...[
            _classicSectionTitle('PROJECTS'),
            pw.SizedBox(height: 4.h),
            ...projects.map((proj) => _classicProject(proj)),
          ],
        ],
      ),
    );

    return pdf;
  }

  // ── Classic Helpers ──
  pw.Widget _classicSectionTitle(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 12.sp,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        pw.Divider(thickness: 0.8),
      ],
    );
  }

  pw.Widget _classicExperience(Map<String, dynamic> exp) {
    final responsibilities = List<String>.from(exp['responsibilities'] ?? []);

    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: 10.h),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                exp['position'] ?? '',
                style: pw.TextStyle(
                  fontSize: 11.sp,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                '${exp['startDate'] ?? ''} - ${exp['isCurrently'] == true ? 'Present' : exp['endDate'] ?? ''}',
                style: pw.TextStyle(fontSize: 9.sp, color: PdfColors.grey600),
              ),
            ],
          ),
          pw.Row(
            children: [
              pw.Text(
                exp['company'] ?? '',
                style: pw.TextStyle(fontSize: 10.sp, color: PdfColors.grey700),
              ),
              if (exp['location'] != null &&
                  exp['location'].toString().isNotEmpty)
                pw.Text(
                  '  |  ${exp['location']}',
                  style: pw.TextStyle(fontSize: 9.sp, color: PdfColors.grey500),
                ),
            ],
          ),
          if (responsibilities.isNotEmpty) pw.SizedBox(height: 3.h),
          ...responsibilities.map(
            (r) => pw.Padding(
              padding: pw.EdgeInsets.only(left: 12.w, bottom: 2.h),
              child: pw.Text('• $r', style: pw.TextStyle(fontSize: 9.5.sp)),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _classicEducation(Map<String, dynamic> edu) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: 8.h),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '${edu['degree'] ?? ''} in ${edu['fieldOfStudy'] ?? ''}',
                  style: pw.TextStyle(
                    fontSize: 11.sp,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  edu['institution'] ?? '',
                  style: pw.TextStyle(
                    fontSize: 10.sp,
                    color: PdfColors.grey700,
                  ),
                ),
                if (edu['gpa'] != null && edu['gpa'].toString().isNotEmpty)
                  pw.Text(
                    'GPA: ${edu['gpa']}',
                    style: pw.TextStyle(
                      fontSize: 9.sp,
                      color: PdfColors.grey600,
                    ),
                  ),
              ],
            ),
          ),
          pw.Text(
            '${edu['startDate'] ?? ''} - ${edu['isCurrently'] == true ? 'Present' : edu['endDate'] ?? ''}',
            style: pw.TextStyle(fontSize: 9.sp, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _classicProject(Map<String, dynamic> proj) {
    final technologies = List<String>.from(proj['technologies'] ?? []);

    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: 8.h),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Text(
                proj['title'] ?? '',
                style: pw.TextStyle(
                  fontSize: 11.sp,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (proj['link'] != null && proj['link'].toString().isNotEmpty)
                pw.Padding(
                  padding: pw.EdgeInsets.only(left: 6.w),
                  child: pw.Text(
                    '(${proj['link']})',
                    style: pw.TextStyle(
                      fontSize: 8.sp,
                      color: PdfColors.blue700,
                    ),
                  ),
                ),
            ],
          ),
          if (proj['description'] != null)
            pw.Text(proj['description'], style: pw.TextStyle(fontSize: 9.5.sp)),
          if (technologies.isNotEmpty)
            pw.Padding(
              padding: pw.EdgeInsets.only(top: 2.h),
              child: pw.Text(
                'Technologies: ${technologies.join(", ")}',
                style: pw.TextStyle(fontSize: 8.5.sp, color: PdfColors.grey600),
              ),
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // 📄 MODERN TEMPLATE PDF
  // ══════════════════════════════════════════
  Future<pw.Document> _generateModernPDF() async {
    final pdf = pw.Document();
    final personalInfo =
        _cvData!['personalInfo'] as Map<String, dynamic>? ?? {};
    final education = List<Map<String, dynamic>>.from(
      _cvData!['education'] ?? [],
    );
    final experience = List<Map<String, dynamic>>.from(
      _cvData!['experience'] ?? [],
    );
    final skills = List<String>.from(_cvData!['skills'] ?? []);
    final projects = List<Map<String, dynamic>>.from(
      _cvData!['projects'] ?? [],
    );
    final summary = _cvData!['summary'] ?? '';

    final accentColor = PdfColors.blueGrey800;

    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();
    final fontSemiBold = await PdfGoogleFonts.nunitoSemiBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(36.r),
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (context) => [
          // ═══════════════════════
          // HEADER
          // ═══════════════════════
          pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.all(16.r),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(6.r)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  (personalInfo['fullName'] ?? '').toString().toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 24.sp,
                    fontWeight: pw.FontWeight.bold,
                    color: accentColor,
                    letterSpacing: 1,
                  ),
                ),
                if (personalInfo['jobTitle'] != null &&
                    personalInfo['jobTitle'].toString().isNotEmpty)
                  pw.Text(
                    personalInfo['jobTitle'],
                    style: pw.TextStyle(
                      fontSize: 13.sp,
                      color: PdfColors.grey700,
                      font: fontSemiBold,
                    ),
                  ),
                pw.SizedBox(height: 8.h),
                pw.Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    if (personalInfo['email'] != null)
                      _modernContact(personalInfo['email']),
                    if (personalInfo['phone'] != null)
                      _modernContact(personalInfo['phone']),
                    if (personalInfo['address'] != null &&
                        personalInfo['address'].toString().isNotEmpty)
                      _modernContact(personalInfo['address']),
                    if (personalInfo['linkedIn'] != null &&
                        personalInfo['linkedIn'].toString().isNotEmpty)
                      _modernContact(personalInfo['linkedIn']),
                    if (personalInfo['github'] != null &&
                        personalInfo['github'].toString().isNotEmpty)
                      _modernContact(personalInfo['github']),
                    if (personalInfo['portfolio'] != null &&
                        personalInfo['portfolio'].toString().isNotEmpty)
                      _modernContact(personalInfo['portfolio']),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14.h),

          // ═══════════════════════
          // SUMMARY
          // ═══════════════════════
          if (summary.toString().isNotEmpty) ...[
            _modernSectionTitle('PROFESSIONAL SUMMARY', accentColor),
            pw.Padding(
              padding: pw.EdgeInsets.only(left: 8.w, bottom: 12.h),
              child: pw.Text(
                summary,
                style: pw.TextStyle(fontSize: 10.sp, lineSpacing: 2),
              ),
            ),
          ],

          // ═══════════════════════
          // EXPERIENCE
          // ═══════════════════════
          if (experience.isNotEmpty) ...[
            _modernSectionTitle('WORK EXPERIENCE', accentColor),
            ...experience.map((exp) => _modernExperience(exp, accentColor)),
          ],

          // ═══════════════════════
          // EDUCATION
          // ═══════════════════════
          if (education.isNotEmpty) ...[
            _modernSectionTitle('EDUCATION', accentColor),
            ...education.map((edu) => _modernEducation(edu, accentColor)),
          ],

          // ═══════════════════════
          // SKILLS
          // ═══════════════════════
          if (skills.isNotEmpty) ...[
            _modernSectionTitle('SKILLS', accentColor),
            pw.Padding(
              padding: pw.EdgeInsets.only(left: 8.w, bottom: 12.h),
              child: pw.Wrap(
                spacing: 6,
                runSpacing: 6,
                children: skills.map((skill) {
                  return pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: accentColor, width: 0.5),
                      borderRadius: pw.BorderRadius.all(
                        pw.Radius.circular(3.r),
                      ),
                    ),
                    child: pw.Text(
                      skill,
                      style: pw.TextStyle(fontSize: 9.sp, color: accentColor),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // ═══════════════════════
          // PROJECTS
          // ═══════════════════════
          if (projects.isNotEmpty) ...[
            _modernSectionTitle('PROJECTS', accentColor),
            ...projects.map((proj) => _modernProject(proj, accentColor)),
          ],
        ],
      ),
    );

    return pdf;
  }

  // ── Modern Helpers ──
  pw.Widget _modernContact(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(fontSize: 9.sp, color: PdfColors.grey700),
    );
  }

  pw.Widget _modernSectionTitle(String title, PdfColor color) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: 6.h),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 12.sp,
              fontWeight: pw.FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          pw.Container(
            height: 2.h,
            width: double.infinity,
            color: color,
            margin: pw.EdgeInsets.only(top: 2.h),
          ),
          pw.SizedBox(height: 6.h),
        ],
      ),
    );
  }

  pw.Widget _modernExperience(Map<String, dynamic> exp, PdfColor color) {
    final responsibilities = List<String>.from(exp['responsibilities'] ?? []);

    return pw.Padding(
      padding: pw.EdgeInsets.only(left: 8.w, bottom: 12.h),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            exp['position'] ?? '',
            style: pw.TextStyle(
              fontSize: 11.sp,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Row(
                children: [
                  pw.Text(
                    exp['company'] ?? '',
                    style: pw.TextStyle(
                      fontSize: 10.sp,
                      color: PdfColors.grey700,
                    ),
                  ),
                  if (exp['location'] != null &&
                      exp['location'].toString().isNotEmpty)
                    pw.Text(
                      '  |  ${exp['location']}',
                      style: pw.TextStyle(
                        fontSize: 9.sp,
                        color: PdfColors.grey500,
                      ),
                    ),
                ],
              ),
              pw.Text(
                '${exp['startDate'] ?? ''} - ${exp['isCurrently'] == true ? 'Present' : exp['endDate'] ?? ''}',
                style: pw.TextStyle(fontSize: 9.sp, color: PdfColors.grey500),
              ),
            ],
          ),
          if (responsibilities.isNotEmpty) pw.SizedBox(height: 3.h),
          ...responsibilities.map(
            (r) => pw.Padding(
              padding: pw.EdgeInsets.only(left: 8.w, bottom: 2.h),
              child: pw.Text('• $r', style: pw.TextStyle(fontSize: 9.5.sp)),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _modernEducation(Map<String, dynamic> edu, PdfColor color) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(left: 8.w, bottom: 8.h),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '${edu['degree'] ?? ''} in ${edu['fieldOfStudy'] ?? ''}',
                  style: pw.TextStyle(
                    fontSize: 11.sp,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  edu['institution'] ?? '',
                  style: pw.TextStyle(
                    fontSize: 10.sp,
                    color: PdfColors.grey600,
                  ),
                ),
                if (edu['gpa'] != null && edu['gpa'].toString().isNotEmpty)
                  pw.Text(
                    'GPA: ${edu['gpa']}',
                    style: pw.TextStyle(
                      fontSize: 9.sp,
                      color: PdfColors.grey500,
                    ),
                  ),
              ],
            ),
          ),
          pw.Text(
            '${edu['startDate'] ?? ''} - ${edu['isCurrently'] == true ? 'Present' : edu['endDate'] ?? ''}',
            style: pw.TextStyle(fontSize: 9.sp, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  pw.Widget _modernProject(Map<String, dynamic> proj, PdfColor color) {
    final technologies = List<String>.from(proj['technologies'] ?? []);

    return pw.Padding(
      padding: pw.EdgeInsets.only(left: 8.w, bottom: 8.h),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Text(
                proj['title'] ?? '',
                style: pw.TextStyle(
                  fontSize: 11.sp,
                  fontWeight: pw.FontWeight.bold,
                  color: color,
                ),
              ),
              if (proj['link'] != null && proj['link'].toString().isNotEmpty)
                pw.Padding(
                  padding: pw.EdgeInsets.only(left: 6.w),
                  child: pw.Text(
                    '(${proj['link']})',
                    style: pw.TextStyle(
                      fontSize: 8.sp,
                      color: PdfColors.blue700,
                    ),
                  ),
                ),
            ],
          ),
          if (proj['description'] != null)
            pw.Text(proj['description'], style: pw.TextStyle(fontSize: 9.5.sp)),
          if (technologies.isNotEmpty)
            pw.Padding(
              padding: pw.EdgeInsets.only(top: 2.h),
              child: pw.Text(
                'Tech: ${technologies.join(", ")}',
                style: pw.TextStyle(fontSize: 8.5.sp, color: PdfColors.grey600),
              ),
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // 🔧 UTILITY METHODS
  // ══════════════════════════════════════════
  String _buildContactLine(Map<String, dynamic> info) {
    final parts = <String>[];
    if (info['email'] != null && info['email'].toString().isNotEmpty) {
      parts.add(info['email']);
    }
    if (info['phone'] != null && info['phone'].toString().isNotEmpty) {
      parts.add(info['phone']);
    }
    if (info['address'] != null && info['address'].toString().isNotEmpty) {
      parts.add(info['address']);
    }
    return parts.join('  |  ');
  }

  String _buildLinksLine(Map<String, dynamic> info) {
    final parts = <String>[];
    if (info['linkedIn'] != null && info['linkedIn'].toString().isNotEmpty) {
      parts.add(info['linkedIn']);
    }
    if (info['github'] != null && info['github'].toString().isNotEmpty) {
      parts.add(info['github']);
    }
    if (info['portfolio'] != null && info['portfolio'].toString().isNotEmpty) {
      parts.add(info['portfolio']);
    }
    return parts.join('  |  ');
  }

  // ══════════════════════════════════════════
  // 📥 DOWNLOAD PDF
  // ══════════════════════════════════════════
  Future<void> _downloadPDF() async {
    if (_pdfBytes == null) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          '${_cvData!['cvTitle'] ?? 'CV'}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(_pdfBytes!);

      if (mounted) {
        _showSnackBar('✅ PDF saved to: ${file.path}', const Color(0xFF4CAF50));
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('❌ Failed to save PDF', const Color(0xFFEF5350));
      }
    }
  }

  // ══════════════════════════════════════════
  // 📤 SHARE PDF
  // ══════════════════════════════════════════
  Future<void> _sharePDF() async {
    if (_pdfBytes == null) return;

    try {
      final dir = await getTemporaryDirectory();
      final fileName = '${_cvData!['cvTitle'] ?? 'CV'}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(_pdfBytes!);

      await Share.shareXFiles([XFile(file.path)], text: 'My Professional CV');
    } catch (e) {
      if (mounted) {
        _showSnackBar('❌ Failed to share PDF', const Color(0xFFEF5350));
      }
    }
  }

  // ══════════════════════════════════════════
  // 🖨️ PRINT PDF
  // ══════════════════════════════════════════
  Future<void> _printPDF() async {
    if (_pdfBytes == null) return;

    try {
      await Printing.layoutPdf(
        onLayout: (_) => _pdfBytes!,
        name: _cvData!['cvTitle'] ?? 'CV',
      );
    } catch (e) {
      if (mounted) {
        _showSnackBar('❌ Failed to print', const Color(0xFFEF5350));
      }
    }
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
      backgroundColor: const Color(0xFF0A0E21),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
          ? _buildErrorState()
          : SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    // ── App Bar ──
                    _buildAppBar(),

                    // ── CV Info Card ──
                    _buildCVInfoCard(),

                    // ── PDF Preview ──
                    Expanded(child: _buildPDFPreview()),

                    // ── Action Buttons ──
                    _buildActionBar(),
                  ],
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
            'Generating your CV...',
            style: TextStyle(color: Colors.white54, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }

  // ╔══════════════════════════════╗
  // ║     ERROR STATE             ║
  // ╚══════════════════════════════╝
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFEF5350),
              size: 56.sp,
            ),
            SizedBox(height: 16.h),
            Text(
              'Something went wrong',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _errorMessage ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadCV();
              },
              icon: Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ╔══════════════════════════════╗
  // ║     APP BAR                 ║
  // ╚══════════════════════════════╝
  Widget _buildAppBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(8.w, 8.h, 16.w, 0.h),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          Expanded(
            child: Text(
              'CV Preview',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          // ── Edit Button ──
          _buildAppBarAction(Icons.edit_outlined, 'Edit', () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => CVBuilderScreen(cvId: widget.cvId),
              ),
            );
          }),
          SizedBox(width: 8.w),

          // ── More Options ──
          _buildAppBarAction(
            Icons.more_vert_rounded,
            null,
            () => _showMoreOptions(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarAction(IconData icon, String? label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: label != null ? 12 : 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.6), size: 18.sp),
            if (label != null) ...[
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ╔══════════════════════════════╗
  // ║     CV INFO CARD            ║
  // ╚══════════════════════════════╝
  Widget _buildCVInfoCard() {
    if (_cvData == null) return const SizedBox.shrink();

    final templateId = _cvData!['templateId'] ?? 'classic';
    final isClassic = templateId == 'classic';
    final templateColor = isClassic
        ? const Color(0xFF66BB6A)
        : const Color(0xFFFFA726);
    final personalInfo =
        _cvData!['personalInfo'] as Map<String, dynamic>? ?? {};

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            // Template Badge
            Container(
              width: 44.r,
              height: 44.r,
              decoration: BoxDecoration(
                color: templateColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                isClassic
                    ? Icons.article_outlined
                    : Icons.auto_awesome_outlined,
                color: templateColor,
                size: 22.sp,
              ),
            ),
            SizedBox(width: 12.w),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _cvData!['cvTitle'] ?? 'My CV',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: templateColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          isClassic ? 'Classic' : 'Modern',
                          style: TextStyle(
                            color: templateColor,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        personalInfo['fullName'] ?? '',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ATS Badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_outlined,
                    color: Color(0xFF4CAF50),
                    size: 14.sp,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'ATS',
                    style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
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
  // ║     PDF PREVIEW             ║
  // ╚══════════════════════════════╝
  Widget _buildPDFPreview() {
    if (_isGenerating || _pdfBytes == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF2196F3)),
            SizedBox(height: 16.h),
            Text(
              'Generating PDF...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: PdfPreview(
          build: (_) => _pdfBytes!,
          canChangeOrientation: false,
          canChangePageFormat: false,
          canDebug: false,
          allowPrinting: false,
          allowSharing: false,
          maxPageWidth: 700,
          pdfPreviewPageDecoration: BoxDecoration(color: Colors.white),
          loadingWidget: const Center(
            child: CircularProgressIndicator(color: Color(0xFF2196F3)),
          ),
          scrollViewDecoration: const BoxDecoration(color: Color(0xFF151928)),
        ),
      ),
    );
  }

  // ╔══════════════════════════════╗
  // ║     ACTION BAR              ║
  // ╚══════════════════════════════╝
  Widget _buildActionBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E21),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Row(
        children: [
          // ── Download ──
          _buildActionButton(
            icon: Icons.download_rounded,
            label: 'Save',
            color: const Color(0xFF2196F3),
            onTap: _downloadPDF,
          ),
          SizedBox(width: 10.w),

          // ── Share ──
          _buildActionButton(
            icon: Icons.share_rounded,
            label: 'Share',
            color: const Color(0xFF9C27B0),
            onTap: _sharePDF,
          ),
          SizedBox(width: 10.w),

          // ── Print ──
          _buildActionButton(
            icon: Icons.print_rounded,
            label: 'Print',
            color: const Color(0xFFFFA726),
            onTap: _printPDF,
          ),
          SizedBox(width: 10.w),

          // ── Edit ──
          Expanded(
            child: SizedBox(
              height: 50.h,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CVBuilderScreen(cvId: widget.cvId),
                    ),
                  );
                },
                icon: Icon(Icons.edit_rounded, size: 18.sp),
                label: Text(
                  'Edit CV',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60.w,
        height: 50.h,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20.sp),
            SizedBox(height: 2.h),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ╔══════════════════════════════╗
  // ║     MORE OPTIONS SHEET      ║
  // ╚══════════════════════════════╝
  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: Color(0xFF1A1F38),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
              'More Options',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 20.h),

            // ── Switch Template ──
            _buildOptionTile(
              Icons.palette_outlined,
              'Switch Template',
              'Change between Classic and Modern',
              const Color(0xFFE91E63),
              () async {
                Navigator.pop(context);
                final currentTemplate = _cvData!['templateId'] ?? 'classic';
                final newTemplate = currentTemplate == 'classic'
                    ? 'modern'
                    : 'classic';

                // Update in Firestore
                await _firestore
                    .collection('users')
                    .doc(_currentUser!.uid)
                    .collection('cvs')
                    .doc(widget.cvId)
                    .update({'templateId': newTemplate});

                // Reload
                setState(() {
                  _isLoading = true;
                  _pdfBytes = null;
                });
                _loadCV();
              },
            ),

            // ── Duplicate ──
            _buildOptionTile(
              Icons.copy_outlined,
              'Duplicate CV',
              'Create a copy of this CV',
              const Color(0xFF00BCD4),
              () async {
                Navigator.pop(context);
                await _duplicateCV();
              },
            ),

            // ── Download ──
            _buildOptionTile(
              Icons.picture_as_pdf_outlined,
              'Save as PDF',
              'Download to your device',
              const Color(0xFF2196F3),
              () {
                Navigator.pop(context);
                _downloadPDF();
              },
            ),

            // ── Print ──
            _buildOptionTile(
              Icons.print_outlined,
              'Print CV',
              'Send to printer',
              const Color(0xFFFFA726),
              () {
                Navigator.pop(context);
                _printPDF();
              },
            ),

            // ── Delete ──
            _buildOptionTile(
              Icons.delete_outline_rounded,
              'Delete CV',
              'Permanently remove this CV',
              const Color(0xFFEF5350),
              () {
                Navigator.pop(context);
                _showDeleteDialog();
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
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 42.r,
        height: 42.r,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(icon, color: color, size: 20.sp),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 14.sp,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11.sp),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: Colors.white.withOpacity(0.3),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
    );
  }

  // ══════════════════════════════════════════
  // 📋 DUPLICATE CV
  // ══════════════════════════════════════════
  Future<void> _duplicateCV() async {
    try {
      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      final newData = Map<String, dynamic>.from(_cvData!);
      newData['id'] = newId;
      newData['cvTitle'] = '${newData['cvTitle']} (Copy)';
      newData['createdAt'] = FieldValue.serverTimestamp();
      newData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('cvs')
          .doc(newId)
          .set(newData);

      if (mounted) {
        _showSnackBar('✅ CV duplicated successfully!', const Color(0xFF4CAF50));
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('❌ Failed to duplicate', const Color(0xFFEF5350));
      }
    }
  }

  // ══════════════════════════════════════════
  // 🗑️ DELETE DIALOG
  // ══════════════════════════════════════════
  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Color(0xFFEF5350), size: 24.sp),
            SizedBox(width: 10.w),
            Text(
              'Delete CV',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this CV?\nThis action cannot be undone.',
          style: TextStyle(color: Colors.white.withOpacity(0.6), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog

              try {
                await _firestore
                    .collection('users')
                    .doc(_currentUser!.uid)
                    .collection('cvs')
                    .doc(widget.cvId)
                    .delete();

                if (mounted) {
                  Navigator.pop(context); // Go back
                }
              } catch (e) {
                if (mounted) {
                  _showSnackBar('❌ Failed to delete', const Color(0xFFEF5350));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF5350),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
