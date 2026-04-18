// lib/screens/cv_builder/steps/projects_step.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../widgets/builder_widgets.dart';

class ProjectsStep extends StatefulWidget {
  final List<Map<String, dynamic>> projectsList;
  final Function(List<Map<String, dynamic>>) onUpdate;

  const ProjectsStep({
    super.key,
    required this.projectsList,
    required this.onUpdate,
  });

  @override
  State<ProjectsStep> createState() => _ProjectsStepState();
}

class _ProjectsStepState extends State<ProjectsStep> {
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
            title: 'Projects',
            subtitle: 'Showcase your work (Optional)',
            icon: Icons.folder_outlined,
            color: Color(0xFF00BCD4),
          ),

          // ── Optional Note ──
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF00BCD4).withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF00BCD4).withOpacity(0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: const Color(0xFF00BCD4).withOpacity(0.7),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This section is optional but highly recommended for developers',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
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

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project, int index) {
    final technologies = List<String>.from(project['technologies'] ?? []);

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
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF00BCD4).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.folder_outlined,
                  color: Color(0xFF00BCD4),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project['title'] ?? 'Project',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (project['link'] != null &&
                        project['link'].toString().isNotEmpty)
                      Text(
                        project['link'],
                        style: const TextStyle(
                          color: Color(0xFF00BCD4),
                          fontSize: 11,
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
                  size: 18,
                ),
              ),
              IconButton(
                onPressed: () => _deleteProject(index),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFEF5350),
                  size: 18,
                ),
              ),
            ],
          ),

          if (project['description'] != null &&
              project['description'].toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              project['description'],
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          if (technologies.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: technologies.map((tech) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BCD4).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tech,
                    style: const TextStyle(
                      color: Color(0xFF4DD0E1),
                      fontSize: 10,
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
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF00BCD4).withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.2)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: Color(0xFF00BCD4), size: 22),
            SizedBox(width: 8),
            Text(
              'Add Project',
              style: TextStyle(
                color: Color(0xFF00BCD4),
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
            decoration: const BoxDecoration(
              color: Color(0xFF1A1F38),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // ── Header ──
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
                            isEditing ? 'Edit Project' : 'Add Project',
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
                          const SizedBox(height: 14),
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
                          const SizedBox(height: 14),
                          CVTextField(
                            controller: linkCtrl,
                            label: 'Project Link (Optional)',
                            hint: 'e.g. github.com/user/project',
                            icon: Icons.link_rounded,
                            keyboardType: TextInputType.url,
                          ),
                          const SizedBox(height: 18),

                          // Technologies
                          Text(
                            'Technologies Used',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: techCtrl,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                  cursorColor: const Color(0xFF00BCD4),
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
                                        color: Color(0xFF00BCD4),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
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
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF00BCD4,
                                    ).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.add_rounded,
                                    color: Color(0xFF00BCD4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Tech Chips
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: technologies.asMap().entries.map((e) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF00BCD4,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF00BCD4,
                                    ).withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      e.value,
                                      style: const TextStyle(
                                        color: Color(0xFF4DD0E1),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          technologies.removeAt(e.key);
                                        });
                                      },
                                      child: const Icon(
                                        Icons.close_rounded,
                                        color: Color(0xFF4DD0E1),
                                        size: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
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
                        backgroundColor: const Color(0xFF00BCD4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        isEditing ? 'Update Project' : 'Add Project',
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

  void _deleteProject(int index) {
    setState(() {
      widget.projectsList.removeAt(index);
    });
    widget.onUpdate(widget.projectsList);
  }
}
