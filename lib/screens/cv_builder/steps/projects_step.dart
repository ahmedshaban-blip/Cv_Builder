// lib/screens/cv_builder/steps/projects_step.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';
import '../widgets/builder_widgets.dart';

class ProjectsStep extends StatefulWidget {
  final List<Map<String, dynamic>> projectsList;
  final Function(List<Map<String, dynamic>>) onUpdate;

  ProjectsStep({super.key, required this.projectsList, required this.onUpdate});

  @override
  State<ProjectsStep> createState() => _ProjectsStepState();
}

class _ProjectsStepState extends State<ProjectsStep> {
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
            title: 'Projects',
            subtitle: 'Showcase your work (Optional)',
            icon: Icons.folder_outlined,
            color: Color(0xFF00BCD4),
          ),

          // ── Optional Note ──
          Container(
            padding: EdgeInsets.all(12.r),
            margin: EdgeInsets.only(bottom: 16.h),
            decoration: BoxDecoration(
              color: Color(0xFF00BCD4).withOpacity(0.06),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Color(0xFF00BCD4).withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF00BCD4).withOpacity(0.7),
                  size: 18.sp,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'This section is optional but highly recommended for developers',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Project Cards ──
          ...widget.projectsList.asMap().entries.map(
            (entry) => _buildProjectCard(entry.value, entry.key),
          ),

          // ── Add Button ──
          _buildAddButton(),

          SizedBox(height: 30.h),
        ],
      ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project, int index) {
    final technologies = List<String>.from(project['technologies'] ?? []);

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
          Row(
            children: [
              Container(
                width: 40.r,
                height: 40.r,
                decoration: BoxDecoration(
                  color: Color(0xFF00BCD4).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.folder_outlined,
                  color: Color(0xFF00BCD4),
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project['title'] ?? 'Project',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (project['link'] != null &&
                        project['link'].toString().isNotEmpty)
                      Text(
                        project['link'],
                        style: TextStyle(
                          color: Color(0xFF00BCD4),
                          fontSize: 11.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () =>
                    _showProjectForm(existingData: project, index: index),
                icon: Icon(
                  Icons.edit_outlined,
                  color: Colors.white.withOpacity(0.4),
                  size: 18.sp,
                ),
              ),
              IconButton(
                onPressed: () => _deleteProject(index),
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFEF5350),
                  size: 18.sp,
                ),
              ),
            ],
          ),

          if (project['description'] != null &&
              project['description'].toString().isNotEmpty) ...[
            SizedBox(height: 10.h),
            Text(
              project['description'],
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12.sp,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          if (technologies.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: technologies.map((tech) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFF00BCD4).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    tech,
                    style: TextStyle(
                      color: Color(0xFF4DD0E1),
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () => _showProjectForm(),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 18.h),
        decoration: BoxDecoration(
          color: Color(0xFF00BCD4).withOpacity(0.06),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Color(0xFF00BCD4).withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: Color(0xFF00BCD4), size: 22.sp),
            SizedBox(width: 8.w),
            Text(
              'Add Project',
              style: TextStyle(
                color: Color(0xFF00BCD4),
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
  // 📝 Project Form Bottom Sheet
  // ══════════════════════════════════════════
  void _showProjectForm({Map<String, dynamic>? existingData, int? index}) {
    final isEditing = existingData != null;
    final titleCtrl = TextEditingController(text: existingData?['title'] ?? '');
    final descCtrl = TextEditingController(
      text: existingData?['description'] ?? '',
    );
    final linkCtrl = TextEditingController(text: existingData?['link'] ?? '');
    final techCtrl = TextEditingController();

    List<String> technologies = List<String>.from(
      existingData?['technologies'] ?? [],
    );

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
                // ── Header ──
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
                            isEditing ? 'Edit Project' : 'Add Project',
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
                          CVTextField(
                            controller: titleCtrl,
                            label: 'Project Name',
                            hint: 'e.g. E-Commerce App',
                            icon: Icons.folder_outlined,
                            isRequired: true,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Required'
                                : null,
                          ),
                          SizedBox(height: 14.h),
                          CVTextField(
                            controller: descCtrl,
                            label: 'Description',
                            hint:
                                'Briefly describe the project and your role...',
                            icon: Icons.description_outlined,
                            maxLines: 4,
                            isRequired: true,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Required'
                                : null,
                          ),
                          SizedBox(height: 14.h),
                          CVTextField(
                            controller: linkCtrl,
                            label: 'Project Link (Optional)',
                            hint: 'e.g. github.com/user/project',
                            icon: Icons.link_rounded,
                            keyboardType: TextInputType.url,
                          ),
                          SizedBox(height: 18.h),

                          // Technologies
                          Text(
                            'Technologies Used',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: techCtrl,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.sp,
                                  ),
                                  cursorColor: Color(0xFF00BCD4),
                                  onFieldSubmitted: (v) {
                                    if (v.trim().isNotEmpty) {
                                      setModalState(() {
                                        technologies.add(v.trim());
                                        techCtrl.clear();
                                      });
                                    }
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'e.g. Flutter',
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
                                        color: Color(0xFF00BCD4),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              GestureDetector(
                                onTap: () {
                                  if (techCtrl.text.trim().isNotEmpty) {
                                    setModalState(() {
                                      technologies.add(techCtrl.text.trim());
                                      techCtrl.clear();
                                    });
                                  }
                                },
                                child: Container(
                                  width: 46.r,
                                  height: 46.r,
                                  decoration: BoxDecoration(
                                    color: Color(0xFF00BCD4).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Icon(
                                    Icons.add_rounded,
                                    color: Color(0xFF00BCD4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),

                          // Tech Chips
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: technologies.asMap().entries.map((e) {
                              return Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFF00BCD4).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: Color(0xFF00BCD4).withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      e.value,
                                      style: TextStyle(
                                        color: Color(0xFF4DD0E1),
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                    GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          technologies.removeAt(e.key);
                                        });
                                      },
                                      child: Icon(
                                        Icons.close_rounded,
                                        color: Color(0xFF4DD0E1),
                                        size: 14.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
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
                          'title': titleCtrl.text.trim(),
                          'description': descCtrl.text.trim(),
                          'link': linkCtrl.text.trim(),
                          'technologies': technologies,
                        };

                        setState(() {
                          if (isEditing && index != null) {
                            widget.projectsList[index] = data;
                          } else {
                            widget.projectsList.add(data);
                          }
                        });
                        widget.onUpdate(widget.projectsList);

                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF00BCD4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      child: Text(
                        isEditing ? 'Update Project' : 'Add Project',
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

  void _deleteProject(int index) {
    setState(() {
      widget.projectsList.removeAt(index);
    });
    widget.onUpdate(widget.projectsList);
  }
}
