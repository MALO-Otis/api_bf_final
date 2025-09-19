import 'package:flutter/material.dart';

class SectionChampsManquants extends StatelessWidget {
  final List<String> champsManquants;

  const SectionChampsManquants({
    Key? key,
    required this.champsManquants,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    if (champsManquants.isEmpty) {
      return const SizedBox.shrink();
    }

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            margin: EdgeInsets.only(bottom: isSmallScreen ? 16 : 20),
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              border: Border.all(color: Colors.orange[300]!, width: 1.5),
              borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.checklist_rtl,
                      color: Colors.orange[700],
                      size: isSmallScreen ? 20 : 24,
                    ),
                    SizedBox(width: isSmallScreen ? 6 : 8),
                    Expanded(
                      child: Text(
                        "Éléments à compléter",
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 6 : 8,
                        vertical: isSmallScreen ? 2 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${champsManquants.length}",
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 8 : 10),
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: champsManquants
                        .map(
                          (champ) => Padding(
                            padding: EdgeInsets.only(
                              bottom: isSmallScreen ? 4 : 6,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: EdgeInsets.only(
                                    top: isSmallScreen ? 4 : 6,
                                    right: isSmallScreen ? 6 : 8,
                                  ),
                                  width: isSmallScreen ? 4 : 5,
                                  height: isSmallScreen ? 4 : 5,
                                  decoration: BoxDecoration(
                                    color: Colors.orange[400],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    champ.replaceAll('• ', ''),
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 12 : 13,
                                      color: Colors.orange[700],
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
