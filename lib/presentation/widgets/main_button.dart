import 'package:flutter/material.dart';

class MainButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? color;
  final Color? textColor;

  const MainButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
    this.textColor,
  }); // Costruttore const: ottimo per performance

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon:
            icon != null
                ? Icon(icon, color: textColor ?? Colors.white)
                : const SizedBox.shrink(), // const
        label: Text(
          label,
          style: TextStyle(
            color: textColor ?? Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Colors.teal,
          foregroundColor: textColor ?? Colors.white,
          minimumSize: const Size(double.infinity, 48), // const
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 6,
        ),
        onPressed: onPressed,
      ),
    );
  }
}
