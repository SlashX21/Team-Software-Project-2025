import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/app_colors.dart';
import '../services/app_styles.dart';
import '../services/buttons.dart';
import '../services/api.dart';

class OCRPage extends StatefulWidget {
  const OCRPage({super.key});

  @override
  State<OCRPage> createState() => _OCRPageState();
}

class _OCRPageState extends State<OCRPage> {
  File? _image;
  List<String> _products = [];
  bool _loading = false;

  Future<void> pickImageAndUpload() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
        _loading = true;
      });
      final result = await ApiService.uploadReceipt(_image!);
      setState(() {
        _products = result;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Upload Receipt', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _image != null
                  ? Image.file(_image!, height: 200)
                  : Text('No image selected.', style: AppStyles.bodyRegular),
              const SizedBox(height: 16),
              PrimaryButton(
                text: 'Select Receipt Image',
                onPressed: pickImageAndUpload,
              ),
              const SizedBox(height: 24),
              if (_loading)
                const CircularProgressIndicator()
              else if (_products.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Detected Products:', style: AppStyles.bodyBold),
                    const SizedBox(height: 8),
                    ..._products.map((p) => Text("- $p", style: AppStyles.bodyRegular)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
