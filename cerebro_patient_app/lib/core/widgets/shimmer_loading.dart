import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1E2D42) : const Color(0xFFE2E8F0),
      highlightColor:
          isDark ? const Color(0xFF2A3F5A) : const Color(0xFFF1F5F9),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class ShimmerLine extends StatelessWidget {
  final double? width;
  final double height;

  const ShimmerLine({super.key, this.width, this.height = 14});

  @override
  Widget build(BuildContext context) {
    return ShimmerBox(
      width: width ?? double.infinity,
      height: height,
      radius: 6,
    );
  }
}

class ShimmerCircle extends StatelessWidget {
  final double size;

  const ShimmerCircle({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1E2D42) : const Color(0xFFE2E8F0),
      highlightColor:
          isDark ? const Color(0xFF2A3F5A) : const Color(0xFFF1F5F9),
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class ShimmerCard extends StatelessWidget {
  final double height;

  const ShimmerCard({super.key, this.height = 100});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ShimmerBox(width: double.infinity, height: height, radius: 16),
    );
  }
}

class ShimmerListTile extends StatelessWidget {
  const ShimmerListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const ShimmerCircle(size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLine(width: MediaQuery.of(context).size.width * 0.4),
                const SizedBox(height: 8),
                ShimmerLine(width: MediaQuery.of(context).size.width * 0.6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ShimmerHomeLoader extends StatelessWidget {
  const ShimmerHomeLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerLine(width: 160, height: 18),
          const SizedBox(height: 6),
          const ShimmerLine(width: 120, height: 28),
          const SizedBox(height: 24),
          ShimmerBox(width: double.infinity, height: 90, radius: 20),
          const SizedBox(height: 28),
          const ShimmerLine(width: 130, height: 18),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: ShimmerBox(width: 0, height: 100, radius: 16)),
              const SizedBox(width: 14),
              Expanded(child: ShimmerBox(width: 0, height: 100, radius: 16)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: ShimmerBox(width: 0, height: 100, radius: 16)),
              const SizedBox(width: 14),
              Expanded(child: ShimmerBox(width: 0, height: 100, radius: 16)),
            ],
          ),
          const SizedBox(height: 28),
          const ShimmerLine(width: 110, height: 18),
          const SizedBox(height: 14),
          ShimmerBox(width: double.infinity, height: 160, radius: 16),
        ],
      ),
    );
  }
}
