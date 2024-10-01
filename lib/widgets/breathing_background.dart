import 'package:flutter/material.dart';

class BreathingBackground extends StatelessWidget {
  final Animation<double> animation;

  const BreathingBackground({Key? key, required this.animation}) : super(key: key);

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
                // Darken the inner color and reduce its opacity
                HSLColor.fromColor(Theme.of(context).colorScheme.surface)
                    .withLightness(0.3 + 0.1 * animation.value)
                    .toColor()
                    .withOpacity(0.5),
                // Darken the outer color
                Theme.of(context).colorScheme.background.withOpacity(0.95),
              ],
            ),
          ),
        );
      },
    );
  }
}