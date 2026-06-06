import 'package:flutter/material.dart';

class GiglyLoadingSpinner extends StatelessWidget {
  const GiglyLoadingSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}
