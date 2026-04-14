import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String formatDate(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);
String formatTime(DateTime dt) => DateFormat('HH:mm:ss').format(dt);
String formatDateTime(DateTime dt) => DateFormat('MMM d, yyyy  HH:mm').format(dt);
String formatPercent(double v) => '${(v * 100).toStringAsFixed(1)}%';

void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
  ));
}
