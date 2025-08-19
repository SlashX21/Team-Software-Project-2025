import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../theme/screen_adapter.dart';
import '../theme/responsive_layout.dart';
import 'adaptive_widgets.dart';

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
              AdaptiveSpacing.horizontal(8),
              Text(
                title,
                style: AppStyles.bodyBold.copyWith(
                  color: AppColors.primary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          AdaptiveSpacing.vertical(12),
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
        
        // 显示"Show all"按钮的条件：1）数量>10 或 2）有文本被省略
        if (_shouldShowExpandButton(processedIngredients, displayCount) && showExpandButton) ...[
          AdaptiveSpacing.vertical(12),
          _buildExpandButton(processedIngredients),
        ],
      ],
    );
  }

  /// 判断是否应该显示"Show all"按钮
  bool _shouldShowExpandButton(List<String> processedIngredients, int displayCount) {
    // 条件1：成分数量超过显示限制
    if (processedIngredients.length > maxDisplayCount) {
      return true;
    }
    
    // 条件2：有文本被省略（检测显示的成分中是否有长文本）
    List<String> displayedIngredients = processedIngredients.take(displayCount).toList();
    for (String ingredient in displayedIngredients) {
      if (_isTextTruncated(ingredient)) {
        return true;
      }
    }
    
    return false;
  }

  /// 检测文本是否会被省略（简单估算）
  bool _isTextTruncated(String text) {
    // 简单的字符长度估算：超过约30个字符在单行中可能被省略
    // 这个数值可以根据实际字体大小和屏幕宽度调整
    return text.length > 30;
  }

  /// 构建双列布局显示 - 按顺序排列成两列
  Widget _buildIngredientGrid(List<String> ingredients) {
    List<Widget> rows = [];
    
    // 简单的双列布局：每行显示两个成分
    for (int i = 0; i < ingredients.length; i += 2) {
      String leftIngredient = ingredients[i];
      String? rightIngredient = (i + 1 < ingredients.length) ? ingredients[i + 1] : null;
      
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左列
          Expanded(child: _buildIngredientItem(leftIngredient)),
          SizedBox(width: 12),
          // 右列
          Expanded(
            child: rightIngredient != null 
                ? _buildIngredientItem(rightIngredient)
                : SizedBox(), // 空占位符
          ),
        ],
      ));
      
      // 添加行间距（除了最后一行）
      if (i + 2 < ingredients.length) {
        rows.add(SizedBox(height: 6));
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }

  /// 构建单个成分项 - 传统列表样式
  Widget _buildIngredientItem(String ingredient) {
    return Container(
            margin: EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(top: 6, right: 8),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: AdaptiveText(
                    text: ingredient,
                    style: AppStyles.bodyRegular.copyWith(
                      color: AppColors.textDark,
                      height: 1.3,
                      fontSize: 14,
                    ),
                    maxLines: 1, // 固定单行显示
                    overflow: TextOverflow.ellipsis, // 超出显示省略号
                    useResponsiveFontSize: false,
                    useDeviceOptimization: false,
                  ),
                ),
              ],
            ),
    );
  }

  /// 构建全宽ingredient项（用于独占一行的长文本）
  Widget _buildFullWidthIngredientItem(String ingredient) {
    return Container(
      margin: EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 6, right: 8),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: AdaptiveText(
              text: ingredient,
              style: AppStyles.bodyRegular.copyWith(
                color: AppColors.textDark,
                height: 1.3,
                fontSize: 14,
              ),
              maxLines: 3, // 长文本允许更多行数
              overflow: TextOverflow.ellipsis,
              useResponsiveFontSize: false,
              useDeviceOptimization: false,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建成分标签 - 新的流式布局样式
  Widget _buildIngredientChip(String ingredient) {
    return Container(
      margin: EdgeInsets.only(bottom: 4),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Text(
        ingredient,
        style: AppStyles.bodyRegular.copyWith(
          color: AppColors.textDark,
          fontSize: 13,
          height: 1.2,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
              AdaptiveSpacing.horizontal(8),
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
      
      // 检查是否是一个长的成分描述，需要分割
      if (cleaned.length > 100 && (cleaned.contains(',') || cleaned.contains('.'))) {
        // 分割长的成分描述
        List<String> splitIngredients = _splitLongIngredientText(cleaned);
        for (String splitIngredient in splitIngredients) {
          String formattedIngredient = _formatIngredientCase(splitIngredient);
          formattedIngredient = _displayFormat(formattedIngredient);
          if (formattedIngredient.isNotEmpty && formattedIngredient.length > 1) {
            processed.add(formattedIngredient);
          }
        }
      } else {
        // 正常处理单个成分
        cleaned = _formatIngredientCase(cleaned);
        cleaned = _displayFormat(cleaned);
        
        if (cleaned.isNotEmpty && cleaned.length > 1) {
          processed.add(cleaned);
        }
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

  /// 分割长的成分描述文本，智能处理不同格式
  List<String> _splitLongIngredientText(String longText) {
    List<String> ingredients = [];
    
    // 检查是否是"产品名 (成分列表)"的格式
    if (_isProductNameWithIngredientsList(longText)) {
      ingredients = _extractIngredientsFromProductDescription(longText);
    } else {
      // 普通的长成分文本，使用智能分割
      ingredients = _smartSplitByComma(longText);
      
      // 如果按逗号分割效果不好，尝试其他分隔符
      if (ingredients.length <= 1) {
        ingredients = _smartSplitByDelimiter(longText, ';');
      }
      
      // 最后尝试句号分割
      if (ingredients.length <= 1) {
        ingredients = _smartSplitByDelimiter(longText, '.');
      }
    }
    
    // 如果还是只有一个很长的成分，保持原样
    if (ingredients.isEmpty) {
      ingredients.add(longText);
    }
    
    return ingredients;
  }

  /// 检查是否是"产品名 (成分列表)"的格式
  bool _isProductNameWithIngredientsList(String text) {
    // 查找第一个左括号的位置
    int firstParenIndex = text.indexOf('(');
    if (firstParenIndex == -1) return false;
    
    // 检查括号前的部分是否看起来像产品名
    String beforeParen = text.substring(0, firstParenIndex).trim();
    
    // 如果括号前的文本较短且没有逗号，可能是产品名
    if (beforeParen.length < 50 && !beforeParen.contains(',')) {
      // 检查括号内是否包含多个成分（有逗号）
      int lastParenIndex = text.lastIndexOf(')');
      if (lastParenIndex > firstParenIndex) {
        String insideParens = text.substring(firstParenIndex + 1, lastParenIndex);
        return insideParens.contains(',') && insideParens.length > 50;
      }
    }
    
    return false;
  }

  /// 从"产品名 (成分列表)"格式中提取成分
  List<String> _extractIngredientsFromProductDescription(String text) {
    List<String> ingredients = [];
    
    // 找到主要的括号内容
    int firstParenIndex = text.indexOf('(');
    int lastParenIndex = text.lastIndexOf(')');
    
    if (firstParenIndex != -1 && lastParenIndex > firstParenIndex) {
      // 提取括号内的成分列表
      String ingredientsList = text.substring(firstParenIndex + 1, lastParenIndex);
      
      // 对成分列表进行智能分割
      ingredients = _smartSplitByComma(ingredientsList);
      
      // 处理括号后的额外信息
      String afterParens = text.substring(lastParenIndex + 1).trim();
      if (afterParens.isNotEmpty && afterParens.length > 5) {
        // 清理开头的标点符号
        afterParens = afterParens.replaceAll(RegExp(r'^[,.\s]+'), '');
        if (afterParens.isNotEmpty) {
          ingredients.add(afterParens);
        }
      }
    }
    
    return ingredients;
  }

  /// 智能按逗号分割，保护括号内容
  List<String> _smartSplitByComma(String text) {
    List<String> result = [];
    int parenthesesLevel = 0;
    int lastSplitIndex = 0;
    
    for (int i = 0; i < text.length; i++) {
      String currentChar = text[i];
      
      if (currentChar == '(') {
        parenthesesLevel++;
      } else if (currentChar == ')') {
        parenthesesLevel--;
      } else if (currentChar == ',' && parenthesesLevel == 0) {
        // 只在括号外的逗号处分割
        String part = text.substring(lastSplitIndex, i).trim();
        if (part.isNotEmpty && part.length > 3) {
          result.add(part);
        }
        lastSplitIndex = i + 1;
      }
    }
    
    // 添加最后一部分
    String lastPart = text.substring(lastSplitIndex).trim();
    if (lastPart.isNotEmpty && lastPart.length > 3) {
      result.add(lastPart);
    }
    
    return result;
  }

  /// 智能按指定分隔符分割，保护括号内容
  List<String> _smartSplitByDelimiter(String text, String delimiter) {
    List<String> result = [];
    int parenthesesLevel = 0;
    int lastSplitIndex = 0;
    
    for (int i = 0; i < text.length; i++) {
      String currentChar = text[i];
      
      if (currentChar == '(') {
        parenthesesLevel++;
      } else if (currentChar == ')') {
        parenthesesLevel--;
      } else if (currentChar == delimiter && parenthesesLevel == 0) {
        // 只在括号外的分隔符处分割
        String part = text.substring(lastSplitIndex, i).trim();
        if (part.isNotEmpty && part.length > 3) {
          result.add(part);
        }
        lastSplitIndex = i + 1;
      }
    }
    
    // 添加最后一部分
    String lastPart = text.substring(lastSplitIndex).trim();
    if (lastPart.isNotEmpty && lastPart.length > 3) {
      result.add(lastPart);
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
    
    // 不再在文本处理层面截断，让UI组件处理换行
    // 这样可以保证完整的ingredients信息被显示
    
    return formatted;
  }
}