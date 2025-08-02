// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class InfoBox extends StatelessWidget {
  final String title;
  final int value;
  final List<Color> gradientColors;
  final IconData icon;
  final Color iconColor;

  const InfoBox({
    super.key,
    required this.title,
    required this.value,
    required this.gradientColors,
    required this.icon,
    required this.iconColor,
  }); // Costruttore const: ottimo per performance

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            offset: const Offset(0, 6), // const
            blurRadius: 12,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16), // const
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 8), // const
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10), // const
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
