import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';

/// 可复用的成分显示组件
class IngredientsDisplay extends StatelessWidget {
  final List<String>? ingredients;
  final String title;
  final int maxDisplayCount;
  final bool showExpandButton;
  final EdgeInsets padding;

  const IngredientsDisplay({
    Key? key,
    required this.ingredients,
    this.title = "Ingredients",
    this.maxDisplayCount = 10, // 双列显示：2列x5行=10个
    this.showExpandButton = true,
    this.padding = const EdgeInsets.all(16),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            children: [
              Icon(Icons.list, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                title,
                style: AppStyles.bodyBold.copyWith(
                  color: AppColors.primary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          // 成分内容
          _buildIngredientsContent(),
        ],
      ),
    );
  }

  Widget _buildIngredientsContent() {
    if (ingredients == null || ingredients!.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey[600], size: 16),
            SizedBox(width: 8),
            Text(
              'No ingredients information available',
              style: AppStyles.bodyRegular.copyWith(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    // 处理成分数据
    List<String> processedIngredients = _processIngredients(ingredients!);
    int displayCount = processedIngredients.length > maxDisplayCount ? maxDisplayCount : processedIngredients.length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 双列显示成分
        _buildIngredientGrid(processedIngredients.take(displayCount).toList()),
        
        // 只有当成分数量 > 10时才显示"Show all"按钮
        if (processedIngredients.length > 10 && showExpandButton) ...[
          SizedBox(height: 12),
          _buildExpandButton(processedIngredients),
        ],
      ],
    );
  }

  /// 构建双列网格显示
  Widget _buildIngredientGrid(List<String> ingredients) {
    return Column(
      children: [
        for (int i = 0; i < ingredients.length; i += 2) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左列
              Expanded(
                child: _buildIngredientItem(ingredients[i]),
              ),
              SizedBox(width: 12),
              // 右列
              Expanded(
                child: i + 1 < ingredients.length 
                    ? _buildIngredientItem(ingredients[i + 1])
                    : SizedBox(), // 如果是奇数个成分，右列为空
              ),
            ],
          ),
          if (i + 2 < ingredients.length) SizedBox(height: 6), // 行间距
        ],
      ],
    );
  }

  /// 构建单个成分项
  Widget _buildIngredientItem(String ingredient) {
    return Container(
            margin: EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(top: 8, right: 8),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    ingredient,
                    style: AppStyles.bodyRegular.copyWith(
                      color: AppColors.textDark,
                      height: 1.4,
                fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildExpandButton(List<String> allIngredients) {
    return Builder(
      builder: (context) => InkWell(
        onTap: () => _showAllIngredientsDialog(context, allIngredients),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.expand_more,
                color: AppColors.primary,
                size: 16,
              ),
              SizedBox(width: 4),
              Text(
                'Show all ${allIngredients.length} ingredients',
                style: AppStyles.bodyRegular.copyWith(
                  color: AppColors.primary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAllIngredientsDialog(BuildContext context, List<String> ingredients) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.list, color: AppColors.primary),
              SizedBox(width: 8),
              Text('All $title'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(maxHeight: 400),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: (ingredients.length / 2).ceil(), // 双列显示行数
              itemBuilder: (context, rowIndex) {
                final leftIndex = rowIndex * 2;
                final rightIndex = leftIndex + 1;
                
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 左列
                      Expanded(
                        child: _buildDialogIngredientItem(ingredients[leftIndex]),
                      ),
                      SizedBox(width: 12),
                      // 右列
                      Expanded(
                        child: rightIndex < ingredients.length 
                            ? _buildDialogIngredientItem(ingredients[rightIndex])
                            : SizedBox(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  /// 构建弹窗中的成分项（不截断文字）
  Widget _buildDialogIngredientItem(String ingredient) {
    return Container(
      margin: EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 8, right: 8),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              ingredient,
              style: AppStyles.bodyRegular.copyWith(
                color: AppColors.textDark,
                height: 1.4,
                fontSize: 14,
              ),
              softWrap: true, // 允许换行
              overflow: TextOverflow.visible, // 不截断
            ),
          ),
        ],
      ),
    );
  }

  /// 处理成分数据 - 简化显示格式化（避免重复解析）
  List<String> _processIngredients(List<String> rawIngredients) {
    List<String> processed = [];
    
    for (String ingredient in rawIngredients) {
      if (ingredient.trim().isEmpty) continue;
      
      String cleaned = ingredient.trim();
      
      // 移除可能的格式前缀
      if (cleaned.startsWith('MODIFIED CODE: ')) {
        cleaned = cleaned.substring(15).trim();
      }
      
      // 基本格式化和大小写统一
      cleaned = _formatIngredientCase(cleaned);
      cleaned = _displayFormat(cleaned);
      
      if (cleaned.isNotEmpty && cleaned.length > 1) {
            processed.add(cleaned);
          }
        }
    
    // 轻量去重（保持顺序）
    List<String> result = [];
    Set<String> seen = {};
    
    for (String item in processed) {
      String normalized = item.toLowerCase().trim();
      if (!seen.contains(normalized)) {
        seen.add(normalized);
        result.add(item);
      }
    }
    
    return result;
  }

  /// 格式化成分大小写 - 统一为首字母大写格式
  String _formatIngredientCase(String ingredient) {
    String formatted = ingredient.toLowerCase().trim();
    
    // 分割单词并首字母大写
    List<String> words = formatted.split(RegExp(r'[\s\-_]+'));
    List<String> capitalizedWords = [];
    
    for (String word in words) {
      if (word.isEmpty) continue;
      
      // 处理括号内容
      if (word.contains('(') || word.contains(')')) {
        String processedWord = '';
        List<String> parts = word.split('(');
        for (int i = 0; i < parts.length; i++) {
          if (i > 0) processedWord += '(';
          List<String> subParts = parts[i].split(')');
          for (int j = 0; j < subParts.length; j++) {
            if (j > 0) processedWord += ')';
            if (subParts[j].isNotEmpty) {
              processedWord += _capitalizeWord(subParts[j]);
            }
          }
        }
        capitalizedWords.add(processedWord);
      } else {
        capitalizedWords.add(_capitalizeWord(word));
      }
    }
    
    return capitalizedWords.join(' ');
  }

  /// 将单个单词首字母大写
  String _capitalizeWord(String word) {
    if (word.isEmpty) return word;
    
    // 处理常见缩写（保持原样）
    const abbreviations = ['ph', 'dha', 'epa', 'gmo', 'msg', 'bha', 'bht'];
    String lowerWord = word.toLowerCase();
    if (abbreviations.contains(lowerWord)) {
      return word.toUpperCase();
        }
    
    // 一般单词首字母大写
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }

  /// 显示格式化 - 仅负责UI显示优化
  String _displayFormat(String ingredient) {
    String formatted = ingredient.trim();
    
    // 移除多余的空格
    formatted = formatted.replaceAll(RegExp(r'\s+'), ' ');
    
    // 移除前后的标点
    formatted = formatted.replaceAll(RegExp(r'^[,;\s]+|[,;\s]+$'), '');
    
    // 适当增加显示长度限制，减少截断
    if (formatted.length > 50) {
      int spaceIndex = formatted.lastIndexOf(' ', 45);
      if (spaceIndex > 15) {
        formatted = formatted.substring(0, spaceIndex).trim() + '...';
      } else {
        formatted = formatted.substring(0, 45).trim() + '...';
      }
    }
    
    return formatted;
  }
}