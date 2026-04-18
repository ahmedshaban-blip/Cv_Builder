// lib/screens/preview/cv_preview_screen.dart
import 'package:flutter/material.dart';
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
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeIn,
      ),
    );
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
    final String? id = widget.cvId ?? ModalRoute.of(context)?.settings.arguments as String?;

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
      final templateId =
          _cvData!['templateId'] ?? 'classic';

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
        _cvData!['personalInfo'] as Map<String, dynamic>? ??
            {};
    final education = List<Map<String, dynamic>>.from(
        _cvData!['education'] ?? []);
    final experience = List<Map<String, dynamic>>.from(
        _cvData!['experience'] ?? []);
    final skills =
        List<String>.from(_cvData!['skills'] ?? []);
    final projects = List<Map<String, dynamic>>.from(
        _cvData!['projects'] ?? []);
    final summary = _cvData!['summary'] ?? '';

    // Load font
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();
    final fontSemiBold =
        await PdfGoogleFonts.nunitoSemiBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        build: (context) => [
          // ═══════════════════════
          // HEADER
          // ═══════════════════════
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  (personalInfo['fullName'] ?? '')
                      .toString()
                      .toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                if (personalInfo['jobTitle'] != null &&
                    personalInfo['jobTitle']
                        .toString()
                        .isNotEmpty)
                  pw.Padding(
                    padding:
                        const pw.EdgeInsets.only(top: 2),
                    child: pw.Text(
                      personalInfo['jobTitle'],
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                        font: fontSemiBold,
                      ),
                    ),
                  ),
                pw.SizedBox(height: 6),
                pw.Text(
                  _buildContactLine(personalInfo),
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                if (_buildLinksLine(personalInfo)
                    .isNotEmpty)
                  pw.Padding(
                    padding:
                        const pw.EdgeInsets.only(top: 2),
                    child: pw.Text(
                      _buildLinksLine(personalInfo),
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.blue800,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Divider(thickness: 1.5),
          pw.SizedBox(height: 8),

          // ═══════════════════════
          // SUMMARY
          // ═══════════════════════
          if (summary.toString().isNotEmpty) ...[
            _classicSectionTitle('PROFESSIONAL SUMMARY'),
            pw.SizedBox(height: 4),
            pw.Text(
              summary,
              style: const pw.TextStyle(
                fontSize: 10,
                lineSpacing: 2,
              ),
            ),
            pw.SizedBox(height: 12),
          ],

          // ═══════════════════════
          // EXPERIENCE
          // ═══════════════════════
          if (experience.isNotEmpty) ...[
            _classicSectionTitle('WORK EXPERIENCE'),
            pw.SizedBox(height: 4),
            ...experience
                .map((exp) => _classicExperience(exp)),
            pw.SizedBox(height: 8),
          ],

          // ═══════════════════════
          // EDUCATION
          // ═══════════════════════
          if (education.isNotEmpty) ...[
            _classicSectionTitle('EDUCATION'),
            pw.SizedBox(height: 4),
            ...education
                .map((edu) => _classicEducation(edu)),
            pw.SizedBox(height: 8),
          ],

          // ═══════════════════════
          // SKILLS
          // ═══════════════════════
          if (skills.isNotEmpty) ...[
            _classicSectionTitle('SKILLS'),
            pw.SizedBox(height: 4),
            pw.Text(
              skills.join('  •  '),
              style: const pw.TextStyle(
                fontSize: 10,
                lineSpacing: 3,
              ),
            ),
            pw.SizedBox(height: 8),
          ],

          // ═══════════════════════
          // PROJECTS
          // ═══════════════════════
          if (projects.isNotEmpty) ...[
            _classicSectionTitle('PROJECTS'),
            pw.SizedBox(height: 4),
            ...projects
                .map((proj) => _classicProject(proj)),
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
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        pw.Divider(thickness: 0.8),
      ],
    );
  }

  pw.Widget _classicExperience(Map<String, dynamic> exp) {
    final responsibilities =
        List<String>.from(exp['responsibilities'] ?? []);

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment:
                pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                exp['position'] ?? '',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                '${exp['startDate'] ?? ''} - ${exp['isCurrently'] == true ? 'Present' : exp['endDate'] ?? ''}',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
          pw.Row(
            children: [
              pw.Text(
                exp['company'] ?? '',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
              if (exp['location'] != null &&
                  exp['location'].toString().isNotEmpty)
                pw.Text(
                  '  |  ${exp['location']}',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey500,
                  ),
                ),
            ],
          ),
          if (responsibilities.isNotEmpty)
            pw.SizedBox(height: 3),
          ...responsibilities.map(
            (r) => pw.Padding(
              padding: const pw.EdgeInsets.only(
                left: 12,
                bottom: 2,
              ),
              child: pw.Text(
                '• $r',
                style: const pw.TextStyle(fontSize: 9.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _classicEducation(Map<String, dynamic> edu) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment:
            pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment:
                  pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '${edu['degree'] ?? ''} in ${edu['fieldOfStudy'] ?? ''}',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  edu['institution'] ?? '',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
                if (edu['gpa'] != null &&
                    edu['gpa'].toString().isNotEmpty)
                  pw.Text(
                    'GPA: ${edu['gpa']}',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
              ],
            ),
          ),
          pw.Text(
            '${edu['startDate'] ?? ''} - ${edu['isCurrently'] == true ? 'Present' : edu['endDate'] ?? ''}',
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _classicProject(Map<String, dynamic> proj) {
    final technologies =
        List<String>.from(proj['technologies'] ?? []);

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Text(
                proj['title'] ?? '',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (proj['link'] != null &&
                  proj['link'].toString().isNotEmpty)
                pw.Padding(
                  padding:
                      const pw.EdgeInsets.only(left: 6),
                  child: pw.Text(
                    '(${proj['link']})',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.blue700,
                    ),
                  ),
                ),
            ],
          ),
          if (proj['description'] != null)
            pw.Text(
              proj['description'],
              style: const pw.TextStyle(fontSize: 9.5),
            ),
          if (technologies.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                'Technologies: ${technologies.join(", ")}',
                style: const pw.TextStyle(
                  fontSize: 8.5,
                  color: PdfColors.grey600,
                ),
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
        _cvData!['personalInfo'] as Map<String, dynamic>? ??
            {};
    final education = List<Map<String, dynamic>>.from(
        _cvData!['education'] ?? []);
    final experience = List<Map<String, dynamic>>.from(
        _cvData!['experience'] ?? []);
    final skills =
        List<String>.from(_cvData!['skills'] ?? []);
    final projects = List<Map<String, dynamic>>.from(
        _cvData!['projects'] ?? []);
    final summary = _cvData!['summary'] ?? '';

    final accentColor = PdfColors.blueGrey800;

    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();
    final fontSemiBold =
        await PdfGoogleFonts.nunitoSemiBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        build: (context) => [
          // ═══════════════════════
          // HEADER
          // ═══════════════════════
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(
                pw.Radius.circular(6),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment:
                  pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  (personalInfo['fullName'] ?? '')
                      .toString()
                      .toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: accentColor,
                    letterSpacing: 1,
                  ),
                ),
                if (personalInfo['jobTitle'] != null &&
                    personalInfo['jobTitle']
                        .toString()
                        .isNotEmpty)
                  pw.Text(
                    personalInfo['jobTitle'],
                    style: pw.TextStyle(
                      fontSize: 13,
                      color: PdfColors.grey700,
                      font: fontSemiBold,
                    ),
                  ),
                pw.SizedBox(height: 8),
                pw.Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    if (personalInfo['email'] != null)
                      _modernContact(
                          personalInfo['email']),
                    if (personalInfo['phone'] != null)
                      _modernContact(
                          personalInfo['phone']),
                    if (personalInfo['address'] != null &&
                        personalInfo['address']
                            .toString()
                            .isNotEmpty)
                      _modernContact(
                          personalInfo['address']),
                    if (personalInfo['linkedIn'] != null &&
                        personalInfo['linkedIn']
                            .toString()
                            .isNotEmpty)
                      _modernContact(
                          personalInfo['linkedIn']),
                    if (personalInfo['github'] != null &&
                        personalInfo['github']
                            .toString()
                            .isNotEmpty)
                      _modernContact(
                          personalInfo['github']),
                    if (personalInfo['portfolio'] !=
                            null &&
                        personalInfo['portfolio']
                            .toString()
                            .isNotEmpty)
                      _modernContact(
                          personalInfo['portfolio']),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // ═══════════════════════
          // SUMMARY
          // ═══════════════════════
          if (summary.toString().isNotEmpty) ...[
            _modernSectionTitle(
                'PROFESSIONAL SUMMARY', accentColor),
            pw.Padding(
              padding: const pw.EdgeInsets.only(
                  left: 8, bottom: 12),
              child: pw.Text(
                summary,
                style: const pw.TextStyle(
                  fontSize: 10,
                  lineSpacing: 2,
                ),
              ),
            ),
          ],

          // ═══════════════════════
          // EXPERIENCE
          // ═══════════════════════
          if (experience.isNotEmpty) ...[
            _modernSectionTitle(
                'WORK EXPERIENCE', accentColor),
            ...experience.map((exp) =>
                _modernExperience(exp, accentColor)),
          ],

          // ═══════════════════════
          // EDUCATION
          // ═══════════════════════
          if (education.isNotEmpty) ...[
            _modernSectionTitle('EDUCATION', accentColor),
            ...education.map((edu) =>
                _modernEducation(edu, accentColor)),
          ],

          // ═══════════════════════
          // SKILLS
          // ═══════════════════════
          if (skills.isNotEmpty) ...[
            _modernSectionTitle('SKILLS', accentColor),
            pw.Padding(
              padding: const pw.EdgeInsets.only(
                  left: 8, bottom: 12),
              child: pw.Wrap(
                spacing: 6,
                runSpacing: 6,
                children: skills.map((skill) {
                  return pw.Container(
                    padding:
                        const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: accentColor,
                        width: 0.5,
                      ),
                      borderRadius:
                          const pw.BorderRadius.all(
                        pw.Radius.circular(3),
                      ),
                    ),
                    child: pw.Text(
                      skill,
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: accentColor,
                      ),
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
            ...projects.map((proj) =>
                _modernProject(proj, accentColor)),
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
      style: const pw.TextStyle(
        fontSize: 9,
        color: PdfColors.grey700,
      ),
    );
  }

  pw.Widget _modernSectionTitle(
      String title, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          pw.Container(
            height: 2,
            width: double.infinity,
            color: color,
            margin: const pw.EdgeInsets.only(top: 2),
          ),
          pw.SizedBox(height: 6),
        ],
      ),
    );
  }

  pw.Widget _modernExperience(
      Map<String, dynamic> exp, PdfColor color) {
    final responsibilities =
        List<String>.from(exp['responsibilities'] ?? []);

    return pw.Padding(
      padding:
          const pw.EdgeInsets.only(left: 8, bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            exp['position'] ?? '',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.Row(
            mainAxisAlignment:
                pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Row(children: [
                pw.Text(
                  exp['company'] ?? '',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
                if (exp['location'] != null &&
                    exp['location'].toString().isNotEmpty)
                  pw.Text(
                    '  |  ${exp['location']}',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey500,
                    ),
                  ),
              ]),
              pw.Text(
                '${exp['startDate'] ?? ''} - ${exp['isCurrently'] == true ? 'Present' : exp['endDate'] ?? ''}',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey500,
                ),
              ),
            ],
          ),
          if (responsibilities.isNotEmpty)
            pw.SizedBox(height: 3),
          ...responsibilities.map(
            (r) => pw.Padding(
              padding: const pw.EdgeInsets.only(
                  left: 8, bottom: 2),
              child: pw.Text(
                '• $r',
                style: const pw.TextStyle(fontSize: 9.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _modernEducation(
      Map<String, dynamic> edu, PdfColor color) {
    return pw.Padding(
      padding:
          const pw.EdgeInsets.only(left: 8, bottom: 8),
      child: pw.Row(
        mainAxisAlignment:
            pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment:
                  pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '${edu['degree'] ?? ''} in ${edu['fieldOfStudy'] ?? ''}',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  edu['institution'] ?? '',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
                if (edu['gpa'] != null &&
                    edu['gpa'].toString().isNotEmpty)
                  pw.Text(
                    'GPA: ${edu['gpa']}',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey500,
                    ),
                  ),
              ],
            ),
          ),
          pw.Text(
            '${edu['startDate'] ?? ''} - ${edu['isCurrently'] == true ? 'Present' : edu['endDate'] ?? ''}',
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey500,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _modernProject(
      Map<String, dynamic> proj, PdfColor color) {
    final technologies =
        List<String>.from(proj['technologies'] ?? []);

    return pw.Padding(
      padding:
          const pw.EdgeInsets.only(left: 8, bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(children: [
            pw.Text(
              proj['title'] ?? '',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
            if (proj['link'] != null &&
                proj['link'].toString().isNotEmpty)
              pw.Padding(
                padding:
                    const pw.EdgeInsets.only(left: 6),
                child: pw.Text(
                  '(${proj['link']})',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.blue700,
                  ),
                ),
              ),
          ]),
          if (proj['description'] != null)
            pw.Text(
              proj['description'],
              style: const pw.TextStyle(fontSize: 9.5),
            ),
          if (technologies.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                'Tech: ${technologies.join(", ")}',
                style: const pw.TextStyle(
                  fontSize: 8.5,
                  color: PdfColors.grey600,
                ),
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
    if (info['email'] != null &&
        info['email'].toString().isNotEmpty) {
      parts.add(info['email']);
    }
    if (info['phone'] != null &&
        info['phone'].toString().isNotEmpty) {
      parts.add(info['phone']);
    }
    if (info['address'] != null &&
        info['address'].toString().isNotEmpty) {
      parts.add(info['address']);
    }
    return parts.join('  |  ');
  }

  String _buildLinksLine(Map<String, dynamic> info) {
    final parts = <String>[];
    if (info['linkedIn'] != null &&
        info['linkedIn'].toString().isNotEmpty) {
      parts.add(info['linkedIn']);
    }
    if (info['github'] != null &&
        info['github'].toString().isNotEmpty) {
      parts.add(info['github']);
    }
    if (info['portfolio'] != null &&
        info['portfolio'].toString().isNotEmpty) {
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
        _showSnackBar(
          '✅ PDF saved to: ${file.path}',
          const Color(0xFF4CAF50),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          '❌ Failed to save PDF',
          const Color(0xFFEF5350),
        );
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
      final fileName =
          '${_cvData!['cvTitle'] ?? 'CV'}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(_pdfBytes!);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'My Professional CV',
      );
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          '❌ Failed to share PDF',
          const Color(0xFFEF5350),
        );
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
        _showSnackBar(
          '❌ Failed to print',
          const Color(0xFFEF5350),
        );
      }
    }
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
                        Expanded(
                          child: _buildPDFPreview(),
                        ),

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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFF2196F3),
          ),
          SizedBox(height: 16),
          Text(
            'Generating your CV...',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
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
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFEF5350),
              size: 56,
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadCV();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
            ),
          ),
          const Expanded(
            child: Text(
              'CV Preview',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          // ── Edit Button ──
          _buildAppBarAction(
            Icons.edit_outlined,
            'Edit',
            () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => CVBuilderScreen(
                    cvId: widget.cvId,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),

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

  Widget _buildAppBarAction(
    IconData icon,
    String? label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: label != null ? 12 : 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white.withOpacity(0.6),
              size: 18,
            ),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
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

    final templateId =
        _cvData!['templateId'] ?? 'classic';
    final isClassic = templateId == 'classic';
    final templateColor = isClassic
        ? const Color(0xFF66BB6A)
        : const Color(0xFFFFA726);
    final personalInfo =
        _cvData!['personalInfo'] as Map<String, dynamic>? ??
            {};

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
          ),
        ),
        child: Row(
          children: [
            // Template Badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: templateColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isClassic
                    ? Icons.article_outlined
                    : Icons.auto_awesome_outlined,
                color: templateColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    _cvData!['cvTitle'] ?? 'My CV',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: templateColor
                              .withOpacity(0.15),
                          borderRadius:
                              BorderRadius.circular(4),
                        ),
                        child: Text(
                          isClassic ? 'Classic' : 'Modern',
                          style: TextStyle(
                            color: templateColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        personalInfo['fullName'] ?? '',
                        style: TextStyle(
                          color:
                              Colors.white.withOpacity(0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ATS Badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF4CAF50)
                      .withOpacity(0.2),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_outlined,
                    color: Color(0xFF4CAF50),
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'ATS',
                    style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 11,
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
            const CircularProgressIndicator(
              color: Color(0xFF2196F3),
            ),
            const SizedBox(height: 16),
            Text(
              'Generating PDF...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: PdfPreview(
          build: (_) => _pdfBytes!,
          canChangeOrientation: false,
          canChangePageFormat: false,
          canDebug: false,
          allowPrinting: false,
          allowSharing: false,
          maxPageWidth: 700,
          pdfPreviewPageDecoration: const BoxDecoration(
            color: Colors.white,
          ),
          loadingWidget: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF2196F3),
            ),
          ),
          scrollViewDecoration: const BoxDecoration(
            color: Color(0xFF151928),
          ),
        ),
      ),
    );
  }

  // ╔══════════════════════════════╗
  // ║     ACTION BAR              ║
  // ╚══════════════════════════════╝
  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E21),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.06),
          ),
        ),
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
          const SizedBox(width: 10),

          // ── Share ──
          _buildActionButton(
            icon: Icons.share_rounded,
            label: 'Share',
            color: const Color(0xFF9C27B0),
            onTap: _sharePDF,
          ),
          const SizedBox(width: 10),

          // ── Print ──
          _buildActionButton(
            icon: Icons.print_rounded,
            label: 'Print',
            color: const Color(0xFFFFA726),
            onTap: _printPDF,
          ),
          const SizedBox(width: 10),

          // ── Edit ──
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CVBuilderScreen(
                        cvId: widget.cvId,
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.edit_rounded,
                  size: 18,
                ),
                label: const Text(
                  'Edit CV',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
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
        width: 60,
        height: 50,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
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
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1F38),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'More Options',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),

            // ── Switch Template ──
            _buildOptionTile(
              Icons.palette_outlined,
              'Switch Template',
              'Change between Classic and Modern',
              const Color(0xFFE91E63),
              () async {
                Navigator.pop(context);
                final currentTemplate =
                    _cvData!['templateId'] ?? 'classic';
                final newTemplate =
                    currentTemplate == 'classic'
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

            const SizedBox(height: 10),
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
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.white.withOpacity(0.4),
          fontSize: 11,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: Colors.white.withOpacity(0.3),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  // ══════════════════════════════════════════
  // 📋 DUPLICATE CV
  // ══════════════════════════════════════════
  Future<void> _duplicateCV() async {
    try {
      final newId =
          DateTime.now().millisecondsSinceEpoch.toString();
      final newData = Map<String, dynamic>.from(_cvData!);
      newData['id'] = newId;
      newData['cvTitle'] =
          '${newData['cvTitle']} (Copy)';
      newData['createdAt'] = FieldValue.serverTimestamp();
      newData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('cvs')
          .doc(newId)
          .set(newData);

      if (mounted) {
        _showSnackBar(
          '✅ CV duplicated successfully!',
          const Color(0xFF4CAF50),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          '❌ Failed to duplicate',
          const Color(0xFFEF5350),
        );
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
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.warning_rounded,
              color: Color(0xFFEF5350),
              size: 24,
            ),
            SizedBox(width: 10),
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
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
              ),
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
                  _showSnackBar(
                    '❌ Failed to delete',
                    const Color(0xFFEF5350),
                  );
                }
              }
            },
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
      ),
    );
  }
}