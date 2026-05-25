import 'package:flutter/material.dart';

class OnboardingIndicator extends StatelessWidget {
  final int length;
  final int currentIndex;

  const OnboardingIndicator({
    super.key,
    required this.length,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 8,
          width: currentIndex == index ? 22 : 10,
          decoration: BoxDecoration(
            color: currentIndex == index
                ? const Color(0xFFFF66AA)
                : Colors.grey.shade400,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
