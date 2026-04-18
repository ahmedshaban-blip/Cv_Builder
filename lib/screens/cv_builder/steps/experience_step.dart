// lib/screens/cv_builder/steps/experience_step.dart
import 'package:flutter/material.dart';
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
            title: 'Work Experience',
            subtitle: 'Add your professional history',
            icon: Icons.work_outline_rounded,
            color: Color(0xFFFFA726),
          ),

          // ── Experience Cards ──
          ...widget.experienceList.asMap().entries.map(
            (entry) => _buildExperienceCard(entry.value, entry.key),
          ),

          // ── Add Button ──
          _buildAddButton(),

          // ── Tips ──
          if (widget.experienceList.isEmpty) _buildTips(),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // 🃏 Experience Card
  // ══════════════════════════════════════════
  Widget _buildExperienceCard(Map<String, dynamic> exp, int index) {
    final responsibilities = List<String>.from(exp['responsibilities'] ?? []);

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
          // ── Header Row ──
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA726).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.work_outline_rounded,
                  color: Color(0xFFFFA726),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exp['position'] ?? 'Position',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            exp['company'] ?? 'Company',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (exp['location'] != null &&
                            exp['location'].toString().isNotEmpty) ...[
                          Text(
                            '  •  ',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            exp['location'],
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Edit
              IconButton(
                onPressed: () =>
                    _showExperienceForm(existingData: exp, index: index),
                icon: Icon(
                  Icons.edit_outlined,
                  color: Colors.white.withOpacity(0.4),
                  size: 18,
                ),
              ),
              // Delete
              IconButton(
                onPressed: () => _deleteExperience(index),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFEF5350),
                  size: 18,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Date ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: Colors.white.withOpacity(0.4),
                  size: 12,
                ),
                const SizedBox(width: 6),
                Text(
                  '${exp['startDate'] ?? ''} - ${exp['isCurrently'] == true ? 'Present' : exp['endDate'] ?? ''}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // ── Responsibilities ──
          if (responsibilities.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...responsibilities
                .take(3)
                .map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFA726).withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            r,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
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
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+${responsibilities.length - 3} more...',
                  style: TextStyle(
                    color: const Color(0xFFFFA726).withOpacity(0.7),
                    fontSize: 11,
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
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFA726).withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFA726).withOpacity(0.2)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: Color(0xFFFFA726), size: 22),
            SizedBox(width: 8),
            Text(
              'Add Experience',
              style: TextStyle(
                color: Color(0xFFFFA726),
                fontSize: 14,
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
                'ATS Tips for Experience',
                style: TextStyle(
                  color: Color(0xFF64B5F6),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: Colors.white.withOpacity(0.4))),
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
                            isEditing ? 'Edit Experience' : 'Add Experience',
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
                          const SizedBox(height: 14),

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
                          const SizedBox(height: 14),

                          // Location
                          CVTextField(
                            controller: locationCtrl,
                            label: 'Location (Optional)',
                            hint: 'e.g. Cairo, Egypt',
                            icon: Icons.location_on_outlined,
                          ),
                          const SizedBox(height: 14),

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
                              const SizedBox(width: 12),
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
                          const SizedBox(height: 8),

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
                                activeColor: const Color(0xFFFFA726),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              Text(
                                'I currently work here',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // ═══════════════════════════
                          // Responsibilities Section
                          // ═══════════════════════════
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFA726),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Key Responsibilities & Achievements',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Add Responsibility Input
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: responsibilityCtrl,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                  cursorColor: const Color(0xFFFFA726),
                                  decoration: InputDecoration(
                                    hintText:
                                        'e.g. Led a team of 5 developers...',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.2),
                                      fontSize: 13,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.05),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.white.withOpacity(0.08),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.white.withOpacity(0.08),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFFFA726),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
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
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFFFA726,
                                    ).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFFFA726,
                                      ).withOpacity(0.3),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.add_rounded,
                                    color: Color(0xFFFFA726),
                                    size: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

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
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.06),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.list_alt_rounded,
                                    color: Colors.white.withOpacity(0.2),
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add your key responsibilities\n'
                                    'and achievements',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.3),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
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
                          'company': companyCtrl.text.trim(),
                          'position': positionCtrl.text.trim(),
                          'location': locationCtrl.text.trim(),
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
                        backgroundColor: const Color(0xFFFFA726),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        isEditing ? 'Update Experience' : 'Add Experience',
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

  // ── Responsibility Item ──
  Widget _buildResponsibilityItem(
    String text,
    int index,
    List<String> list,
    StateSetter setModalState,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFFFFA726).withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Color(0xFFFFA726),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
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
              color: const Color(0xFFEF5350).withOpacity(0.7),
              size: 18,
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
}
