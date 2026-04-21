// lib/screens/cv_builder/steps/template_step.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../widgets/builder_widgets.dart';

class TemplateStep extends StatefulWidget {
  final String selectedTemplate;
  final Function(String) onSelect;
  final Map<String, dynamic> cvData;

  TemplateStep({
    super.key,
    required this.selectedTemplate,
    required this.onSelect,
    required this.cvData,
  });

  @override
  State<TemplateStep> createState() => _TemplateStepState();
}

class _TemplateStepState extends State<TemplateStep>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    _scaleAnim = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          StepHeader(
            title: 'Choose Template',
            subtitle: 'Select your CV design',
            icon: Icons.palette_outlined,
            color: Color(0xFFE91E63),
          ),

          // ── Info Banner ──
          _buildInfoBanner(),
          SizedBox(height: 24.h),

          // ── Templates ──
          ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              children: [
                // Template 1: Classic
                _buildTemplateCard(
                  id: 'classic',
                  name: 'Classic ATS',
                  description:
                      'Clean, traditional layout. Best for corporate and formal applications.',
                  icon: Icons.article_outlined,
                  color: Color(0xFF66BB6A),
                  features: [
                    'Simple single-column',
                    'Traditional formatting',
                    'Maximum ATS compatibility',
                    'Best for corporate roles',
                  ],
                ),
                SizedBox(height: 16.h),

                // Template 2: Modern
                _buildTemplateCard(
                  id: 'modern',
                  name: 'Modern ATS',
                  description:
                      'Contemporary design with subtle accents. Perfect for tech and creative roles.',
                  icon: Icons.auto_awesome_outlined,
                  color: Color(0xFFFFA726),
                  features: [
                    'Modern clean design',
                    'Subtle color accents',
                    'Skill badges/chips',
                    'Best for tech roles',
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          // ── Preview Section ──
          _buildPreviewSection(),
          SizedBox(height: 24.h),

          // ── Comparison Table ──
          _buildComparisonTable(),
          SizedBox(height: 24.h),

          // ── ATS Info ──
          _buildATSInfo(),

          SizedBox(height: 30.h),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // ℹ️ Info Banner
  // ══════════════════════════════════════════
  Widget _buildInfoBanner() {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Color(0xFFE91E63).withOpacity(0.06),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Color(0xFFE91E63).withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 36.r,
            height: 36.r,
            decoration: BoxDecoration(
              color: Color(0xFFE91E63).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.verified_outlined,
              color: Color(0xFFE91E63),
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Both templates are ATS-optimized',
                  style: TextStyle(
                    color: Color(0xFFE91E63),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Choose the style that best fits your industry',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // 🃏 Template Card
  // ══════════════════════════════════════════
  Widget _buildTemplateCard({
    required String id,
    required String name,
    required String description,
    required IconData icon,
    required Color color,
    required List<String> features,
  }) {
    final isSelected = widget.selectedTemplate == id;

    return GestureDetector(
      onTap: () => widget.onSelect(id),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.all(18.r),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.08)
              : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? color.withOpacity(0.5)
                : Colors.white.withOpacity(0.08),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Row(
              children: [
                // ── Template Preview Mini ──
                Container(
                  width: 70.w,
                  height: 90.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isSelected
                          ? color.withOpacity(0.3)
                          : Colors.white.withOpacity(0.08),
                    ),
                  ),
                  child: _buildMiniPreview(id, color),
                ),
                SizedBox(width: 16.w),

                // ── Info ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(icon, color: color, size: 20.sp),
                          SizedBox(width: 8.w),
                          Text(
                            name,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.8),
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12.sp,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Selection Indicator ──
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  width: 28.r,
                  height: 28.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? color : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? color : Colors.white.withOpacity(0.2),
                      width: 2.w,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 16.sp,
                        )
                      : null,
                ),
              ],
            ),

            // ── Features ──
            SizedBox(height: 14.h),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: features.map((feature) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withOpacity(0.1)
                        : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: isSelected
                            ? color
                            : Colors.white.withOpacity(0.3),
                        size: 12.sp,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        feature,
                        style: TextStyle(
                          color: isSelected
                              ? color
                              : Colors.white.withOpacity(0.4),
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // 📄 Mini Preview (inside template card)
  // ══════════════════════════════════════════
  Widget _buildMiniPreview(String templateId, Color color) {
    if (templateId == 'classic') {
      return Padding(
        padding: EdgeInsets.all(8.r),
        child: Column(
          children: [
            // Name placeholder
            Container(
              width: double.infinity,
              height: 8.h,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 3.h),
            Container(
              width: 35.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 5.h),
            Container(
              width: double.infinity,
              height: 1.h,
              color: Colors.white.withOpacity(0.1),
            ),
            SizedBox(height: 5.h),
            // Section placeholders
            ...List.generate(3, (i) {
              return Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(1.r),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Container(
                      width: 30.w,
                      height: 3.h,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(1.r),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
    } else {
      // Modern template preview
      return Padding(
        padding: EdgeInsets.all(6.r),
        child: Column(
          children: [
            // Header with color
            Container(
              width: double.infinity,
              height: 24.h,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4.r),
              ),
              padding: EdgeInsets.all(4.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 35.w,
                    height: 5.h,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Container(
                    width: 25.w,
                    height: 3.h,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(1.r),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 4.h),
            // Section with colored header
            ...List.generate(2, (i) {
              return Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 30.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(1.r),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Container(
                      width: double.infinity,
                      height: 3.h,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(1.r),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Container(
                      width: 35.w,
                      height: 3.h,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(1.r),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
    }
  }

  // ══════════════════════════════════════════
  // 👁️ Preview Section
  // ══════════════════════════════════════════
  Widget _buildPreviewSection() {
    final fullName = widget.cvData['fullName'] ?? 'Your Name';
    final jobTitle = widget.cvData['jobTitle'] ?? 'Job Title';
    final email = widget.cvData['email'] ?? 'email@example.com';
    final phone = widget.cvData['phone'] ?? '+XX XXX XXX';
    final skills = List<String>.from(widget.cvData['skills'] ?? []);
    final isClassic = widget.selectedTemplate == 'classic';
    final color = isClassic ? Color(0xFF66BB6A) : Color(0xFFFFA726);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4.w,
              height: 20.h,
              decoration: BoxDecoration(
                color: Color(0xFFE91E63),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(width: 10.w),
            Text(
              'Live Preview',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),

        // Preview Card
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: isClassic
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              // ── Classic Header ──
              if (isClassic) ...[
                Text(
                  fullName.toString().toUpperCase(),
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  jobTitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 11.sp),
                ),
                SizedBox(height: 4.h),
                Text(
                  '$email  |  $phone',
                  style: TextStyle(color: Colors.grey[500], fontSize: 9.sp),
                ),
                Divider(height: 16.h),
              ],

              // ── Modern Header ──
              if (!isClassic) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName.toString().toUpperCase(),
                        style: TextStyle(
                          color: Colors.blueGrey[800],
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        jobTitle,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '$email  •  $phone',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 9.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
              ],

              // ── Section ──
              Text(
                isClassic ? 'WORK EXPERIENCE' : 'WORK EXPERIENCE',
                style: TextStyle(
                  color: isClassic ? Colors.black87 : Colors.blueGrey[800],
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                height: isClassic ? 0.8 : 2,
                width: double.infinity,
                margin: EdgeInsets.symmetric(vertical: 3.h),
                color: isClassic ? Colors.grey[400] : Colors.blueGrey[800],
              ),
              SizedBox(height: 4.h),
              Text(
                'Your experience will appear here...',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 9.sp,
                  fontStyle: FontStyle.italic,
                ),
              ),

              SizedBox(height: 10.h),

              // ── Skills ──
              Text(
                'SKILLS',
                style: TextStyle(
                  color: isClassic ? Colors.black87 : Colors.blueGrey[800],
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                height: isClassic ? 0.8 : 2,
                width: double.infinity,
                margin: EdgeInsets.symmetric(vertical: 3.h),
                color: isClassic ? Colors.grey[400] : Colors.blueGrey[800],
              ),
              SizedBox(height: 6.h),

              if (skills.isNotEmpty)
                isClassic
                    ? Text(
                        skills.take(5).join('  •  '),
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 9.sp,
                        ),
                      )
                    : Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: skills.take(5).map((s) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.blueGrey[300]!,
                                width: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(3.r),
                            ),
                            child: Text(
                              s,
                              style: TextStyle(
                                color: Colors.blueGrey[700],
                                fontSize: 8.sp,
                              ),
                            ),
                          );
                        }).toList(),
                      )
              else
                Text(
                  'Your skills will appear here...',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 9.sp,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════
  // 📊 Comparison Table
  // ══════════════════════════════════════════
  Widget _buildComparisonTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4.w,
              height: 20.h,
              decoration: BoxDecoration(
                color: Color(0xFFE91E63),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(width: 10.w),
            Text(
              'Template Comparison',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),

        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(16.r),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Feature',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Classic',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF66BB6A),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Modern',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFFFA726),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Rows
              _buildComparisonRow('ATS Score', '★★★★★', '★★★★☆'),
              _buildComparisonRow('Visual Appeal', '★★★☆☆', '★★★★★'),
              _buildComparisonRow('Layout', 'Single Column', 'Single Column'),
              _buildComparisonRow('Color', 'Minimal', 'Subtle Accents'),
              _buildComparisonRow('Best For', 'Corporate', 'Tech/Creative'),
              _buildComparisonRow('Skill Display', 'Text List', 'Badges'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonRow(String feature, String classic, String modern) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.04)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              feature,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12.sp,
              ),
            ),
          ),
          Expanded(
            child: Text(
              classic,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 11.sp,
              ),
            ),
          ),
          Expanded(
            child: Text(
              modern,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 11.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // 🛡️ ATS Info
  // ══════════════════════════════════════════
  Widget _buildATSInfo() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Color(0xFF2196F3).withOpacity(0.06),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Color(0xFF2196F3).withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.security_outlined,
                color: Color(0xFF2196F3).withOpacity(0.8),
                size: 18.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'What is ATS?',
                style: TextStyle(
                  color: Color(0xFF64B5F6),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            'Applicant Tracking Systems (ATS) are software used by 99% of Fortune 500 companies to filter resumes before human review.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12.sp,
              height: 1.5,
            ),
          ),
          SizedBox(height: 12.h),

          // ATS checks
          _buildATSCheck('✅', 'Standard fonts used'),
          _buildATSCheck('✅', 'No images or graphics'),
          _buildATSCheck('✅', 'Single-column layout'),
          _buildATSCheck('✅', 'Standard section headings'),
          _buildATSCheck('✅', 'Clean text formatting'),
          _buildATSCheck('✅', 'PDF output compatible'),
        ],
      ),
    );
  }

  Widget _buildATSCheck(String emoji, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 12.sp)),
          SizedBox(width: 8.w),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }
}
