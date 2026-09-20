import 'package:flutter/material.dart';

/// Centered loading indicator with an optional message.
class CustomLoadingState extends StatelessWidget {
  final String? message;

  const CustomLoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }
}
