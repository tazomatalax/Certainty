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
              radius: 0.8 * animation.value,
              colors: [
                Theme.of(context).colorScheme.surface.withOpacity(0.6),
                Theme.of(context).colorScheme.background.withOpacity(0.9),
              ],
            ),
          ),
        );
      },
    );
  }
}