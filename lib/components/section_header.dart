import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 25,
              height: 5,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 20, 50, 81),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Color.fromRGBO(20, 50, 81, 0.5),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Color.fromRGBO(26, 35, 126, 0.5),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 25),
        const Text(
          'Relax Mode',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 20, 50, 81),
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'For rest and recuperation',
          style: TextStyle(
            color: Color.fromRGBO(20, 50, 81, 0.7),
            fontSize: 16,
            letterSpacing: -1.0,
          ),
        ),
      ],
    );
  }
}
