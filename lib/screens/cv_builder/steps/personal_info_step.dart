// lib/screens/cv_builder/steps/personal_info_step.dart
import 'package:flutter/material.dart';
import '../widgets/builder_widgets.dart';

class PersonalInfoStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController jobTitleController;
  final TextEditingController linkedInController;
  final TextEditingController githubController;
  final TextEditingController portfolioController;

  const PersonalInfoStep({
    super.key,
    required this.formKey,
    required this.fullNameController,
    required this.emailController,
    required this.phoneController,
    required this.addressController,
    required this.jobTitleController,
    required this.linkedInController,
    required this.githubController,
    required this.portfolioController,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            const StepHeader(
              title: 'Personal Information',
              subtitle: 'Tell us about yourself',
              icon: Icons.person_outline_rounded,
              color: Color(0xFF2196F3),
            ),

            // ── Full Name ──
            CVTextField(
              controller: fullNameController,
              label: 'Full Name',
              hint: 'e.g. Ahmed Mohamed',
              icon: Icons.person_outline_rounded,
              isRequired: true,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Full name is required';
                }
                if (v.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Job Title ──
            CVTextField(
              controller: jobTitleController,
              label: 'Job Title',
              hint: 'e.g. Flutter Developer',
              icon: Icons.work_outline_rounded,
              isRequired: true,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Job title is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Email ──
            CVTextField(
              controller: emailController,
              label: 'Email Address',
              hint: 'e.g. ahmed@email.com',
              icon: Icons.email_outlined,
              isRequired: true,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Email is required';
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(v)) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Phone ──
            CVTextField(
              controller: phoneController,
              label: 'Phone Number',
              hint: 'e.g. +20 123 456 7890',
              icon: Icons.phone_outlined,
              isRequired: true,
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Phone number is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Address ──
            CVTextField(
              controller: addressController,
              label: 'Address',
              hint: 'e.g. Cairo, Egypt',
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 24),

            // ── Links Section ──
            _buildSectionDivider('Online Profiles'),
            const SizedBox(height: 16),

            // ── LinkedIn ──
            CVTextField(
              controller: linkedInController,
              label: 'LinkedIn',
              hint: 'linkedin.com/in/username',
              icon: Icons.link_rounded,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),

            // ── GitHub ──
            CVTextField(
              controller: githubController,
              label: 'GitHub',
              hint: 'github.com/username',
              icon: Icons.code_rounded,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),

            // ── Portfolio ──
            CVTextField(
              controller: portfolioController,
              label: 'Portfolio / Website',
              hint: 'yourwebsite.com',
              icon: Icons.language_rounded,
              keyboardType: TextInputType.url,
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionDivider(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withOpacity(0.06),
          ),
        ),
      ],
    );
  }
}