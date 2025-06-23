import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

ElevatedButton froyoFlatBtn(String text, onPressed) {
  return ElevatedButton(
    onPressed: onPressed,
    child: Text(text),
    style: ElevatedButton.styleFrom(
      foregroundColor: AppColors.white,
      backgroundColor: AppColors.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
  );
}

OutlinedButton froyoOutlineBtn(String text, onPressed) {
  return OutlinedButton(
    onPressed: onPressed,
    child: Text(text),
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      side: BorderSide(color: AppColors.primary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
  );
}
