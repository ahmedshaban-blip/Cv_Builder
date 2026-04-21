// lib/screens/cv_builder/steps/summary_step.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../widgets/builder_widgets.dart';

class SummaryStep extends StatefulWidget {
  final TextEditingController summaryController;
  final String jobTitle;
  final List<String> skills;

  SummaryStep({
    super.key,
    required this.summaryController,
    required this.jobTitle,
    required this.skills,
  });

  @override
  State<SummaryStep> createState() => _SummaryStepState();
}

class _SummaryStepState extends State<SummaryStep> {
  // ══════════════════════════════════
  // 📝 Pre-built Summary Templates
  // ══════════════════════════════════
  List<String> get _summaryTemplates => [
    'Results-driven ${widget.jobTitle.isNotEmpty ? widget.jobTitle : "[Job Title]"} with a proven track record of delivering high-quality solutions. Skilled in ${widget.skills.take(3).join(", ")}${widget.skills.length > 3 ? " and more" : ""}. Passionate about building scalable applications and collaborating with cross-functional teams to achieve business goals.',
    'Dedicated ${widget.jobTitle.isNotEmpty ? widget.jobTitle : "[Job Title]"} with extensive experience in developing and maintaining robust applications. Proficient in ${widget.skills.take(3).join(", ")}${widget.skills.length > 3 ? " among other technologies" : ""}. Strong problem-solving abilities with a focus on writing clean, maintainable code.',
    'Innovative ${widget.jobTitle.isNotEmpty ? widget.jobTitle : "[Job Title]"} with a passion for creating efficient and user-friendly solutions. Experienced in ${widget.skills.take(3).join(", ")}${widget.skills.length > 3 ? " and related technologies" : ""}. Committed to continuous learning and staying up-to-date with the latest industry trends.',
    'Detail-oriented ${widget.jobTitle.isNotEmpty ? widget.jobTitle : "[Job Title]"} experienced in full software development lifecycle. Expertise in ${widget.skills.take(3).join(", ")}${widget.skills.length > 3 ? " and additional tools" : ""}. Known for strong analytical skills and ability to work effectively in fast-paced environments.',
  ];

  int? _selectedTemplateIndex;
  int _charCount = 0;
  static int _maxChars = 500;
  static int _recommendedMin = 150;
  static int _recommendedMax = 300;

