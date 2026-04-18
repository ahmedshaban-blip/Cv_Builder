// utils/pdf_generator.dart
import 'package:cv_builder/models/education_model.dart';
import 'package:cv_builder/models/experience_model.dart';
import 'package:cv_builder/models/project_model.dart';
import 'package:cv_builder/models/user_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/cv_model.dart';

class PDFGenerator {

  // ══════════════════════════════════════════
  // 📄 TEMPLATE 1: CLASSIC ATS
  // ══════════════════════════════════════════
  // بسيط - خط واحد - بدون ألوان كتير
  // ══════════════════════════════════════════
  static Future<pw.Document> generateClassicTemplate(
    CVModel cv,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // ── HEADER: Name & Contact ──
          _buildClassicHeader(cv.personalInfo),
          pw.SizedBox(height: 4),
          pw.Divider(thickness: 1.5),
          pw.SizedBox(height: 10),

          // ── PROFESSIONAL SUMMARY ──
          if (cv.summary != null && cv.summary!.isNotEmpty) ...[
            _buildSectionTitle('PROFESSIONAL SUMMARY'),
            pw.SizedBox(height: 4),
            pw.Text(
              cv.summary!,
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 14),
          ],

          // ── EXPERIENCE ──
          if (cv.experience.isNotEmpty) ...[
            _buildSectionTitle('WORK EXPERIENCE'),
            pw.SizedBox(height: 4),
            ...cv.experience.map(
              (exp) => _buildClassicExperience(exp),
            ),
            pw.SizedBox(height: 14),
          ],

          // ── EDUCATION ──
          if (cv.education.isNotEmpty) ...[
            _buildSectionTitle('EDUCATION'),
            pw.SizedBox(height: 4),
            ...cv.education.map(
              (edu) => _buildClassicEducation(edu),
            ),
            pw.SizedBox(height: 14),
          ],

          // ── SKILLS ──
          if (cv.skills.isNotEmpty) ...[
            _buildSectionTitle('SKILLS'),
            pw.SizedBox(height: 4),
            pw.Text(
              cv.skills.join('  •  '),
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 14),
          ],

          // ── PROJECTS ──
          if (cv.projects.isNotEmpty) ...[
            _buildSectionTitle('PROJECTS'),
            pw.SizedBox(height: 4),
            ...cv.projects.map(
              (proj) => _buildClassicProject(proj),
            ),
          ],
        ],
      ),
    );

    return pdf;
  }

  // ── Classic Header ──
  static pw.Widget _buildClassicHeader(PersonalInfo info) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          info.fullName.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 22,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        if (info.jobTitle != null)
          pw.Text(
            info.jobTitle!,
            style: const pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey700,
            ),
          ),
        pw.SizedBox(height: 6),
        pw.Text(
          [
            info.email,
            info.phone,
            if (info.address != null) info.address,
          ].join('  |  '),
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.Text(
          [
            if (info.linkedIn != null) info.linkedIn,
            if (info.github != null) info.github,
            if (info.portfolio != null) info.portfolio,
          ].join('  |  '),
          style: const pw.TextStyle(
            fontSize: 9,
            color: PdfColors.blue800,
          ),
        ),
      ],
    );
  }

  // ── Section Title ──
  static pw.Widget _buildSectionTitle(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Divider(thickness: 0.8),
      ],
    );
  }

  // ── Classic Experience Item ──
  static pw.Widget _buildClassicExperience(Experience exp) {
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
                exp.position,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                '${exp.startDate} - ${exp.isCurrently ? "Present" : exp.endDate}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
          pw.Text(
            '${exp.company}${exp.location != null ? " | ${exp.location}" : ""}',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 3),
          ...exp.responsibilities.map(
            (r) => pw.Padding(
              padding: const pw.EdgeInsets.only(
                left: 12, bottom: 2,
              ),
              child: pw.Text(
                '• $r',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Classic Education Item ──
  static pw.Widget _buildClassicEducation(Education edu) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment:
            pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '${edu.degree} in ${edu.fieldOfStudy}',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                edu.institution,
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
          pw.Text(
            '${edu.startDate} - ${edu.isCurrently ? "Present" : edu.endDate}',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ── Classic Project Item ──
  static pw.Widget _buildClassicProject(Project proj) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            proj.title,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            proj.description,
            style: const pw.TextStyle(fontSize: 10),
          ),
          if (proj.technologies.isNotEmpty)
            pw.Text(
              'Technologies: ${proj.technologies.join(", ")}',
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey700,
              ),
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // 📄 TEMPLATE 2: MODERN ATS
  // ══════════════════════════════════════════
  // فيه لمسة لون بسيطة - لكن لسه ATS-friendly
  // ══════════════════════════════════════════
  static Future<pw.Document> generateModernTemplate(
    CVModel cv,
  ) async {
    final pdf = pw.Document();
    const accentColor = PdfColors.blueGrey800;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => [
          // ── HEADER with accent color ──
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: const pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.all(
                pw.Radius.circular(4),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment:
                  pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  cv.personalInfo.fullName.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                if (cv.personalInfo.jobTitle != null)
                  pw.Text(
                    cv.personalInfo.jobTitle!,
                    style: pw.TextStyle(
                      fontSize: 13,
                      color: PdfColors.grey700,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                pw.SizedBox(height: 8),
                pw.Wrap(
                  spacing: 16,
                  children: [
                    _modernContactItem(
                      cv.personalInfo.email,
                    ),
                    _modernContactItem(
                      cv.personalInfo.phone,
                    ),
                    if (cv.personalInfo.linkedIn != null)
                      _modernContactItem(
                        cv.personalInfo.linkedIn!,
                      ),
                    if (cv.personalInfo.github != null)
                      _modernContactItem(
                        cv.personalInfo.github!,
                      ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // ── SUMMARY ──
          if (cv.summary != null &&
              cv.summary!.isNotEmpty) ...[
            _buildModernSection('PROFESSIONAL SUMMARY',
                accentColor),
            pw.Padding(
              padding: const pw.EdgeInsets.only(
                left: 8, bottom: 12,
              ),
              child: pw.Text(
                cv.summary!,
                style: const pw.TextStyle(
                  fontSize: 10,
                  lineSpacing: 2,
                ),
              ),
            ),
          ],

          // ── EXPERIENCE ──
          if (cv.experience.isNotEmpty) ...[
            _buildModernSection(
              'WORK EXPERIENCE', accentColor,
            ),
            ...cv.experience.map(
              (exp) => _buildModernExperience(
                exp, accentColor,
              ),
            ),
          ],

          // ── EDUCATION ──
          if (cv.education.isNotEmpty) ...[
            _buildModernSection('EDUCATION', accentColor),
            ...cv.education.map(
              (edu) => _buildModernEducation(
                edu, accentColor,
              ),
            ),
          ],

          // ── SKILLS ──
          if (cv.skills.isNotEmpty) ...[
            _buildModernSection('SKILLS', accentColor),
            pw.Padding(
              padding: const pw.EdgeInsets.only(
                left: 8, bottom: 12,
              ),
              child: pw.Wrap(
                spacing: 8,
                runSpacing: 4,
                children: cv.skills.map((skill) {
                  return pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
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

          // ── PROJECTS ──
          if (cv.projects.isNotEmpty) ...[
            _buildModernSection('PROJECTS', accentColor),
            ...cv.projects.map(
              (proj) => _buildModernProject(
                proj, accentColor,
              ),
            ),
          ],
        ],
      ),
    );

    return pdf;
  }

  static pw.Widget _modernContactItem(String text) {
    return pw.Text(
      text,
      style: const pw.TextStyle(fontSize: 9),
    );
  }

  static pw.Widget _buildModernSection(
    String title, PdfColor color,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.Container(
            height: 2,
            width: double.infinity,
            color: color,
          ),
          pw.SizedBox(height: 6),
        ],
      ),
    );
  }

  static pw.Widget _buildModernExperience(
    Experience exp, PdfColor color,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(
        left: 8, bottom: 12,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            exp.position,
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
              pw.Text(
                exp.company,
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Text(
                '${exp.startDate} - ${exp.isCurrently ? "Present" : exp.endDate}',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 3),
          ...exp.responsibilities.map(
            (r) => pw.Padding(
              padding: const pw.EdgeInsets.only(
                left: 8, bottom: 2,
              ),
              child: pw.Text(
                '• $r',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildModernEducation(
    Education edu, PdfColor color,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(
        left: 8, bottom: 8,
      ),
      child: pw.Row(
        mainAxisAlignment:
            pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment:
                pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '${edu.degree} in ${edu.fieldOfStudy}',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                edu.institution,
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
          pw.Text(
            '${edu.startDate} - ${edu.isCurrently ? "Present" : edu.endDate}',
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildModernProject(
    Project proj, PdfColor color,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(
        left: 8, bottom: 8,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            proj.title,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.Text(
            proj.description,
            style: const pw.TextStyle(fontSize: 10),
          ),
          if (proj.technologies.isNotEmpty)
            pw.Text(
              'Tech: ${proj.technologies.join(", ")}',
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey600,
              ),
            ),
        ],
      ),
    );
  }
}