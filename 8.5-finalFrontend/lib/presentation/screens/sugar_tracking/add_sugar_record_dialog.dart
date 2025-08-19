import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_styles.dart';
import '../../theme/screen_adapter.dart';
import '../../theme/responsive_layout.dart';
import '../../widgets/adaptive_widgets.dart';
import '../../../services/api.dart';
import '../../../services/user_service.dart';

class AddSugarRecordDialog extends StatefulWidget {
  final DateTime? initialDate;
  
  const AddSugarRecordDialog({
    Key? key,
    this.initialDate,
  }) : super(key: key);

  @override
  _AddSugarRecordDialogState createState() => _AddSugarRecordDialogState();
}

class _AddSugarRecordDialogState extends State<AddSugarRecordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _foodNameController = TextEditingController();
  final _sugarAmountController = TextEditingController();
  final _quantityController = TextEditingController();
  
  DateTime _selectedDateTime = DateTime.now();
  bool _isLoading = false;
  String _selectedUnit = 'mg';
  final List<String> _units = ['mg', 'g'];

  @override
  void initState() {
    super.initState();
    _quantityController.text = '1';
    
    // 如果传入了初始日期，使用该日期的当前时间
    if (widget.initialDate != null) {
      final now = DateTime.now();
      _selectedDateTime = DateTime(
        widget.initialDate!.year,
        widget.initialDate!.month,
        widget.initialDate!.day,
        now.hour,
        now.minute,
      );
    }
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _sugarAmountController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // 检查是否是未来时间
    if (_selectedDateTime.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot add sugar record for future time.'),
          backgroundColor: AppColors.alert,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final foodName = _foodNameController.text.trim();
      final sugarAmountText = _sugarAmountController.text.trim();
      final quantityText = _quantityController.text.trim();

      // 解析数值
      final sugarAmount = double.parse(sugarAmountText);
      final quantity = double.parse(quantityText);

      // 转换为毫克
      final sugarAmountMg = _selectedUnit == 'g' ? sugarAmount * 1000 : sugarAmount;

      final userId = await UserService.instance.getCurrentUserId();
      if (userId == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
        return;
      }

      final success = await addSugarIntakeRecord(
        userId: userId,
        foodName: foodName,
        sugarAmount: sugarAmountMg,
        quantity: quantity,
        consumedAt: _selectedDateTime,
      );

      setState(() => _isLoading = false);

      if (success) {
        Navigator.pop(context, true); // 返回成功
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sugar record added successfully'),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add sugar record'),
            backgroundColor: AppColors.alert,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid input. Please check your values.'),
          backgroundColor: AppColors.alert,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Web端字体缩放修正 - 只针对Chrome浏览器
    final isWeb = kIsWeb;
    final adapter = ScreenAdapter.instance;
    final shouldReduceTextScale = isWeb; // 只要是Web平台就应用缩放
    
    Widget dialog = AdaptiveDialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title section
          Container(
            padding: EdgeInsets.all(20.r),
            child: Row(
              children: [
                AdaptiveIcon(
                  icon: Icons.add_circle, 
                  color: AppColors.primary,
                  size: 24,
                ),
                AdaptiveSpacing.horizontal(8),
                Expanded(
                  child: AdaptiveText(
                    text: 'Add Sugar Record', 
                    style: AppStyles.h2,
                  ),
                ),
              ],
            ),
          ),
          // Content section
          Flexible(
            child: AdaptiveSingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.r),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
              // 食品名称
              AdaptiveTextField(
                controller: _foodNameController,
                labelText: 'Food Name',
                hintText: 'e.g. Orange Juice, Chocolate Cookie',
                prefixIcon: Icons.fastfood,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter food name';
                  }
                  return null;
                },
              ),
              AdaptiveSpacing.vertical(16),

              // 糖分含量和单位
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: AdaptiveTextField(
                      controller: _sugarAmountController,
                      labelText: 'Sugar Amount',
                      hintText: '0.0',
                      prefixIcon: Icons.medical_services,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        final amount = double.tryParse(value.trim());
                        if (amount == null || amount < 0) {
                          return 'Invalid amount';
                        }
                        return null;
                      },
                    ),
                  ),
                  AdaptiveSpacing.horizontal(8),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      decoration: InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 16.h,
                        ),
                      ),
                      items: _units.map((unit) {
                        return DropdownMenuItem(
                          value: unit,
                          child: AdaptiveText(text: unit, style: AppStyles.bodyRegular),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedUnit = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              AdaptiveSpacing.vertical(16),

              // 数量
              AdaptiveTextField(
                controller: _quantityController,
                labelText: 'Quantity',
                hintText: '1',
                prefixIcon: Icons.format_list_numbered,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter quantity';
                  }
                  final quantity = double.tryParse(value.trim());
                  if (quantity == null || quantity <= 0) {
                    return 'Quantity must be greater than 0';
                  }
                  return null;
                },
              ),
              AdaptiveSpacing.vertical(16),

              // 时间选择器
              _buildDateTimeSelector(),
              AdaptiveSpacing.vertical(16),

              // 示例提示
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    AdaptiveIcon(
                      icon: Icons.info_outline, 
                      color: AppColors.primary, 
                      size: 16,
                    ),
                    AdaptiveSpacing.horizontal(8),
                    Expanded(
                      child: AdaptiveText(
                        text: 'Tip: Common sugar amounts - Apple: 100mg, Soda: 350mg, Cookie: 150mg',
                        style: TextStyle(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
                  ],
                ),
              ),
            ),
          ),
          // Actions section
          Container(
            padding: EdgeInsets.all(20.r),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AdaptiveButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context, false),
                  variant: ButtonVariant.text,
                  backgroundColor: AppColors.textLight,
                  child: AdaptiveText(text: 'Cancel'),
                ),
                AdaptiveSpacing.horizontal(12),
                AdaptiveButton(
                  onPressed: _isLoading ? null : _onSubmit,
                  variant: ButtonVariant.elevated,
                  backgroundColor: AppColors.primary,
                  child: _isLoading
                      ? AdaptiveLoadingIndicator(
                          size: 20,
                          strokeWidth: 2,
                          color: Colors.white,
                        )
                      : AdaptiveText(text: 'Add Record'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    
    // 如果是Web端桌面，应用文本缩放修正
    if (shouldReduceTextScale) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaleFactor: MediaQuery.of(context).textScaleFactor * 0.60,
        ),
        child: dialog,
      );
    }
    
    return dialog;
  }

  Widget _buildDateTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdaptiveText(
          text: 'Intake Time',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        AdaptiveSpacing.vertical(8),
        GestureDetector(
          onTap: _selectDateTime,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8.r),
              color: Colors.grey[50],
            ),
            child: Row(
              children: [
                AdaptiveIcon(
                  icon: Icons.access_time, 
                  color: Colors.grey[600], 
                  size: 20,
                ),
                AdaptiveSpacing.horizontal(12),
                Expanded(
                  child: AdaptiveText(
                    text: DateFormat('MMM d, yyyy HH:mm').format(_selectedDateTime),
                    style: TextStyle(
                      color: Colors.black87,
                    ),
                  ),
                ),
                AdaptiveIcon(
                  icon: Icons.edit, 
                  color: Colors.grey[500], 
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        AdaptiveSpacing.vertical(4),
        AdaptiveText(
          text: 'Tap to modify intake time (cannot be in the future)',
          style: TextStyle(
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Future<void> _selectDateTime() async {
    // 第一步: 选择日期
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(Duration(days: 365)), // 最多选择一年前
      lastDate: DateTime.now(), // 不能选择未来日期
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      // 第二步: 选择时间
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black87,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        final newDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        
        // 检查是否是未来时间
        if (newDateTime.isAfter(DateTime.now())) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot select future time. Please choose a time in the past.'),
              backgroundColor: AppColors.alert,
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }
        
        setState(() {
          _selectedDateTime = newDateTime;
        });
      }
    }
  }

}