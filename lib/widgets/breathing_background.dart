import 'package:flutter/material.dart';

class BreathingBackground extends StatelessWidget {
  final Animation<double> animation;

  const BreathingBackground({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.5 + 0.5 * animation.value,
              colors: [
                // Darker color in the center
                Theme.of(context).colorScheme.surface.withOpacity(0.95),
                // Lighter color at the edges
                HSLColor.fromColor(Theme.of(context).colorScheme.surface)
                    .withLightness(0.6 + 0.1 * animation.value)
                    .toColor()
                    .withOpacity(0.99),
              ],
            ),
          ),
        );
      },
    );
  }
}