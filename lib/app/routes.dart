import 'package:flutter/material.dart';
import 'package:cv_builder/screens/splash/splash_screen.dart';
import 'package:cv_builder/screens/onboarding/onboarding_screen.dart';
import 'package:cv_builder/screens/auth/login_screen.dart';
import 'package:cv_builder/screens/auth/register_screen.dart';
import 'package:cv_builder/screens/auth/forgot_password_screen.dart';
import 'package:cv_builder/screens/home/home_screen.dart';
import 'package:cv_builder/screens/cv_builder/personal_info_screen.dart';
import 'package:cv_builder/screens/cv_builder/education_screen.dart';
import 'package:cv_builder/screens/cv_builder/experience_screen.dart';
import 'package:cv_builder/screens/cv_builder/skills_screen.dart';
import 'package:cv_builder/screens/cv_builder/projects_screen.dart';
import 'package:cv_builder/screens/cv_builder/summary_screen.dart';
import 'package:cv_builder/screens/cv_builder/template_selection_screen.dart';
import 'package:cv_builder/screens/preview/cv_preview_screen.dart';
import 'package:cv_builder/screens/my_cvs/my_cvs_screen.dart';

class AppRoutes {
  static final routes = {
    SplashScreen.routeName: (context) => const SplashScreen(),
    OnboardingScreen.routeName: (context) => const OnboardingScreen(),
    LoginScreen.routeName: (context) => const LoginScreen(),
    RegisterScreen.routeName: (context) => const RegisterScreen(),
    ForgotPasswordScreen.routeName: (context) => const ForgotPasswordScreen(),
    HomeScreen.routeName: (context) => const HomeScreen(),
    PersonalInfoScreen.routeName: (context) => const PersonalInfoScreen(),
    EducationScreen.routeName: (context) => const EducationScreen(),
    ExperienceScreen.routeName: (context) => const ExperienceScreen(),
    SkillsScreen.routeName: (context) => const SkillsScreen(),
    ProjectsScreen.routeName: (context) => const ProjectsScreen(),
    SummaryScreen.routeName: (context) => const SummaryScreen(),
    TemplateSelectionScreen.routeName: (context) =>
        const TemplateSelectionScreen(),
    CVPreviewScreen.routeName: (context) => const CVPreviewScreen(),
    MyCvsScreen.routeName: (context) => const MyCvsScreen(),
  };
}