  @override
  void initState() {
    super.initState();
    _charCount = widget.summaryController.text.length;
    widget.summaryController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {
      _charCount = widget.summaryController.text.length;
    });
  }

  @override
  void dispose() {
    widget.summaryController.removeListener(_onTextChanged);
    super.dispose();
  }

  Color get _charCountColor {
    if (_charCount == 0) return Colors.white.withOpacity(0.3);
    if (_charCount < _recommendedMin) {
      return Color(0xFFFFA726);
    }
    if (_charCount <= _recommendedMax) {
      return Color(0xFF66BB6A);
    }
    if (_charCount <= _maxChars) {
      return Color(0xFFFFA726);
    }
    return Color(0xFFEF5350);
  }

  String get _charCountHint {
    if (_charCount == 0) return 'Start writing...';
    if (_charCount < _recommendedMin) {
      return 'Too short - add more details';
    }
    if (_charCount <= _recommendedMax) {
      return 'Perfect length! ✨';
    }
    if (_charCount <= _maxChars) {
      return 'Getting long - consider shortening';
    }
    return 'Too long! Please shorten your summary';
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
            title: 'Professional Summary',
            subtitle: 'Write a brief overview about yourself',
            icon: Icons.text_snippet_outlined,
            color: Color(0xFFFF7043),
          ),

          // ── Summary Text Field ──
          _buildSummaryField(),
          SizedBox(height: 8.h),

          // ── Character Count ──
          _buildCharacterCount(),
          SizedBox(height: 24.h),

          // ── Quick Templates ──
          _buildTemplatesSection(),
          SizedBox(height: 24.h),

          // ── Writing Guide ──
          _buildWritingGuide(),
          SizedBox(height: 24.h),

          // ── ATS Tips ──
          _buildTips(),

          SizedBox(height: 30.h),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // 📝 Summary Field
  // ══════════════════════════════════════════
  Widget _buildSummaryField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _charCount > _maxChars
              ? Color(0xFFEF5350).withOpacity(0.5)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: TextFormField(
        controller: widget.summaryController,
        maxLines: 8,
        maxLength: _maxChars + 50, // soft limit
        style: TextStyle(color: Colors.white, fontSize: 15.sp, height: 1.6),
        cursorColor: Color(0xFFFF7043),
        buildCounter:
            (context, {required currentLength, required isFocused, maxLength}) {
              return SizedBox.shrink();
            },
        decoration: InputDecoration(
          hintText:
              'Write a compelling 2-3 sentence summary that highlights your key qualifications, experience, and career goals...',
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.2),
            fontSize: 14.sp,
            height: 1.5,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.04),
          contentPadding: EdgeInsets.all(18.r),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(color: Color(0xFFFF7043), width: 1.5),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // 🔢 Character Count
  // ══════════════════════════════════════════
  Widget _buildCharacterCount() {
    return Row(
      children: [
        // Progress Bar
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: (_charCount / _recommendedMax).clamp(0.0, 1.0),
              backgroundColor: Colors.white.withOpacity(0.06),
              valueColor: AlwaysStoppedAnimation(_charCountColor),
              minHeight: 4,
            ),
          ),
        ),
        SizedBox(width: 12.w),

        // Count
        Text(
          '$_charCount / $_recommendedMax',
          style: TextStyle(
            color: _charCountColor,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
    // Hint text below
  }

  // ══════════════════════════════════════════
  // 📋 Quick Templates Section
  // ══════════════════════════════════════════
  Widget _buildTemplatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4.w,
              height: 20.h,
              decoration: BoxDecoration(
                color: Color(0xFFFF7043),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(width: 10.w),
            Text(
              'Quick Templates',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            Spacer(),
            Text(
              'Tap to use',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 11.sp,
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),

        ...List.generate(_summaryTemplates.length, (index) {
          final isSelected = _selectedTemplateIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTemplateIndex = index;
                widget.summaryController.text = _summaryTemplates[index];
              });
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 250),
              margin: EdgeInsets.only(bottom: 10.h),
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: isSelected
                    ? Color(0xFFFF7043).withOpacity(0.08)
                    : Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: isSelected
                      ? Color(0xFFFF7043).withOpacity(0.3)
                      : Colors.white.withOpacity(0.06),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Template Number
                  Container(
                    width: 28.r,
                    height: 28.r,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Color(0xFFFF7043).withOpacity(0.15)
                          : Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Center(
                      child: isSelected
                          ? Icon(
                              Icons.check_rounded,
                              color: Color(0xFFFF7043),
                              size: 16.sp,
                            )
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(width: 12.w),

                  // Template Text
                  Expanded(
                    child: Text(
                      _summaryTemplates[index],
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white.withOpacity(0.8)
                            : Colors.white.withOpacity(0.4),
                        fontSize: 12.sp,
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ══════════════════════════════════════════
  // 📖 Writing Guide
  // ══════════════════════════════════════════
  Widget _buildWritingGuide() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Color(0xFFFF7043).withOpacity(0.06),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Color(0xFFFF7043).withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit_note_rounded,
                color: Color(0xFFFF7043).withOpacity(0.8),
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Writing Guide',
                style: TextStyle(
                  color: Color(0xFFFF7043),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          _buildGuideItem(
            '1️⃣',
            'Start with your title & experience level',
            'e.g. "Senior Flutter Developer with 5+ years..."',
          ),
          _buildGuideItem(
            '2️⃣',
            'Mention key skills & technologies',
            'e.g. "Proficient in Flutter, Dart, Firebase..."',
          ),
          _buildGuideItem(
            '3️⃣',
            'Highlight achievements',
            'e.g. "Successfully delivered 20+ mobile apps..."',
          ),
          _buildGuideItem(
            '4️⃣',
            'End with your career goal',
            'e.g. "Seeking to leverage expertise in..."',
          ),
        ],
      ),
    );
  }

  Widget _buildGuideItem(String number, String title, String example) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(number, style: TextStyle(fontSize: 14.sp)),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  example,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 11.sp,
                    fontStyle: FontStyle.italic,
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
  // 💡 ATS Tips
  // ══════════════════════════════════════════
  Widget _buildTips() {
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
                Icons.lightbulb_outline,
                color: Color(0xFF2196F3).withOpacity(0.8),
                size: 18.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'ATS Tips for Summary',
                style: TextStyle(
                  color: Color(0xFF64B5F6),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          _tipItem('Keep it 2-4 sentences (150-300 characters)'),
          _tipItem('Include keywords from the job posting'),
          _tipItem('Avoid personal pronouns (I, me, my)'),
          _tipItem('Use industry-specific terminology'),
          _tipItem('Focus on value you bring, not what you want'),
        ],
      ),
    );
  }

  Widget _tipItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: Colors.white.withOpacity(0.4))),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 12.sp,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
