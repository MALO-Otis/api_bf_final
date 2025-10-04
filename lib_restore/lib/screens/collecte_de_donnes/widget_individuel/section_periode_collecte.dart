import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SectionPeriodeCollecte extends StatelessWidget {
  final String periodeCollecte;
  final Function(String) onPeriodeChanged;

  const SectionPeriodeCollecte({
    Key? key,
    required this.periodeCollecte,
    required this.onPeriodeChanged,
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
                            color: Colors.purple[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.date_range,
                            color: Colors.purple[600],
                            size: isSmallScreen ? 18 : 22,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 8 : 12),
                        Text(
                          'Période de Collecte',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                      decoration: BoxDecoration(
                        color: Colors.purple[50],
                        borderRadius:
                            BorderRadius.circular(isSmallScreen ? 8 : 10),
                        border: Border.all(color: Colors.purple[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date de collecte',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 13 : 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.purple[700],
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 6 : 8),
                          InkWell(
                            onTap: () async {
                              final initial =
                                  _parseDateOrNull(periodeCollecte) ??
                                      DateTime.now();
                              final DateTime? picked =
                                  await showDialog<DateTime>(
                                context: context,
                                builder: (ctx) {
                                  DateTime temp = initial;
                                  return Dialog(
                                    insetPadding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 12 : 24,
                                      vertical: isSmallScreen ? 24 : 32,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Container(
                                      padding: EdgeInsets.all(
                                          isSmallScreen ? 8 : 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        color: Colors.white,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical:
                                                    isSmallScreen ? 8 : 12),
                                            child: Row(
                                              children: [
                                                Icon(Icons.calendar_month,
                                                    color: Colors.purple[600]),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Sélectionner une date',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize:
                                                        isSmallScreen ? 14 : 16,
                                                  ),
                                                ),
                                                Spacer(),
                                                IconButton(
                                                  icon: Icon(Icons.close,
                                                      color: Colors.grey[600]),
                                                  onPressed: () =>
                                                      Navigator.of(ctx).pop(),
                                                )
                                              ],
                                            ),
                                          ),
                                          Divider(height: 1),
                                          CalendarDatePicker(
                                            initialDate: initial,
                                            firstDate: DateTime(2020, 1, 1),
                                            lastDate: DateTime(2035, 12, 31),
                                            onDateChanged: (d) {
                                              temp = d;
                                            },
                                          ),
                                          SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              TextButton.icon(
                                                onPressed: () {
                                                  final today = DateTime.now();
                                                  Navigator.of(ctx).pop(today);
                                                },
                                                icon: Icon(Icons.today,
                                                    color: Colors.purple[700]),
                                                label: Text('Aujourd\'hui',
                                                    style: TextStyle(
                                                        color: Colors
                                                            .purple[700])),
                                              ),
                                              ElevatedButton.icon(
                                                onPressed: () =>
                                                    Navigator.of(ctx).pop(temp),
                                                icon: Icon(Icons.check),
                                                label: Text('Valider'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.purple[600],
                                                  foregroundColor: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                              if (picked != null) {
                                final newVal = _formatDate(picked);
                                onPeriodeChanged(newVal);
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 10 : 12,
                                vertical: isSmallScreen ? 12 : 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.purple[300]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: Colors.purple[600],
                                    size: isSmallScreen ? 18 : 20,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      periodeCollecte,
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 14 : 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ),
                                  Icon(Icons.edit_calendar,
                                      color: Colors.purple[600]),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 6 : 8),
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: isSmallScreen ? 14 : 16,
                                color: Colors.purple[600],
                              ),
                              SizedBox(width: isSmallScreen ? 4 : 6),
                              Text(
                                'Touchez pour choisir une date (JJ/MM/AAAA)',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 11 : 12,
                                  color: Colors.purple[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  bool _isValidDate(String date) {
    if (date.length != 10) return false;

    final parts = date.split('/');
    if (parts.length != 3) return false;

    try {
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      if (day < 1 || day > 31) return false;
      if (month < 1 || month > 12) return false;
      if (year < 2020 || year > 2035) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  DateTime? _parseDateOrNull(String raw) {
    if (!_isValidDate(raw)) return null;
    final p = raw.split('/');
    return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
  }

  String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd/$mm/$yyyy';
  }
}

class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.length <= 2) {
      return newValue;
    } else if (text.length <= 5) {
      final formatted = '${text.substring(0, 2)}/${text.substring(2)}';
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    } else if (text.length <= 10) {
      final formatted =
          '${text.substring(0, 2)}/${text.substring(2, 4)}/${text.substring(4)}';
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    return oldValue;
  }
}
