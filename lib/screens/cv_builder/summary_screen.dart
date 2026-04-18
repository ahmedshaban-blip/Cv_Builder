import 'package:flutter/material.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  static const routeName = '/summary';

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Summary Screen')));
  }
}
