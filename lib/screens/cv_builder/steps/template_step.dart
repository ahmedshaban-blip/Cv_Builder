// lib/screens/cv_builder/steps/template_step.dart
import 'package:flutter/material.dart';
import '../widgets/builder_widgets.dart';

class TemplateStep extends StatefulWidget {
  final String selectedTemplate;
  final Function(String) onSelect;
  final Map<String, dynamic> cvData;

  const TemplateStep({
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
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = Tween<double>(begin: 0.9, end: 1.0)
        .animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    ));
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
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          const StepHeader(
            title: 'Choose Template',
            subtitle: 'Select your CV design',
            icon: Icons.palette_outlined,
            color: Color(0xFFE91E63),
          ),

          // ── Info Banner ──
          _buildInfoBanner(),
          const SizedBox(height: 24),

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
                  color: const Color(0xFF66BB6A),
                  features: [
                    'Simple single-column',
                    'Traditional formatting',
                    'Maximum ATS compatibility',
                    'Best for corporate roles',
                  ],
                ),
                const SizedBox(height: 16),

                // Template 2: Modern
                _buildTemplateCard(
                  id: 'modern',
                  name: 'Modern ATS',
                  description:
                      'Contemporary design with subtle accents. Perfect for tech and creative roles.',
                  icon: Icons.auto_awesome_outlined,
                  color: const Color(0xFFFFA726),
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
          const SizedBox(height: 24),

          // ── Preview Section ──
          _buildPreviewSection(),
          const SizedBox(height: 24),

          // ── Comparison Table ──
          _buildComparisonTable(),
          const SizedBox(height: 24),

          // ── ATS Info ──
          _buildATSInfo(),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // ℹ️ Info Banner
  // ══════════════════════════════════════════
  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE91E63).withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE91E63).withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color:
                  const Color(0xFFE91E63).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.verified_outlined,
              color: Color(0xFFE91E63),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Both templates are ATS-optimized',
                  style: TextStyle(
                    color: Color(0xFFE91E63),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Choose the style that best fits your industry',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
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
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.08)
              : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
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
                  width: 70,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? color.withOpacity(0.3)
                          : Colors.white
                              .withOpacity(0.08),
                    ),
                  ),
                  child: _buildMiniPreview(id, color),
                ),
                const SizedBox(width: 16),

                // ── Info ──
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            icon,
                            color: color,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            name,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white
                                      .withOpacity(0.8),
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: TextStyle(
                          color:
                              Colors.white.withOpacity(0.4),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Selection Indicator ──
                AnimatedContainer(
                  duration:
                      const Duration(milliseconds: 300),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? color
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? color
                          : Colors.white
                              .withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
              ],
            ),

            // ── Features ──
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: features.map((feature) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withOpacity(0.1)
                        : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: isSelected
                            ? color
                            : Colors.white
                                .withOpacity(0.3),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        feature,
                        style: TextStyle(
                          color: isSelected
                              ? color
                              : Colors.white
                                  .withOpacity(0.4),
                          fontSize: 11,
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
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            // Name placeholder
            Container(
              width: double.infinity,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 3),
            Container(
              width: 35,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 5),
            Container(
              width: double.infinity,
              height: 1,
              color: Colors.white.withOpacity(0.1),
            ),
            const SizedBox(height: 5),
            // Section placeholders
            ...List.generate(3, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 4,
                      decoration: BoxDecoration(
                        color:
                            Colors.white.withOpacity(0.15),
                        borderRadius:
                            BorderRadius.circular(1),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 30,
                      height: 3,
                      decoration: BoxDecoration(
                        color:
                            Colors.white.withOpacity(0.08),
                        borderRadius:
                            BorderRadius.circular(1),
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
        padding: const EdgeInsets.all(6),
        child: Column(
          children: [
            // Header with color
            Container(
              width: double.infinity,
              height: 24,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.all(4),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 35,
                    height: 5,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.6),
                      borderRadius:
                          BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    width: 25,
                    height: 3,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.3),
                      borderRadius:
                          BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Section with colored header
            ...List.generate(2, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 30,
                      height: 4,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.4),
                        borderRadius:
                            BorderRadius.circular(1),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: double.infinity,
                      height: 3,
                      decoration: BoxDecoration(
                        color:
                            Colors.white.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(1),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 35,
                      height: 3,
                      decoration: BoxDecoration(
                        color:
                            Colors.white.withOpacity(0.06),
                        borderRadius:
                            BorderRadius.circular(1),
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
    final fullName =
        widget.cvData['fullName'] ?? 'Your Name';
    final jobTitle =
        widget.cvData['jobTitle'] ?? 'Job Title';
    final email = widget.cvData['email'] ?? 'email@example.com';
    final phone = widget.cvData['phone'] ?? '+XX XXX XXX';
    final skills =
        List<String>.from(widget.cvData['skills'] ?? []);
    final isClassic = widget.selectedTemplate == 'classic';
    final color = isClassic
        ? const Color(0xFF66BB6A)
        : const Color(0xFFFFA726);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFFE91E63),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Live Preview',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Preview Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
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
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  jobTitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$email  |  $phone',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 9,
                  ),
                ),
                const Divider(height: 16),
              ],

              // ── Modern Header ──
              if (!isClassic) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius:
                        BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName.toString().toUpperCase(),
                        style: TextStyle(
                          color: Colors.blueGrey[800],
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        jobTitle,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$email  •  $phone',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── Section ──
              Text(
                isClassic
                    ? 'WORK EXPERIENCE'
                    : 'WORK EXPERIENCE',
                style: TextStyle(
                  color: isClassic
                      ? Colors.black87
                      : Colors.blueGrey[800],
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                height: isClassic ? 0.8 : 2,
                width: double.infinity,
                margin:
                    const EdgeInsets.symmetric(vertical: 3),
                color: isClassic
                    ? Colors.grey[400]
                    : Colors.blueGrey[800],
              ),
              const SizedBox(height: 4),
              Text(
                'Your experience will appear here...',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 9,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 10),

              // ── Skills ──
              Text(
                'SKILLS',
                style: TextStyle(
                  color: isClassic
                      ? Colors.black87
                      : Colors.blueGrey[800],
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                height: isClassic ? 0.8 : 2,
                width: double.infinity,
                margin:
                    const EdgeInsets.symmetric(vertical: 3),
                color: isClassic
                    ? Colors.grey[400]
                    : Colors.blueGrey[800],
              ),
              const SizedBox(height: 6),

              if (skills.isNotEmpty)
                isClassic
                    ? Text(
                        skills.take(5).join('  •  '),
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 9,
                        ),
                      )
                    : Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children:
                            skills.take(5).map((s) {
                          return Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors
                                    .blueGrey[300]!,
                                width: 0.5,
                              ),
                              borderRadius:
                                  BorderRadius.circular(3),
                            ),
                            child: Text(
                              s,
                              style: TextStyle(
                                color:
                                    Colors.blueGrey[700],
                                fontSize: 8,
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
                    fontSize: 9,
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
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFFE91E63),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Template Comparison',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.06),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Feature',
                        style: TextStyle(
                          color:
                              Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Classic',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF66BB6A),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Modern',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFFFA726),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Rows
              _buildComparisonRow(
                  'ATS Score', '★★★★★', '★★★★☆'),
              _buildComparisonRow(
                  'Visual Appeal', '★★★☆☆', '★★★★★'),
              _buildComparisonRow(
                  'Layout', 'Single Column', 'Single Column'),
              _buildComparisonRow(
                  'Color', 'Minimal', 'Subtle Accents'),
              _buildComparisonRow(
                  'Best For', 'Corporate', 'Tech/Creative'),
              _buildComparisonRow(
                  'Skill Display', 'Text List', 'Badges'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonRow(
    String feature,
    String classic,
    String modern,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.04),
          ),
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
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              classic,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              modern,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 11,
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
                Icons.security_outlined,
                color: const Color(0xFF2196F3)
                    .withOpacity(0.8),
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'What is ATS?',
                style: TextStyle(
                  color: Color(0xFF64B5F6),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Applicant Tracking Systems (ATS) are software used by 99% of Fortune 500 companies to filter resumes before human review.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),

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
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}