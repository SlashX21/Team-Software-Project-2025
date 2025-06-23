import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/app_colors.dart';
import '../services/app_styles.dart';

class BarcodePage extends StatefulWidget {
  const BarcodePage({super.key});

  @override
  State<BarcodePage> createState() => _BarcodePageState();
}

class _BarcodePageState extends State<BarcodePage> {
  String? scannedBarcode;

  void _onDetect(Barcode barcode) {
    final String? code = barcode.rawValue;
    if (code != null && scannedBarcode == null) {
      setState(() {
        scannedBarcode = code;
      });
      // TODO: Call backend API with scanned code
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Scan Barcode', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: MobileScanner(
              onDetect: (capture) {
                final barcode = capture.barcodes.first;
                _onDetect(barcode);
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: scannedBarcode != null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Scanned Barcode:', style: AppStyles.bodyBold),
                        const SizedBox(height: 8),
                        Text(
                          scannedBarcode!,
                          style: AppStyles.bodyRegular.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    )
                  : Text('Point the camera at a barcode', style: AppStyles.bodyRegular),
            ),
          ),
        ],
      ),
    );
  }
}
