class ProductAnalysis {
  final String name;
  final String imageUrl;
  final List<String> ingredients;
  final List<String> detectedAllergens;
  final String summary;
  final String detailedAnalysis;
  final List<String> actionSuggestions;
  final Map<String, dynamic>? llmAnalysis;
  final List<ProductAnalysis> recommendations;
  final String? barcode; // 新增：条码字段
  final String? detailedSummary; // 新增：详细推荐理由（用于详情页面）

  ProductAnalysis({
    required this.name,
    required this.imageUrl,
    required this.ingredients,
    required this.detectedAllergens,
    this.summary = '',
    this.detailedAnalysis = '',
    this.actionSuggestions = const [],
    this.llmAnalysis,
    this.recommendations = const [],
    this.barcode, // 新增：条码参数
    this.detailedSummary, // 新增：详细推荐理由参数
  });

  factory ProductAnalysis.fromJson(Map<String, dynamic> json) {
    // 处理 ingredients，可能是字符串数组或逗号分隔的字符串
    List<String> parseIngredients(dynamic ingredientsData) {
      if (ingredientsData == null) return [];
      if (ingredientsData is List) {
        return List<String>.from(ingredientsData);
      }
      if (ingredientsData is String) {
        return ProductAnalysis._cleanAndParseIngredients(ingredientsData);
      }
      return [];
    }

    // 处理 allergens，可能是字符串数组或逗号分隔的字符串
    List<String> parseAllergens(dynamic allergensData) {
      if (allergensData == null) return [];
      if (allergensData is List) {
        return List<String>.from(allergensData);
      }
      if (allergensData is String) {
        return allergensData
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return [];
    }

    return ProductAnalysis(
      name: json['name'] ?? json['productName'] ?? '',
      imageUrl: json['imageUrl'] ?? json['image'] ?? '',
      ingredients: parseIngredients(json['ingredients']),
      detectedAllergens: parseAllergens(json['detectedAllergens'] ?? json['allergens']),
      summary: json['summary'] ?? json['reasoning'] ?? '', // 简短推荐理由
      detailedAnalysis: json['detailedAnalysis'] ?? json['analysis'] ?? '',
      actionSuggestions: List<String>.from(json['actionSuggestions'] ?? json['suggestions'] ?? []),
      llmAnalysis: json['llmAnalysis'] as Map<String, dynamic>?,
      recommendations: (json['recommendations'] as List?)
          ?.map((i) => ProductAnalysis.fromJson(i as Map<String, dynamic>))
          .toList() ??
          [],
      barcode: json['barcode'] ?? json['barCode'], // 支持两种可能的字段名
      detailedSummary: json['detailedSummary'] ?? json['detailed_reasoning'], // 详细推荐理由
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'ingredients': ingredients,
      'detectedAllergens': detectedAllergens,
      'summary': summary,
      'detailedAnalysis': detailedAnalysis,
      'actionSuggestions': actionSuggestions,
      'barcode': barcode,
      'detailedSummary': detailedSummary,
    };
  }

  ProductAnalysis copyWith({
    String? name,
    String? imageUrl,
    List<String>? ingredients,
    List<String>? detectedAllergens,
    String? summary,
    String? detailedAnalysis,
    List<String>? actionSuggestions,
    Map<String, dynamic>? llmAnalysis,
    List<ProductAnalysis>? recommendations,
    String? barcode,
    String? detailedSummary,
  }) {
    return ProductAnalysis(
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      ingredients: ingredients ?? this.ingredients,
      detectedAllergens: detectedAllergens ?? this.detectedAllergens,
      summary: summary ?? this.summary,
      detailedAnalysis: detailedAnalysis ?? this.detailedAnalysis,
      actionSuggestions: actionSuggestions ?? this.actionSuggestions,
      llmAnalysis: llmAnalysis ?? this.llmAnalysis,
      recommendations: recommendations ?? this.recommendations,
      barcode: barcode ?? this.barcode,
      detailedSummary: detailedSummary ?? this.detailedSummary,
  );
  }

  // 智能解析和清理成分列表
  static List<String> _cleanAndParseIngredients(String ingredientsText) {
    if (ingredientsText.isEmpty) return [];
    
    // Step 1: 预处理 - 清理原始文本
    String cleaned = ingredientsText.trim();
    
    // 处理重复的空格
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    
    // 移除营养成分百分比信息 (如 "0% 2% 4% 2%")
    cleaned = cleaned.replaceAll(RegExp(r'\s*\d+%\s*'), ' ');
    
    // 分离特殊声明信息（CONTAINS 和 MAY CONTAIN）
    List<String> specialDeclarations = [];
    
    // 处理 CONTAINS 声明
    if (cleaned.toUpperCase().contains('CONTAINS')) {
      var match = RegExp(r'CONTAINS\s+([^.]+)', caseSensitive: false).firstMatch(cleaned);
      if (match != null) {
        String containsInfo = match.group(1)?.trim() ?? '';
        if (containsInfo.isNotEmpty) {
          specialDeclarations.add('Contains: ${_formatAllergenList(containsInfo)}');
        }
        cleaned = cleaned.replaceAll(match.group(0)!, '');
      }
    }
    
    // 处理 MAY CONTAIN 声明
    if (cleaned.toUpperCase().contains('MAY CONTAIN')) {
      var match = RegExp(r'MAY\s+CONTAIN\s+([^.]+)', caseSensitive: false).firstMatch(cleaned);
      if (match != null) {
        String mayContainInfo = match.group(1)?.trim() ?? '';
        if (mayContainInfo.isNotEmpty) {
          specialDeclarations.add('May contain: ${_formatAllergenList(mayContainInfo)}');
        }
        cleaned = cleaned.replaceAll(match.group(0)!, '');
      }
    }
    
    // 移除末尾的句号
    cleaned = cleaned.replaceAll(RegExp(r'\.\s*$'), '');
    
    // Step 2: 智能分割主要成分（保护括号内容）
    List<String> mainIngredients = _intelligentSplit(cleaned);
    
    // Step 3: 清理和格式化每个成分
    List<String> processedIngredients = [];
    
    for (String ingredient in mainIngredients) {
      String processed = _formatSingleIngredient(ingredient);
      if (processed.isNotEmpty && processed.length > 1) {
        processedIngredients.add(processed);
      }
    }
    
    // Step 4: 添加特殊声明
    processedIngredients.addAll(specialDeclarations);
    
    // Step 5: 去重并限制数量（避免过长的列表）
    List<String> finalList = processedIngredients.toSet().toList();
    
    // 限制主要成分数量，保持重要信息
    if (finalList.length > 25) {
      List<String> important = finalList.take(20).toList();
      important.addAll(specialDeclarations);
      finalList = important;
    }
    
    return finalList;
  }

  // 智能分割成分，正确处理嵌套结构
  static List<String> _intelligentSplit(String text) {
    List<String> ingredients = [];
    StringBuffer current = StringBuffer();
    int parenDepth = 0;
    int bracketDepth = 0;
    bool inQuotes = false;
    
    for (int i = 0; i < text.length; i++) {
      String char = text[i];
      String nextChar = i + 1 < text.length ? text[i + 1] : '';
      
      switch (char) {
        case '(':
        parenDepth++;
        current.write(char);
          break;
        case ')':
        parenDepth--;
        current.write(char);
          break;
        case '[':
        bracketDepth++;
        current.write(char);
          break;
        case ']':
        bracketDepth--;
        current.write(char);
          break;
        case '"':
        case "'":
          inQuotes = !inQuotes;
          current.write(char);
          break;
        case ',':
          // 只有在最外层（没有嵌套）时才分割
          if (parenDepth == 0 && bracketDepth == 0 && !inQuotes) {
        String ingredient = current.toString().trim();
            if (ingredient.isNotEmpty && ingredient.length > 1) {
          ingredients.add(ingredient);
        }
        current.clear();
      } else {
            current.write(char);
          }
          break;
        default:
        current.write(char);
      }
    }
    
    // 添加最后一个成分
    String lastIngredient = current.toString().trim();
    if (lastIngredient.isNotEmpty && lastIngredient.length > 1) {
      ingredients.add(lastIngredient);
    }
    
    return ingredients;
  }

  // 格式化单个成分
  static String _formatSingleIngredient(String ingredient) {
    String formatted = ingredient.trim();
    
    // 移除前后多余的标点和空格
    formatted = formatted.replaceAll(RegExp(r'^[,\s\.\;]+|[,\s\.\;]+$'), '');
    
    // 修复不匹配的括号
    formatted = _balanceParentheses(formatted);
    
    // 清理内部多余空格
    formatted = formatted.replaceAll(RegExp(r'\s+'), ' ');
    
    // 转换为适当的大小写格式
    formatted = _toProperCase(formatted);
    
    // 优化长度处理 - 更智能的截断
    if (formatted.length > 75) {
      // 优先在括号或逗号处截断
      List<int> breakPoints = [];
      for (int i = 0; i < formatted.length && i < 70; i++) {
        if (formatted[i] == ')' || formatted[i] == ']' || formatted[i] == ',') {
          breakPoints.add(i + 1);
        }
      }
      
      if (breakPoints.isNotEmpty) {
        int breakPoint = breakPoints.last;
        formatted = formatted.substring(0, breakPoint).trim() + '...';
      } else {
        // 寻找最后一个空格截断
        int lastSpace = formatted.lastIndexOf(' ', 65);
        if (lastSpace > 25) {
          formatted = formatted.substring(0, lastSpace).trim() + '...';
        } else {
          formatted = formatted.substring(0, 65).trim() + '...';
        }
      }
    }
    
    return formatted;
  }

  // 平衡括号
  static String _balanceParentheses(String text) {
    // 统计括号
    int openParen = text.split('(').length - 1;
    int closeParen = text.split(')').length - 1;
    int openBracket = text.split('[').length - 1;
    int closeBracket = text.split(']').length - 1;
    
    String result = text;
    
    // 补充缺失的闭合括号
    if (openParen > closeParen) {
      result += ')' * (openParen - closeParen);
    }
    if (openBracket > closeBracket) {
      result += ']' * (openBracket - closeBracket);
    }
    
    return result;
    }
    
  // 转换为适当的大小写格式
  static String _toProperCase(String text) {
    if (text.isEmpty) return text;
    
    // 如果全是大写，转换为标题格式
    if (text == text.toUpperCase() && text.contains(' ')) {
      return _toTitleCase(text);
    }
    
    // 如果已经是混合大小写，保持原样
    if (text != text.toUpperCase() && text != text.toLowerCase()) {
      return text;
    }
    
    // 处理全小写的情况
    if (text == text.toLowerCase()) {
      return _toTitleCase(text);
    }
    
    return text;
  }

  // 格式化过敏原列表
  static String _formatAllergenList(String allergenText) {
    List<String> allergens = allergenText
        .split(RegExp(r'[,\s]+'))
        .where((s) => s.trim().isNotEmpty)
        .map((s) => _toTitleCase(s.trim()))
        .toList();
    
    if (allergens.length <= 3) {
      return allergens.join(', ');
    } else {
      return '${allergens.take(3).join(', ')} and others';
    }
  }

  // 转换为标题格式
  static String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    
    // 常见的应该保持小写的词
    final Set<String> lowerCaseWords = {
      'of', 'the', 'and', 'or', 'in', 'on', 'at', 'to', 'for', 'with', 'by', 'from', 'an', 'a'
    };
    
    List<String> words = text.toLowerCase().split(' ');
    for (int i = 0; i < words.length; i++) {
      String word = words[i].trim();
      if (word.isEmpty) continue;
      
      // 第一个词或不在小写词列表中的词要首字母大写
      if (i == 0 || !lowerCaseWords.contains(word)) {
        words[i] = word[0].toUpperCase() + (word.length > 1 ? word.substring(1) : '');
      }
    }
    
    return words.join(' ');
  }
}