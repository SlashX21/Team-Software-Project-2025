import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';

class LabelledNumberInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final double? min;
  final double? max;
  final String? suffix;
  final bool allowDecimal;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final VoidCallback? onFieldSubmitted;
  final bool enabled;
  final TextInputAction? textInputAction;

  const LabelledNumberInput({
    Key? key,
    required this.label,
    required this.controller,
    this.min,
    this.max,
    this.suffix,
    this.allowDecimal = false,
    this.validator,
    this.focusNode,
    this.onFieldSubmitted,
    this.enabled = true,
    this.textInputAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppStyles.bodyRegular.copyWith(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey[300] 
                    : AppColors.textLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: enabled
                ? TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: enabled,
                    keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
                    textInputAction: textInputAction,
                    inputFormatters: [
                      if (!allowDecimal) FilteringTextInputFormatter.digitsOnly,
                      if (allowDecimal) 
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}$')),
                    ],
                    validator: validator ?? (value) {
                      if (value == null || value.isEmpty) return null;
                      
                      final number = double.tryParse(value);
                      if (number == null) {
                        return allowDecimal ? 'Please enter a valid number' : 'Please enter a whole number';
                      }
                      
                      if (min != null && number < min!) {
                        return 'Must be at least $min${suffix ?? ''}';
                      }
                      
                      if (max != null && number > max!) {
                        return 'Must be at most $max${suffix ?? ''}';
                      }
                      
                      return null;
                    },
                    onFieldSubmitted: (_) => onFieldSubmitted?.call(),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.grey[600]! 
                              : Colors.grey[300]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.grey[600]! 
                              : Colors.grey[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      suffixText: suffix,
                      suffixStyle: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.grey[400] 
                            : Colors.grey[600],
                      ),
                    ),
                  )
                : Text(
                    '${controller.text}${suffix ?? ''}',
                    style: AppStyles.bodyRegular.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.grey[300] 
                          : AppColors.textDark,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
} 