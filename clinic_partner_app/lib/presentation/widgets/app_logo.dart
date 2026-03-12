import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final double borderRadius;

  const AppLogo({
    super.key,
    this.size = 120,
    this.borderRadius = 30,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        'images/cerebro.jpg',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF00B8A9), Color(0xFF6FCF4E)],
              ),
            ),
            child: Icon(
              Icons.psychology_rounded,
              size: size * 0.55,
              color: Colors.white,
            ),
          );
        },
      ),
    );
  }
}
