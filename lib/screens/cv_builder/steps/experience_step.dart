// lib/screens/cv_builder/steps/experience_step.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';
import '../widgets/builder_widgets.dart';

class ExperienceStep extends StatefulWidget {
  final List<Map<String, dynamic>> experienceList;
  final Function(List<Map<String, dynamic>>) onUpdate;

  const ExperienceStep({
    super.key,
    required this.experienceList,
    required this.onUpdate,
  });

  @override
  State<ExperienceStep> createState() => _ExperienceStepState();
}

class _ExperienceStepState extends State<ExperienceStep> {
  static const List<String> _employmentTypes = [
    'Full Time',
    'Part Time',
    'Contract',
    'Internship',
  ];

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
            child: StepHeader(
              title: 'Work Experience',
              subtitle: 'Add your professional history',
              icon: Icons.work_outline_rounded,
              color: Color(0xFFFFA726),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          sliver: SliverReorderableList(
            itemCount: widget.experienceList.length,
            onReorder: _onReorder,
            itemBuilder: (context, index) {
              final exp = widget.experienceList[index];
              return ReorderableDelayedDragStartListener(
                key: ValueKey(exp['id'] ?? 'exp_$index'),
                index: index,
                child: _buildExperienceCard(exp, index),
              );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: _buildAddButton(),
          ),
        ),
        if (widget.experienceList.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: _buildTips(),
            ),
          ),
        SliverToBoxAdapter(child: SizedBox(height: 30.h)),
      ],
    );
  }

  // ══════════════════════════════════════════
  // 🃏 Experience Card
  // ══════════════════════════════════════════
  Widget _buildExperienceCard(Map<String, dynamic> exp, int index) {
    final responsibilities = List<String>.from(exp['responsibilities'] ?? []);
    final location = (exp['location'] ?? '').toString().trim();
    final employmentType = (exp['employmentType'] ?? '').toString().trim();

    String? locationAndType;
    if (location.isNotEmpty && employmentType.isNotEmpty) {
      locationAndType = '$location - $employmentType';
    } else if (location.isNotEmpty) {
      locationAndType = location;
    } else if (employmentType.isNotEmpty) {
      locationAndType = employmentType;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row ──
          Row(
            children: [
              Container(
                width: 40.r,
                height: 40.r,
                decoration: BoxDecoration(
                  color: Color(0xFFFFA726).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.work_outline_rounded,
                  color: Color(0xFFFFA726),
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exp['position'] ?? 'Position',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 2.h,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          exp['company'] ?? 'Company',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12.sp,
                          ),
                        ),
                        if (locationAndType != null)
                          Text(
                            '• $locationAndType',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.55),
                              fontSize: 12.sp,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.drag_handle_rounded,
                color: Colors.white.withOpacity(0.35),
                size: 20,
              ),
              // Edit
              IconButton(
                onPressed: () =>
                    _showExperienceForm(existingData: exp, index: index),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                iconSize: 20,
                icon: Icon(
                  Icons.edit_outlined,
                  color: Colors.white.withOpacity(0.4),
                  size: 20,
                ),
              ),
              SizedBox(width: 8.w),
              // Delete
              IconButton(
                onPressed: () => _deleteExperience(index),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                iconSize: 20,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFEF5350),
                  size: 20,
                ),
              ),
            ],
          ),

          SizedBox(height: 10.h),

          // ── Date ──
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: Colors.white.withOpacity(0.4),
                  size: 12.sp,
                ),
                SizedBox(width: 6.w),
                Text(
                  '${exp['startDate'] ?? ''} - ${exp['isCurrently'] == true ? 'Present' : exp['endDate'] ?? ''}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),

          // ── Responsibilities ──
          if (responsibilities.isNotEmpty) ...[
            SizedBox(height: 12.h),
            ...responsibilities
                .take(3)
                .map(
                  (r) => Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(top: 6.h),
                          width: 4.r,
                          height: 4.r,
                          decoration: BoxDecoration(
                            color: Color(0xFFFFA726).withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            r,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12.sp,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            if (responsibilities.length > 3)
              Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: Text(
                  '+${responsibilities.length - 3} more...',
                  style: TextStyle(
                    color: Color(0xFFFFA726).withOpacity(0.7),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // ➕ Add Button
  // ══════════════════════════════════════════
  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () => _showExperienceForm(),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 18.h),
        decoration: BoxDecoration(
          color: Color(0xFFFFA726).withOpacity(0.06),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Color(0xFFFFA726).withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: Color(0xFFFFA726), size: 22.sp),
            SizedBox(width: 8.w),
            Text(
              'Add Experience',
              style: TextStyle(
                color: Color(0xFFFFA726),
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // 💡 Tips
  // ══════════════════════════════════════════
  Widget _buildTips() {
    return Container(
      margin: EdgeInsets.only(top: 20.h),
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
                'ATS Tips for Experience',
                style: TextStyle(
                  color: Color(0xFF64B5F6),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          _buildTipItem('Start each bullet with an action verb'),
          _buildTipItem('Include measurable achievements (numbers, %)'),
          _buildTipItem('Use keywords from job descriptions'),
          _buildTipItem('List most recent experience first'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
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

  // ══════════════════════════════════════════
  // 📝 Experience Form Bottom Sheet
  // ══════════════════════════════════════════
  void _showExperienceForm({Map<String, dynamic>? existingData, int? index}) {
    final isEditing = existingData != null;
    final companyCtrl = TextEditingController(
      text: existingData?['company'] ?? '',
    );
    final positionCtrl = TextEditingController(
      text: existingData?['position'] ?? '',
    );
    final locationCtrl = TextEditingController(
      text: existingData?['location'] ?? '',
    );
    String? selectedEmploymentType =
        (existingData?['employmentType'] ?? '').toString().trim().isEmpty
        ? null
        : existingData?['employmentType'];

    if (selectedEmploymentType != null &&
        !_employmentTypes.contains(selectedEmploymentType)) {
      selectedEmploymentType = null;
    }

    final startDateCtrl = TextEditingController(
      text: existingData?['startDate'] ?? '',
    );
    final endDateCtrl = TextEditingController(
      text: existingData?['endDate'] ?? '',
    );

    bool isCurrently = existingData?['isCurrently'] ?? false;

    List<String> responsibilities = List<String>.from(
      existingData?['responsibilities'] ?? [],
    );

    final responsibilityCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: Color(0xFF1A1F38),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            child: Column(
              children: [
                // ── Handle & Header ──
                Padding(
                  padding: EdgeInsets.all(20.r),
                  child: Column(
                    children: [
                      Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Text(
                            isEditing ? 'Edit Experience' : 'Add Experience',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close_rounded,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Form ──
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Position
                          CVTextField(
                            controller: positionCtrl,
                            label: 'Job Title / Position',
                            hint: 'e.g. Senior Flutter Developer',
                            icon: Icons.badge_outlined,
                            isRequired: true,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Required'
                                : null,
                          ),
                          SizedBox(height: 14.h),

                          // Company
                          CVTextField(
                            controller: companyCtrl,
                            label: 'Company',
                            hint: 'e.g. Google',
                            icon: Icons.business_outlined,
                            isRequired: true,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Required'
                                : null,
                          ),
                          SizedBox(height: 14.h),

                          // Location
                          CVTextField(
                            controller: locationCtrl,
                            label: 'Location (Optional)',
                            hint: 'e.g. Cairo, Egypt',
                            icon: Icons.location_on_outlined,
                          ),
                          SizedBox(height: 14.h),

                          DropdownButtonFormField<String>(
                            initialValue: selectedEmploymentType,
                            dropdownColor: Color(0xFF1A1F38),
                            iconEnabledColor: Colors.white.withOpacity(0.7),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Employment Type (Optional)',
                              labelStyle: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12.sp,
                              ),
                              hintText: 'Select employment type',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.2),
                                fontSize: 13.sp,
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.08),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.08),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: BorderSide(
                                  color: Color(0xFFFFA726),
                                ),
                              ),
                            ),
                            items: _employmentTypes
                                .map(
                                  (type) => DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(type),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setModalState(() {
                                selectedEmploymentType = value;
                              });
                            },
                          ),
                          SizedBox(height: 14.h),

                          // Dates
                          Row(
                            children: [
                              Expanded(
                                child: CVTextField(
                                  controller: startDateCtrl,
                                  label: 'Start Date',
                                  hint: 'e.g. Jan 2022',
                                  icon: Icons.calendar_today_outlined,
                                  isRequired: true,
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                      ? 'Required'
                                      : null,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: CVTextField(
                                  controller: endDateCtrl,
                                  label: 'End Date',
                                  hint: isCurrently
                                      ? 'Present'
                                      : 'e.g. Dec 2023',
                                  icon: Icons.calendar_today_outlined,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),

                          // Currently Working
                          Row(
                            children: [
                              Checkbox(
                                value: isCurrently,
                                onChanged: (v) {
                                  setModalState(() {
                                    isCurrently = v ?? false;
                                  });
                                },
                                activeColor: Color(0xFFFFA726),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              Text(
                                'I currently work here',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 13.sp,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 18.h),

                          // ═══════════════════════════
                          // Responsibilities Section
                          // ═══════════════════════════
                          Row(
                            children: [
                              Container(
                                width: 4.w,
                                height: 20.h,
                                decoration: BoxDecoration(
                                  color: Color(0xFFFFA726),
                                  borderRadius: BorderRadius.circular(2.r),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Text(
                                'Key Responsibilities & Achievements',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),

                          // Add Responsibility Input
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: responsibilityCtrl,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.sp,
                                  ),
                                  cursorColor: Color(0xFFFFA726),
                                  decoration: InputDecoration(
                                    hintText:
                                        'e.g. Led a team of 5 developers...',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.2),
                                      fontSize: 13.sp,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.05),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                      borderSide: BorderSide(
                                        color: Colors.white.withOpacity(0.08),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                      borderSide: BorderSide(
                                        color: Colors.white.withOpacity(0.08),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                      borderSide: BorderSide(
                                        color: Color(0xFFFFA726),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              GestureDetector(
                                onTap: () {
                                  if (responsibilityCtrl.text
                                      .trim()
                                      .isNotEmpty) {
                                    setModalState(() {
                                      responsibilities.add(
                                        responsibilityCtrl.text.trim(),
                                      );
                                      responsibilityCtrl.clear();
                                    });
                                  }
                                },
                                child: Container(
                                  width: 46.r,
                                  height: 46.r,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFFA726).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color: Color(0xFFFFA726).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.add_rounded,
                                    color: Color(0xFFFFA726),
                                    size: 22.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),

                          // Responsibility List
                          ...responsibilities.asMap().entries.map(
                            (entry) => _buildResponsibilityItem(
                              entry.value,
                              entry.key,
                              responsibilities,
                              setModalState,
                            ),
                          ),

                          if (responsibilities.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(16.r),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.06),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.list_alt_rounded,
                                    color: Colors.white.withOpacity(0.2),
                                    size: 32.sp,
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'Add your key responsibilities\n'
                                    'and achievements',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.3),
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          SizedBox(height: 20.h),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Save Button ──
                Padding(
                  padding: EdgeInsets.only(
                    left: 20.w,
                    right: 20.w,
                    bottom: MediaQuery.of(context).viewPadding.bottom + 20,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;

                        final data = {
                          'id': existingData?['id'] ?? Uuid().v4(),
                          'company': companyCtrl.text.trim(),
                          'position': positionCtrl.text.trim(),
                          'location': locationCtrl.text.trim(),
                          'employmentType': selectedEmploymentType ?? '',
                          'startDate': startDateCtrl.text.trim(),
                          'endDate': endDateCtrl.text.trim(),
                          'isCurrently': isCurrently,
                          'responsibilities': responsibilities,
                        };

                        setState(() {
                          if (isEditing && index != null) {
                            widget.experienceList[index] = data;
                          } else {
                            widget.experienceList.add(data);
                          }
                        });
                        widget.onUpdate(widget.experienceList);

                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFFA726),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      child: Text(
                        isEditing ? 'Update Experience' : 'Add Experience',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Responsibility Item ──
  Widget _buildResponsibilityItem(
    String text,
    int index,
    List<String> list,
    StateSetter setModalState,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 22.r,
            height: 22.r,
            decoration: BoxDecoration(
              color: Color(0xFFFFA726).withOpacity(0.15),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: Color(0xFFFFA726),
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13.sp,
                height: 1.3,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setModalState(() {
                list.removeAt(index);
              });
            },
            child: Icon(
              Icons.close_rounded,
              color: Color(0xFFEF5350).withOpacity(0.7),
              size: 18.sp,
            ),
          ),
        ],
      ),
    );
  }

  void _deleteExperience(int index) {
    setState(() {
      widget.experienceList.removeAt(index);
    });
    widget.onUpdate(widget.experienceList);
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    setState(() {
      final item = widget.experienceList.removeAt(oldIndex);
      widget.experienceList.insert(newIndex, item);
    });

    widget.onUpdate(widget.experienceList);
  }
}
