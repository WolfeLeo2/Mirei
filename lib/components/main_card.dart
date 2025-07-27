import 'package:flutter/material.dart';
import 'package:mirei/models/session_info.dart';

class MainCard extends StatelessWidget {
  final SessionInfo session;
  final VoidCallback? onPlay;
  const MainCard({Key? key, required this.session, this.onPlay}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 40.0, 20.0, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SERENITY',
            style: TextStyle(
              color: Color.fromARGB(255, 20, 50, 81),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            session.mainCardText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color.fromARGB(255, 20, 50, 81),
              fontSize: 48,
              fontWeight: FontWeight.bold,
              height: 1.2,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 25),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.play_arrow, size: 20),
            label: const Text(
              '9 Minutes',
              style: TextStyle(
                color: Color.fromARGB(255, 20, 50, 81),
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              foregroundColor: const Color.fromARGB(255, 20, 50, 81),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
