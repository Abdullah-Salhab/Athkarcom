import 'package:flutter/material.dart';

class ExceptionPopup extends StatelessWidget {
  final String exceptionMessage;

  const ExceptionPopup({super.key, required this.exceptionMessage});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Error'),
      content: Text(exceptionMessage),
      actions: [
        TextButton(
          child: const Text('حسناً'),
          onPressed: () {
            Navigator.of(context).pop();  // Close the dialog
          },
        ),
      ],
    );
  }
}

// Function to show the popup
void showExceptionPopup(BuildContext context, String exceptionMessage) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return ExceptionPopup(exceptionMessage: exceptionMessage);
    },
  );
}
