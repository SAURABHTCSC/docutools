import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Helper function to format bytes into KB, MB, etc.
String formatBytes(int bytes, [int decimals = 2]) {
  if (bytes <= 0) return "0 B";
  return NumberFormat.compactSimpleCurrency(
    locale: 'en_US',
    name: 'B', // Use 'B' for bytes
    decimalDigits: decimals,
  ).format(bytes).replaceAll('\$',''); // Remove currency symbol
}

// --- NEW FUNCTION TO SHOW SNACKBAR AT THE TOP ---
void showTopSnackbar(BuildContext context, String message, {bool isError = false}) {
  if (!context.mounted) return;

  final snackBar = SnackBar(
    content: Text(
      message,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
    // This makes it green for success, red for error
    backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
    // This makes it a floating banner at the top
    behavior: SnackBarBehavior.floating,
    // This is the magic to position it at the top
    margin: EdgeInsets.only(
      bottom: MediaQuery.of(context).size.height - 100, // Push to top
      left: 20,
      right: 20,
    ),
    duration: const Duration(seconds: 3),
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
