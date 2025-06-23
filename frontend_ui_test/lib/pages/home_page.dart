import 'package:flutter/material.dart';
import '../services/app_colors.dart';
import '../services/buttons.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Home',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PrimaryButton(
              text: 'Scan Barcode',
              onPressed: () {
                Navigator.pushNamed(context, '/barcode');
              },
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              text: 'Upload Receipt',
              onPressed: () {
                Navigator.pushNamed(context, '/ocr');
              },
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              text: 'Profile',
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              text: 'History',
              onPressed: () {
                Navigator.pushNamed(context, '/history');
              },
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              text: 'Feedback',
              onPressed: () {
                Navigator.pushNamed(context, '/feedback');
              },
            ),
          ],
        ),
      ),
    );
  }
}
