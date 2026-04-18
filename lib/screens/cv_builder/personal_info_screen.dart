import 'package:flutter/material.dart';

class PersonalInfoScreen extends StatelessWidget {
  const PersonalInfoScreen({super.key});

  static const routeName = '/personal_info';

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Personal Info Screen')));
  }
}
