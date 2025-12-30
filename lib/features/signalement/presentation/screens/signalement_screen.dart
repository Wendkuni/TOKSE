import 'package:flutter/material.dart';

class SignalementScreen extends StatelessWidget {
  const SignalementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau Signalement'),
      ),
      body: const Center(
        child: Text('Signalement Screen'),
      ),
    );
  }
}
