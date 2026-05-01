// lib/screens/cv_builder/steps/education_step.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';
import '../widgets/builder_widgets.dart';

class EducationStep extends StatefulWidget {
  final List<Map<String, dynamic>> educationList;
  final Function(List<Map<String, dynamic>>) onUpdate;

  const EducationStep({
    super.key,
    required this.educationList,
    required this.onUpdate,
  });

  @override
  State<EducationStep> createState() => _EducationStepState();
}

class _EducationStepState extends State<EducationStep> {
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: BouncingScrollPhysics(),
      slivers: [
        // ── Header ──
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
            child: StepHeader(
              title: 'Education',
              subtitle: 'Add your academic background',
              icon: Icons.school_outlined,
              color: Color(0xFF66BB6A),
            ),
          ),
        ),

        // ── Education Cards (Reorderable) ──
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          sliver: SliverReorderableList(
            itemCount: widget.educationList.length,
            onReorder: _onReorder,
            itemBuilder: (context, index) {
              final edu = widget.educationList[index];
              return ReorderableDelayedDragStartListener(
                key: ValueKey(edu['id'] ?? 'edu_$index'),
                index: index,
                child: _buildEducationCard(edu, index),
              );
            },
          ),
        ),

        // ── Add Button ──
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: _buildAddButton(),
          ),
        ),

        // ── Tips ──
        if (widget.educationList.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: _buildTips(),
            ),
          ),

        // ── Bottom Padding ──
        SliverToBoxAdapter(child: SizedBox(height: 30.h)),
      ],
    );
  }

  Widget _buildEducationCard(Map<String, dynamic> edu, int index) {
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
          // ── Title Row ──
          Row(
            children: [
              Container(
                width: 40.r,
                height: 40.r,
                decoration: BoxDecoration(
                  color: Color(0xFF66BB6A).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.school_outlined,
                  color: Color(0xFF66BB6A),
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      edu['degree'] ?? 'Degree',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      edu['institution'] ?? 'Institution',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                    _showEducationForm(existingData: edu, index: index),
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
                onPressed: () => _deleteEducation(index),
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

          // ── Details ──
          Row(
            children: [
              _buildDetailChip(Icons.book_outlined, edu['fieldOfStudy'] ?? ''),
              SizedBox(width: 8.w),
              _buildDetailChip(
                Icons.calendar_today_outlined,
                '${edu['startDate'] ?? ''} - ${edu['isCurrently'] == true ? 'Present' : edu['endDate'] ?? ''}',
              ),
            ],
          ),

          if (edu['gpa'] != null && edu['gpa'].toString().isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: _buildDetailChip(
                Icons.grade_outlined,
                'GPA: ${edu['gpa']}',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text) {
    if (text.isEmpty) return SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.4), size: 12.sp),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 11.sp,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () => _showEducationForm(),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 18.h),
        decoration: BoxDecoration(
          color: Color(0xFF66BB6A).withOpacity(0.06),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: Color(0xFF66BB6A).withOpacity(0.2),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: Color(0xFF66BB6A), size: 22.sp),
            SizedBox(width: 8.w),
            Text(
              'Add Education',
              style: TextStyle(
                color: Color(0xFF66BB6A),
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                'ATS Tips',
                style: TextStyle(
                  color: Color(0xFF64B5F6),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          _buildTipItem('List most recent education first'),
          _buildTipItem('Include GPA if above 3.0'),
          _buildTipItem('Use full degree name (not abbreviations)'),
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
          Text(
            '• ',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12.sp,
            ),
          ),
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
  // 📝 Education Form Bottom Sheet
  // ══════════════════════════════════════════
  void _showEducationForm({Map<String, dynamic>? existingData, int? index}) {
    final isEditing = existingData != null;
    final institutionCtrl = TextEditingController(
      text: existingData?['institution'] ?? '',
    );
    final degreeCtrl = TextEditingController(
      text: existingData?['degree'] ?? '',
    );
    final fieldCtrl = TextEditingController(
      text: existingData?['fieldOfStudy'] ?? '',
    );
    final startDateCtrl = TextEditingController(
      text: existingData?['startDate'] ?? '',
    );
    final endDateCtrl = TextEditingController(
      text: existingData?['endDate'] ?? '',
    );
    final gpaCtrl = TextEditingController(text: existingData?['gpa'] ?? '');
    bool isCurrently = existingData?['isCurrently'] ?? false;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
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
                            isEditing ? 'Edit Education' : 'Add Education',
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
                        children: [
                          CVTextField(
                            controller: institutionCtrl,
                            label: 'Institution',
                            hint: 'e.g. Cairo University',
                            icon: Icons.account_balance_outlined,
                            isRequired: true,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Required'
                                : null,
                          ),
                          SizedBox(height: 14.h),
                          CVTextField(
                            controller: degreeCtrl,
                            label: 'Degree',
                            hint: 'e.g. Bachelor of Science',
                            icon: Icons.school_outlined,
                            isRequired: true,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Required'
                                : null,
                          ),
                          SizedBox(height: 14.h),
                          CVTextField(
                            controller: fieldCtrl,
                            label: 'Field of Study',
                            hint: 'e.g. Computer Science',
                            icon: Icons.book_outlined,
                            isRequired: true,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Required'
                                : null,
                          ),
                          SizedBox(height: 14.h),
                          Row(
                            children: [
                              Expanded(
                                child: CVTextField(
                                  controller: startDateCtrl,
                                  label: 'Start Date',
                                  hint: 'e.g. Sep 2019',
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
                                      : 'e.g. Jun 2023',
                                  icon: Icons.calendar_today_outlined,
                                  validator: isCurrently
                                      ? null
                                      : (v) => v == null || v.trim().isEmpty
                                            ? 'Required'
                                            : null,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),

                          // Currently Studying
                          Row(
                            children: [
                              Checkbox(
                                value: isCurrently,
                                onChanged: (v) {
                                  setModalState(() {
                                    isCurrently = v ?? false;
                                  });
                                },
                                activeColor: Color(0xFF66BB6A),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              Text(
                                'Currently studying here',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 13.sp,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          CVTextField(
                            controller: gpaCtrl,
                            label: 'GPA (Optional)',
                            hint: 'e.g. 3.5 / 4.0',
                            icon: Icons.grade_outlined,
                            keyboardType: TextInputType.number,
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
                          'institution': institutionCtrl.text.trim(),
                          'degree': degreeCtrl.text.trim(),
                          'fieldOfStudy': fieldCtrl.text.trim(),
                          'startDate': startDateCtrl.text.trim(),
                          'endDate': endDateCtrl.text.trim(),
                          'isCurrently': isCurrently,
                          'gpa': gpaCtrl.text.trim(),
                        };

                        setState(() {
                          if (isEditing && index != null) {
                            widget.educationList[index] = data;
                          } else {
                            widget.educationList.add(data);
                          }
                        });
                        widget.onUpdate(widget.educationList);

                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF66BB6A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      child: Text(
                        isEditing ? 'Update Education' : 'Add Education',
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

  void _deleteEducation(int index) {
    setState(() {
      widget.educationList.removeAt(index);
    });
    widget.onUpdate(widget.educationList);
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    setState(() {
      final item = widget.educationList.removeAt(oldIndex);
      widget.educationList.insert(newIndex, item);
    });

    widget.onUpdate(widget.educationList);
  }
}
