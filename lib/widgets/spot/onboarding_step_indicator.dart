import 'package:flutter/material.dart';

class OnboardingStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const OnboardingStepIndicator({
    Key? key,
    required this.currentStep,
    required this.totalSteps,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalSteps, (index) {
          final isCompleted = index < currentStep;
          final isCurrent = index == currentStep;

          return Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isCompleted
                  ? Theme.of(context).primaryColor
                  : isCurrent
                      ? Theme.of(context).primaryColor.withOpacity(0.5)
                      : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}
