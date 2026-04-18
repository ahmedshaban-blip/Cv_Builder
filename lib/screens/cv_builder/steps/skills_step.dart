// lib/screens/cv_builder/steps/skills_step.dart
import 'package:flutter/material.dart';
import '../widgets/builder_widgets.dart';

class SkillsStep extends StatefulWidget {
  final List<String> skillsList;
  final Function(List<String>) onUpdate;

  const SkillsStep({
    super.key,
    required this.skillsList,
    required this.onUpdate,
  });

  @override
  State<SkillsStep> createState() => _SkillsStepState();
}

class _SkillsStepState extends State<SkillsStep> {
  final _skillController = TextEditingController();

  // ── Suggested Skills Categories ──
  final Map<String, List<String>> _suggestedSkills = {
    '💻 Programming': [
      'Python', 'Java', 'JavaScript', 'TypeScript',
      'C++', 'C#', 'Dart', 'Kotlin', 'Swift', 'Go',
      'Rust', 'PHP', 'Ruby',
    ],
    '📱 Mobile': [
      'Flutter', 'React Native', 'Android', 'iOS',
      'SwiftUI', 'Jetpack Compose', 'Xamarin',
    ],
    '🌐 Web': [
      'React', 'Angular', 'Vue.js', 'Next.js',
      'Node.js', 'Express.js', 'HTML', 'CSS',
      'Tailwind CSS', 'Bootstrap', 'WordPress',
    ],
    '🗄️ Backend & DB': [
      'Firebase', 'MongoDB', 'PostgreSQL', 'MySQL',
      'Redis', 'GraphQL', 'REST API', 'Docker',
      'Kubernetes', 'AWS', 'Azure', 'GCP',
    ],
    '🛠️ Tools': [
      'Git', 'GitHub', 'GitLab', 'Jira', 'Figma',
      'VS Code', 'Android Studio', 'Xcode', 'Postman',
      'CI/CD', 'Linux',
    ],
    '📊 Other': [
      'Agile', 'Scrum', 'Problem Solving',
      'Team Leadership', 'Communication',
      'Project Management', 'Data Analysis',
      'Machine Learning', 'UI/UX Design',
    ],
  };

  String _selectedCategory = '💻 Programming';

  @override
  void dispose() {
    _skillController.dispose();
    super.dispose();
  }

  void _addSkill(String skill) {
    if (skill.trim().isNotEmpty &&
        !widget.skillsList.contains(skill.trim())) {
      setState(() {
        widget.skillsList.add(skill.trim());
      });
      widget.onUpdate(widget.skillsList);
      _skillController.clear();
    }
  }

  void _removeSkill(int index) {
    setState(() {
      widget.skillsList.removeAt(index);
    });
    widget.onUpdate(widget.skillsList);
  }

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
            title: 'Skills',
            subtitle: 'Showcase your abilities',
            icon: Icons.psychology_outlined,
            color: Color(0xFF9C27B0),
          ),

          // ── Add Skill Input ──
          _buildSkillInput(),
          const SizedBox(height: 20),

          // ── Added Skills ──
          if (widget.skillsList.isNotEmpty) ...[
            _buildAddedSkills(),
            const SizedBox(height: 24),
          ],

          // ── Category Selector ──
          _buildCategorySelector(),
          const SizedBox(height: 14),

          // ── Suggested Skills ──
          _buildSuggestedSkills(),

          // ── Tips ──
          const SizedBox(height: 24),
          _buildTips(),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // 📝 Skill Input
  // ══════════════════════════════════════════
  Widget _buildSkillInput() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _skillController,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
            cursorColor: const Color(0xFF9C27B0),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (value) => _addSkill(value),
            decoration: InputDecoration(
              hintText: 'Type a skill and press add...',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.2),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.add_circle_outline,
                color: Colors.white.withOpacity(0.3),
                size: 20,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF9C27B0),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _addSkill(_skillController.text),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF9C27B0),
                  Color(0xFF7B1FA2),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9C27B0)
                      .withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════
  // ✅ Added Skills (Chips)
  // ══════════════════════════════════════════
  Widget _buildAddedSkills() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Your Skills',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF9C27B0)
                    .withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${widget.skillsList.length}',
                style: const TextStyle(
                  color: Color(0xFF9C27B0),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.skillsList
              .asMap()
              .entries
              .map((entry) {
            return _buildSkillChip(
              entry.value,
              entry.key,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSkillChip(String skill, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF9C27B0).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF9C27B0).withOpacity(0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            skill,
            style: const TextStyle(
              color: Color(0xFFCE93D8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _removeSkill(index),
            child: const Icon(
              Icons.close_rounded,
              color: Color(0xFFCE93D8),
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // 🏷️ Category Selector
  // ══════════════════════════════════════════
  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suggested Skills',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _suggestedSkills.keys.map((category) {
              final isSelected =
                  _selectedCategory == category;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(
                      milliseconds: 250,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF9C27B0)
                              .withOpacity(0.2)
                          : Colors.white
                              .withOpacity(0.04),
                      borderRadius:
                          BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF9C27B0)
                                .withOpacity(0.4)
                            : Colors.white
                                .withOpacity(0.08),
                      ),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFFCE93D8)
                            : Colors.white
                                .withOpacity(0.5),
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════
  // 💡 Suggested Skills Grid
  // ══════════════════════════════════════════
  Widget _buildSuggestedSkills() {
    final skills =
        _suggestedSkills[_selectedCategory] ?? [];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills.map((skill) {
        final isAdded = widget.skillsList.contains(skill);

        return GestureDetector(
          onTap: isAdded
              ? null
              : () => _addSkill(skill),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: isAdded
                  ? const Color(0xFF4CAF50)
                      .withOpacity(0.1)
                  : Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isAdded
                    ? const Color(0xFF4CAF50)
                        .withOpacity(0.3)
                    : Colors.white.withOpacity(0.1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isAdded)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.check_rounded,
                      color: Color(0xFF4CAF50),
                      size: 14,
                    ),
                  ),
                Text(
                  skill,
                  style: TextStyle(
                    color: isAdded
                        ? const Color(0xFF4CAF50)
                        : Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: isAdded
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ══════════════════════════════════════════
  // 💡 Tips
  // ══════════════════════════════════════════
  Widget _buildTips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2196F3).withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF2196F3).withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: const Color(0xFF2196F3)
                    .withOpacity(0.8),
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'ATS Tips for Skills',
                style: TextStyle(
                  color: Color(0xFF64B5F6),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _tipItem('Match skills from the job description'),
          _tipItem('Include both technical and soft skills'),
          _tipItem('Use standard skill names (not abbreviations)'),
          _tipItem('8-15 skills is the ideal range'),
        ],
      ),
    );
  }

  Widget _tipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4))),
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
}