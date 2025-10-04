import 'package:flutter/material.dart';

class SectionProgressionFormulaire extends StatelessWidget {
  final double progression;

  const SectionProgressionFormulaire({
    Key? key,
    required this.progression,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animationValue, child) {
        return Transform.translate(
          offset: Offset(0, (1 - animationValue) * 20),
          child: Opacity(
            opacity: animationValue,
            child: Card(
              elevation: 1,
              margin: EdgeInsets.only(bottom: isSmallScreen ? 16 : 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
              ),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: isSmallScreen ? 16 : 18,
                          color: Colors.blue[600],
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Progression',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 13 : 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        Spacer(),
                        Text(
                          '${(progression * 100).round()}%',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 13,
                            fontWeight: FontWeight.bold,
                            color: progression >= 1.0
                                ? Colors.green[600]
                                : Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 800),
                      tween: Tween(begin: 0.0, end: progression),
                      builder: (context, progressValue, child) {
                        return LinearProgressIndicator(
                          value: progressValue,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progression >= 1.0
                                ? Colors.green[500]!
                                : Colors.blue[500]!,
                          ),
                          minHeight: isSmallScreen ? 4 : 6,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
