// lib/screens/cv_builder/steps/education_step.dart
import 'package:flutter/material.dart';
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
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          const StepHeader(
            title: 'Education',
            subtitle: 'Add your academic background',
            icon: Icons.school_outlined,
            color: Color(0xFF66BB6A),
          ),

          // ── Education Cards ──
          ...widget.educationList.asMap().entries.map(
            (entry) => _buildEducationCard(entry.value, entry.key),
          ),

          // ── Add Button ──
          _buildAddButton(),

          // ── Tips ──
          if (widget.educationList.isEmpty) _buildTips(),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildEducationCard(Map<String, dynamic> edu, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title Row ──
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF66BB6A).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school_outlined,
                  color: Color(0xFF66BB6A),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      edu['degree'] ?? 'Degree',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      edu['institution'] ?? 'Institution',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Edit
              IconButton(
                onPressed: () =>
                    _showEducationForm(existingData: edu, index: index),
                icon: Icon(
                  Icons.edit_outlined,
                  color: Colors.white.withOpacity(0.4),
                  size: 18,
                ),
              ),
              // Delete
              IconButton(
                onPressed: () => _deleteEducation(index),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFEF5350),
                  size: 18,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Details ──
          Row(
            children: [
              _buildDetailChip(Icons.book_outlined, edu['fieldOfStudy'] ?? ''),
              const SizedBox(width: 8),
              _buildDetailChip(
                Icons.calendar_today_outlined,
                '${edu['startDate'] ?? ''} - ${edu['isCurrently'] == true ? 'Present' : edu['endDate'] ?? ''}',
              ),
            ],
          ),

          if (edu['gpa'] != null && edu['gpa'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
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
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.4), size: 12),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 11,
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
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF66BB6A).withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF66BB6A).withOpacity(0.2),
            style: BorderStyle.solid,
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: Color(0xFF66BB6A), size: 22),
            SizedBox(width: 8),
            Text(
              'Add Education',
              style: TextStyle(
                color: Color(0xFF66BB6A),
                fontSize: 14,
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
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2196F3).withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: const Color(0xFF2196F3).withOpacity(0.8),
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'ATS Tips',
                style: TextStyle(
                  color: Color(0xFF64B5F6),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildTipItem('List most recent education first'),
          _buildTipItem('Include GPA if above 3.0'),
          _buildTipItem('Use full degree name (not abbreviations)'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 12,
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
            decoration: const BoxDecoration(
              color: Color(0xFF1A1F38),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // ── Handle & Header ──
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            isEditing ? 'Edit Education' : 'Add Education',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20),
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
                          const SizedBox(height: 14),
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
                          const SizedBox(height: 14),
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
                          const SizedBox(height: 14),
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
                              const SizedBox(width: 12),
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
                          const SizedBox(height: 10),

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
                                activeColor: const Color(0xFF66BB6A),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              Text(
                                'Currently studying here',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          CVTextField(
                            controller: gpaCtrl,
                            label: 'GPA (Optional)',
                            hint: 'e.g. 3.5 / 4.0',
                            icon: Icons.grade_outlined,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Save Button ──
                Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: MediaQuery.of(context).viewPadding.bottom + 20,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;

                        final data = {
                          'id': existingData?['id'] ?? const Uuid().v4(),
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
                        backgroundColor: const Color(0xFF66BB6A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        isEditing ? 'Update Education' : 'Add Education',
                        style: const TextStyle(
                          fontSize: 16,
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
}
