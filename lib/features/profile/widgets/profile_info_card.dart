import 'package:flutter/material.dart';

class ProfileInfoCard extends StatelessWidget {
  const ProfileInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Color(0xFF2F2F2F),
            child: Icon(Icons.person, color: Colors.white70, size: 34),
          ),
          SizedBox(height: 14),
          Text(
            'Guest User',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 6),
          Text('user@example.com', style: TextStyle(color: Color(0xFF9E9E9E))),
        ],
      ),
    );
  }
}
