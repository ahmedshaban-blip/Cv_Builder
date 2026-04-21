import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SectionHeader extends StatelessWidget {
  final String title;

  SectionHeader({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0.h),
      child: Text(
        title,
        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
      ),
    );
  }
}
