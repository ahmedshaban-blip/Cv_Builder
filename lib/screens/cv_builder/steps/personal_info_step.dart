// lib/screens/cv_builder/steps/personal_info_step.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

  PersonalInfoStep({
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
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            StepHeader(
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
            SizedBox(height: 16.h),

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
            SizedBox(height: 16.h),

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
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            SizedBox(height: 16.h),

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
            SizedBox(height: 16.h),

            // ── Address ──
            CVTextField(
              controller: addressController,
              label: 'Address',
              hint: 'e.g. Cairo, Egypt',
              icon: Icons.location_on_outlined,
            ),
            SizedBox(height: 24.h),

            // ── Links Section ──
            _buildSectionDivider('Online Profiles'),
            SizedBox(height: 16.h),

            // ── LinkedIn ──
            CVTextField(
              controller: linkedInController,
              label: 'LinkedIn',
              hint: 'linkedin.com/in/username',
              icon: Icons.link_rounded,
              keyboardType: TextInputType.url,
            ),
            SizedBox(height: 16.h),

            // ── GitHub ──
            CVTextField(
              controller: githubController,
              label: 'GitHub',
              hint: 'github.com/username',
              icon: Icons.code_rounded,
              keyboardType: TextInputType.url,
            ),
            SizedBox(height: 16.h),

            // ── Portfolio ──
            CVTextField(
              controller: portfolioController,
              label: 'Portfolio / Website',
              hint: 'yourwebsite.com',
              icon: Icons.language_rounded,
              keyboardType: TextInputType.url,
            ),

            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionDivider(String title) {
    return Row(
      children: [
        Container(
          width: 4.w,
          height: 20.h,
          decoration: BoxDecoration(
            color: Color(0xFF2196F3),
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        SizedBox(width: 10.w),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Container(height: 1.h, color: Colors.white.withOpacity(0.06)),
        ),
      ],
    );
  }
}
