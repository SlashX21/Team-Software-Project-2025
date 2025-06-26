import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';

class LabelledDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> options;
  final String Function(T) displayText;
  final ValueChanged<T>? onChanged;
  final bool enabled;

  const LabelledDropdown({
    Key? key,
    required this.label,
    required this.value,
    required this.options,
    required this.displayText,
    this.onChanged,
    this.enabled = true,
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
                ? DropdownButtonFormField<T>(
                    value: value,
                    items: options.map((option) => DropdownMenuItem<T>(
                      value: option,
                      child: Text(displayText(option)),
                    )).toList(),
                    onChanged: onChanged != null ? (T? val) => onChanged!(val!) : null,
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
                    ),
                    dropdownColor: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.grey[800] 
                        : Colors.white,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white 
                          : Colors.black,
                    ),
                  )
                : Text(
                    displayText(value),
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