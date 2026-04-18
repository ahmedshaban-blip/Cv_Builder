import 'package:flutter/material.dart';

class TemplateSelectionScreen extends StatelessWidget {
  const TemplateSelectionScreen({super.key});

  static const routeName = '/template_selection';

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Template Selection Screen')),
    );
  }
}
