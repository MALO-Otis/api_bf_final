import 'package:flutter/material.dart';

class SectionObservations extends StatelessWidget {
  final TextEditingController observationsController;

  const SectionObservations({
    Key? key,
    required this.observationsController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 40),
          child: Opacity(
            opacity: value,
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
              ),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.note_alt,
                            color: Colors.orange[600],
                            size: isSmallScreen ? 18 : 22,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 8 : 12),
                        Text(
                          'Observations',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    TextFormField(
                      controller: observationsController,
                      maxLines: isSmallScreen ? 3 : 4,
                      decoration: InputDecoration(
                        hintText: 'Observations ou remarques...',
                        border: const OutlineInputBorder(),
                        hintStyle: TextStyle(
                          fontSize: isSmallScreen ? 13 : 14,
                          color: Colors.grey[500],
                        ),
                        contentPadding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      ),
                      style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
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
