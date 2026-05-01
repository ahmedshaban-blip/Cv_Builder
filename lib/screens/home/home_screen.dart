// lib/screens/home/home_screen.dart
import 'package:cv_builder/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:math';
import 'package:archive/archive.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import '../cv_builder/cv_builder_screen.dart';
import '../preview/cv_preview_screen.dart';
import '../settings/delete_account_screen.dart';

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/cv_model.dart';
import '../../utils/pdf_generator.dart';

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

  bool get isTablet => MediaQuery.of(context).size.shortestSide >= 600;
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
  // 📤 SHARE CV AS WORD
  // ══════════════════════════════════════════
  Future<void> _shareCVAsWord(String cvId) async {
    try {
      // ── 1) جلب بيانات الـ CV ──
      final doc = await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('cvs')
          .doc(cvId)
          .get();

      if (!doc.exists) {
        if (mounted) {
          _showSnackBar('❌ CV not found', const Color(0xFFEF5350));
        }
        return;
      }

      final cvData = doc.data() as Map<String, dynamic>;

      // ── 2) توليد ملف Word ──
      final wordBytes = _generateWordDocumentFromData(cvData);

      // ── 3) حفظ مؤقت ──
      final dir = await getTemporaryDirectory();
      final rawTitle = cvData['cvTitle']?.toString().trim() ?? 'CV';
      final safeTitle = rawTitle.replaceAll(
        RegExp(r'[<>:"/\\|?*\x00-\x1F]'),
        '_',
      );
      final fileName = '$safeTitle.docx';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(wordBytes, flush: true);

      // ── 4) مشاركة ──
      await Share.shareXFiles([XFile(file.path)], text: 'My Professional CV');
    } catch (e) {
      if (mounted) {
        _showSnackBar('❌ Failed to share Word: $e', const Color(0xFFEF5350));
      }
    }
  }

  // ══════════════════════════════════════════
  // 📝 GENERATE WORD FROM CV DATA
  // ══════════════════════════════════════════
  Uint8List _generateWordDocumentFromData(Map<String, dynamic> cvData) {
    final personalInfo = cvData['personalInfo'] as Map<String, dynamic>? ?? {};
    final education = List<Map<String, dynamic>>.from(
      cvData['education'] ?? [],
    );
    final experience = List<Map<String, dynamic>>.from(
      cvData['experience'] ?? [],
    );
    final skills = List<String>.from(cvData['skills'] ?? []);
    final projects = List<Map<String, dynamic>>.from(cvData['projects'] ?? []);
    final summary = cvData['summary'] ?? '';

    final body = StringBuffer();

    // ── HEADER ──
    body.write(
      _wordParagraph(
        (personalInfo['fullName'] ?? '').toString().toUpperCase(),
        fontSize: 28,
        bold: true,
        alignment: 'center',
        spacingAfter: 40,
      ),
    );

    if (personalInfo['jobTitle'] != null &&
        personalInfo['jobTitle'].toString().isNotEmpty) {
      body.write(
        _wordParagraph(
          personalInfo['jobTitle'],
          fontSize: 14,
          color: '555555',
          alignment: 'center',
          spacingAfter: 80,
        ),
      );
    }

    // Contact
    final contactParts = <String>[];
    if (personalInfo['email'] != null &&
        personalInfo['email'].toString().isNotEmpty) {
      contactParts.add(personalInfo['email']);
    }
    if (personalInfo['phone'] != null &&
        personalInfo['phone'].toString().isNotEmpty) {
      contactParts.add(personalInfo['phone']);
    }
    if (personalInfo['address'] != null &&
        personalInfo['address'].toString().isNotEmpty) {
      contactParts.add(personalInfo['address']);
    }
    if (contactParts.isNotEmpty) {
      body.write(
        _wordParagraph(
          contactParts.join('  |  '),
          fontSize: 10,
          color: '666666',
          alignment: 'center',
          spacingAfter: 20,
        ),
      );
    }

    // Links
    final linksParts = <String>[];
    if (personalInfo['linkedIn'] != null &&
        personalInfo['linkedIn'].toString().isNotEmpty) {
      linksParts.add(personalInfo['linkedIn']);
    }
    if (personalInfo['github'] != null &&
        personalInfo['github'].toString().isNotEmpty) {
      linksParts.add(personalInfo['github']);
    }
    if (personalInfo['portfolio'] != null &&
        personalInfo['portfolio'].toString().isNotEmpty) {
      linksParts.add(personalInfo['portfolio']);
    }
    if (linksParts.isNotEmpty) {
      body.write(
        _wordParagraph(
          linksParts.join('  |  '),
          fontSize: 9,
          color: '1155CC',
          alignment: 'center',
          spacingAfter: 60,
        ),
      );
    }

    body.write(_wordHorizontalLine());

    // ── SUMMARY ──
    if (summary.toString().isNotEmpty) {
      body.write(_wordSectionTitle('PROFESSIONAL SUMMARY'));
      body.write(_wordParagraph(summary, fontSize: 11, spacingAfter: 160));
    }

    // ── EXPERIENCE ──
    if (experience.isNotEmpty) {
      body.write(_wordSectionTitle('WORK EXPERIENCE'));
      for (final exp in experience) {
        final dateRange =
            '${exp['startDate'] ?? ''} - ${exp['isCurrently'] == true ? 'Present' : exp['endDate'] ?? ''}';

        body.write(
          _wordTwoColumnRow(
            exp['position'] ?? '',
            dateRange,
            leftBold: true,
            leftSize: 12,
            rightSize: 10,
            rightColor: '666666',
          ),
        );

        final companyLine = StringBuffer(exp['company'] ?? '');
        if (exp['location'] != null && exp['location'].toString().isNotEmpty) {
          companyLine.write('  |  ${exp['location']}');
        }
        body.write(
          _wordParagraph(
            companyLine.toString(),
            fontSize: 10,
            color: '555555',
            spacingAfter: 40,
          ),
        );

        final responsibilities = List<String>.from(
          exp['responsibilities'] ?? [],
        );
        for (final r in responsibilities) {
          body.write(_wordBulletPoint(r, fontSize: 10));
        }
        body.write(_wordParagraph('', fontSize: 8, spacingAfter: 120));
      }
    }

    // ── EDUCATION ──
    if (education.isNotEmpty) {
      body.write(_wordSectionTitle('EDUCATION'));
      for (final edu in education) {
        final dateRange =
            '${edu['startDate'] ?? ''} - ${edu['isCurrently'] == true ? 'Present' : edu['endDate'] ?? ''}';
        final degree = '${edu['degree'] ?? ''} in ${edu['fieldOfStudy'] ?? ''}';

        body.write(
          _wordTwoColumnRow(
            degree,
            dateRange,
            leftBold: true,
            leftSize: 12,
            rightSize: 10,
            rightColor: '666666',
          ),
        );

        body.write(
          _wordParagraph(
            edu['institution'] ?? '',
            fontSize: 10,
            color: '555555',
            spacingAfter: 20,
          ),
        );

        if (edu['gpa'] != null && edu['gpa'].toString().isNotEmpty) {
          body.write(
            _wordParagraph(
              'GPA: ${edu['gpa']}',
              fontSize: 9,
              color: '666666',
              spacingAfter: 40,
            ),
          );
        }
        body.write(_wordParagraph('', fontSize: 8, spacingAfter: 100));
      }
    }

    // ── SKILLS ──
    if (skills.isNotEmpty) {
      body.write(_wordSectionTitle('SKILLS'));
      body.write(
        _wordParagraph(skills.join('  •  '), fontSize: 11, spacingAfter: 160),
      );
    }

    // ── PROJECTS ──
    if (projects.isNotEmpty) {
      body.write(_wordSectionTitle('PROJECTS'));
      for (final proj in projects) {
        final titleLine = StringBuffer(proj['title'] ?? '');
        if (proj['link'] != null && proj['link'].toString().isNotEmpty) {
          titleLine.write('  (${proj['link']})');
        }

        body.write(
          _wordParagraph(
            titleLine.toString(),
            fontSize: 12,
            bold: true,
            spacingAfter: 20,
          ),
        );

        if (proj['description'] != null &&
            proj['description'].toString().isNotEmpty) {
          body.write(
            _wordParagraph(proj['description'], fontSize: 10, spacingAfter: 20),
          );
        }

        final technologies = List<String>.from(proj['technologies'] ?? []);
        if (technologies.isNotEmpty) {
          body.write(
            _wordParagraph(
              'Technologies: ${technologies.join(", ")}',
              fontSize: 9,
              color: '666666',
              spacingAfter: 40,
            ),
          );
        }
        body.write(_wordParagraph('', fontSize: 8, spacingAfter: 80));
      }
    }

    return _buildDocx(body.toString());
  }

  // ══════════════════════════════════════════
  // 📦 BUILD DOCX FILE
  // ══════════════════════════════════════════
  Uint8List _buildDocx(String bodyContent) {
    final archive = Archive();

    archive.addFile(
      ArchiveFile(
        '[Content_Types].xml',
        _contentTypesXml.length,
        _contentTypesXml.codeUnits,
      ),
    );
    archive.addFile(
      ArchiveFile('_rels/.rels', _relsXml.length, _relsXml.codeUnits),
    );
    archive.addFile(
      ArchiveFile(
        'word/_rels/document.xml.rels',
        _documentRelsXml.length,
        _documentRelsXml.codeUnits,
      ),
    );
    archive.addFile(
      ArchiveFile('word/styles.xml', _stylesXml.length, _stylesXml.codeUnits),
    );

    final documentXml =
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:wpc="http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas"
  xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
  xmlns:o="urn:schemas-microsoft-com:office:office"
  xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
  xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math"
  xmlns:v="urn:schemas-microsoft-com:vml"
  xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
  xmlns:w10="urn:schemas-microsoft-com:office:word"
  xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
  xmlns:w14="http://schemas.microsoft.com/office/word/2010/wordml"
  xmlns:wpg="http://schemas.microsoft.com/office/word/2010/wordprocessingGroup"
  xmlns:wps="http://schemas.microsoft.com/office/word/2010/wordprocessingShape"
  mc:Ignorable="w14">
  <w:body>
    $bodyContent
    <w:sectPr>
      <w:pgSz w:w="11906" w:h="16838"/>
      <w:pgMar w:top="1134" w:right="1134" w:bottom="1134" w:left="1134"
               w:header="709" w:footer="709" w:gutter="0"/>
    </w:sectPr>
  </w:body>
</w:document>''';

    archive.addFile(
      ArchiveFile(
        'word/document.xml',
        documentXml.length,
        documentXml.codeUnits,
      ),
    );

    final zipData = ZipEncoder().encode(archive);
    return Uint8List.fromList(zipData);
  }

  // ══════════════════════════════════════════
  // 🔤 WORD XML HELPERS
  // ══════════════════════════════════════════
  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  String _wordParagraph(
    String text, {
    int fontSize = 11,
    bool bold = false,
    String color = '000000',
    String alignment = 'left',
    int spacingAfter = 60,
  }) {
    final halfPoints = fontSize * 2;
    return '''
<w:p>
  <w:pPr>
    <w:jc w:val="$alignment"/>
    <w:spacing w:after="$spacingAfter"/>
  </w:pPr>
  <w:r>
    <w:rPr>
      <w:sz w:val="$halfPoints"/>
      <w:szCs w:val="$halfPoints"/>
      ${bold ? '<w:b/><w:bCs/>' : ''}
      ${color != '000000' ? '<w:color w:val="$color"/>' : ''}
    </w:rPr>
    <w:t xml:space="preserve">${_escapeXml(text)}</w:t>
  </w:r>
</w:p>''';
  }

  String _wordSectionTitle(String title) {
    return '''
<w:p>
  <w:pPr>
    <w:spacing w:before="200" w:after="40"/>
    <w:pBdr>
      <w:bottom w:val="single" w:sz="8" w:space="1" w:color="333333"/>
    </w:pBdr>
  </w:pPr>
  <w:r>
    <w:rPr>
      <w:b/><w:bCs/>
      <w:sz w:val="24"/>
      <w:szCs w:val="24"/>
      <w:color w:val="333333"/>
    </w:rPr>
    <w:t>${_escapeXml(title)}</w:t>
  </w:r>
</w:p>''';
  }

  String _wordBulletPoint(String text, {int fontSize = 10}) {
    final halfPoints = fontSize * 2;
    return '''
<w:p>
  <w:pPr>
    <w:spacing w:after="20"/>
    <w:ind w:left="480" w:hanging="240"/>
  </w:pPr>
  <w:r>
    <w:rPr>
      <w:sz w:val="$halfPoints"/>
      <w:szCs w:val="$halfPoints"/>
    </w:rPr>
    <w:t xml:space="preserve">•  ${_escapeXml(text)}</w:t>
  </w:r>
</w:p>''';
  }

  String _wordTwoColumnRow(
    String leftText,
    String rightText, {
    bool leftBold = false,
    int leftSize = 11,
    int rightSize = 10,
    String rightColor = '666666',
  }) {
    final leftHalf = leftSize * 2;
    final rightHalf = rightSize * 2;
    return '''
<w:p>
  <w:pPr>
    <w:tabs>
      <w:tab w:val="right" w:pos="9638"/>
    </w:tabs>
    <w:spacing w:after="20"/>
  </w:pPr>
  <w:r>
    <w:rPr>
      <w:sz w:val="$leftHalf"/>
      <w:szCs w:val="$leftHalf"/>
      ${leftBold ? '<w:b/><w:bCs/>' : ''}
    </w:rPr>
    <w:t xml:space="preserve">${_escapeXml(leftText)}</w:t>
  </w:r>
  <w:r>
    <w:rPr>
      <w:sz w:val="$rightHalf"/>
      <w:szCs w:val="$rightHalf"/>
      <w:color w:val="$rightColor"/>
    </w:rPr>
    <w:tab/>
    <w:t>${_escapeXml(rightText)}</w:t>
  </w:r>
</w:p>''';
  }

  String _wordHorizontalLine() {
    return '''
<w:p>
  <w:pPr>
    <w:pBdr>
      <w:bottom w:val="single" w:sz="12" w:space="1" w:color="000000"/>
    </w:pBdr>
    <w:spacing w:after="120"/>
  </w:pPr>
</w:p>''';
  }

  static const String _contentTypesXml =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
      '<Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>'
      '</Types>';

  static const String _relsXml =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
      '</Relationships>';

  static const String _documentRelsXml =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
      '</Relationships>';

  static const String _stylesXml =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
      '<w:docDefaults>'
      '<w:rPrDefault><w:rPr>'
      '<w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:cs="Calibri"/>'
      '<w:sz w:val="22"/><w:szCs w:val="22"/>'
      '</w:rPr></w:rPrDefault>'
      '</w:docDefaults>'
      '</w:styles>';

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
                        errorBuilder: (_, _, _) => _buildAvatarText(),
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
                      separatorBuilder: (_, _) => SizedBox(width: 6.w),
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
        child: SingleChildScrollView(
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
                  _shareCV(cvId);
                },
              ),
              _buildOptionTile(
                Icons.description_outlined,
                'Share as Word',
                Color(0xFF2979FF),
                () {
                  Navigator.pop(context);
                  _shareCVAsWord(cvId);
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
      ),
    );
  }

  Widget _buildOptionTile(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: isTablet ? 25.0 : 0.0),
      child: ListTile(
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
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
                        errorBuilder: (_, _, _) => Center(
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
  // 📤 SHARE CV
  // ══════════════════════════════════════════
  Future<void> _shareCV(String cvId) async {
    try {
      // 1. Get CV data from Firestore
      final doc = await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('cvs')
          .doc(cvId)
          .get();

      if (!doc.exists) {
        if (mounted) {
          _showSnackBar('❌ CV not found', Color(0xFFEF5350));
        }
        return;
      }

      final cv = CVModel.fromMap(doc.data() as Map<String, dynamic>);

      // 2. Generate PDF using utility
      final templateId = cv.templateId;
      final pdf = templateId == 'modern'
          ? await PDFGenerator.generateModernTemplate(cv)
          : await PDFGenerator.generateClassicTemplate(cv);

      final bytes = await pdf.save();

      // 3. Save to temporary file for sharing
      final dir = await getTemporaryDirectory();
      // Clean file name: remove special characters except spaces and hyphens
      final cleanTitle = cv.cvTitle.replaceAll(RegExp(r'[^\w\s-]'), '');
      final file = File('${dir.path}/$cleanTitle.pdf');
      await file.writeAsBytes(bytes);

      // 4. Share using share_plus
      if (mounted) {
        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'Check out my professional CV: ${cv.cvTitle}');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('❌ Failed to share PDF: $e', Color(0xFFEF5350));
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
