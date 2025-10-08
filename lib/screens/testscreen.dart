import 'package:flutter/material.dart';

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Screen'),
      ),
      body: Center(
        child: Chip(
          avatar: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Text('A'),
          ),
          label: const Text('Example Chip'
          )
      ),
      ),
    );
    
  }
}