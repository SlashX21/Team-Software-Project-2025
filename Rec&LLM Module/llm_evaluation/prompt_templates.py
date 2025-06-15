"""
Prompt模板管理
针对条形码扫描和小票分析的专业化prompt设计
"""

import logging
from typing import Dict, List, Optional, Any
from datetime import datetime
from dataclasses import dataclass

from config.constants import NutritionGoal, LLM_CONSTANTS

logger = logging.getLogger(__name__)

@dataclass
class PromptContext:
    """Prompt上下文数据"""
    user_profile: Dict[str, Any]
    original_product: Optional[Dict[str, Any]] = None
    recommended_products: Optional[List[Dict[str, Any]]] = None
    purchased_items: Optional[List[Dict[str, Any]]] = None
    nutrition_comparison: Optional[Dict[str, Any]] = None
    request_type: str = "unknown"

class PromptTemplateManager:
    """Prompt模板管理器"""
    
    def __init__(self):
        self.templates = self._load_templates()
        self.safety_disclaimer = "注意：以上建议仅供参考，不能替代专业医疗建议。如有健康问题，请咨询医生。"
        
    def _load_templates(self) -> Dict[str, str]:
        """加载所有prompt模板"""
        return {
            "barcode_scan": self._get_barcode_scan_template(),
            "receipt_analysis": self._get_receipt_analysis_template(),
            "nutrition_comparison": self._get_nutrition_comparison_template(),
            "allergen_warning": self._get_allergen_warning_template(),
            "health_assessment": self._get_health_assessment_template()
        }
    
    def generate_barcode_scan_prompt(self, context: PromptContext) -> str:
        """生成条形码扫描推荐分析prompt"""
        template = self.templates["barcode_scan"]
        
        # 准备模板变量
        user_profile = context.user_profile
        original_product = context.original_product or {}
        recommended_products = context.recommended_products or []
        nutrition_comparison = context.nutrition_comparison or {}
        
        # 用户画像信息
        age = user_profile.get("age", "未知")
        gender = self._translate_gender(user_profile.get("gender", ""))
        height_cm = user_profile.get("height_cm", "未知")
        weight_kg = user_profile.get("weight_kg", "未知")
        nutrition_goal_cn = self._translate_nutrition_goal(user_profile.get("nutrition_goal", "maintain"))
        activity_level_cn = self._translate_activity_level(user_profile.get("activity_level", "moderate"))
        
        # 过敏原信息
        allergens_list = self._format_allergens_list(user_profile.get("allergens", []))
        
        # 营养目标信息
        daily_calories = user_profile.get("daily_calories_target", "未设置")
        daily_protein = user_profile.get("daily_protein_target", "未设置")
        daily_nutrition_targets = f"热量{daily_calories}kcal，蛋白质{daily_protein}g"
        
        # 原商品信息
        original_product_name = original_product.get("name", "未知商品")
        original_product_brand = original_product.get("brand", "未知品牌")
        original_calories = original_product.get("energy_kcal_100g", "未知")
        original_protein = original_product.get("proteins_100g", "未知")
        original_fat = original_product.get("fat_100g", "未知")
        original_carbs = original_product.get("carbohydrates_100g", "未知")
        original_sugar = original_product.get("sugars_100g", "未知")
        
        # 推荐商品详情
        recommended_products_details = self._format_recommended_products(recommended_products)
        
        # 营养对比分析
        nutrition_comparison_text = self._format_nutrition_comparison(nutrition_comparison)
        
        # 填充模板
        prompt = template.format(
            age=age,
            gender=gender,
            height_cm=height_cm,
            weight_kg=weight_kg,
            nutrition_goal_cn=nutrition_goal_cn,
            activity_level_cn=activity_level_cn,
            allergens_list=allergens_list,
            daily_nutrition_targets=daily_nutrition_targets,
            original_product_name=original_product_name,
            original_product_brand=original_product_brand,
            original_calories=original_calories,
            original_protein=original_protein,
            original_fat=original_fat,
            original_carbs=original_carbs,
            original_sugar=original_sugar,
            recommended_products_details=recommended_products_details,
            nutrition_comparison=nutrition_comparison_text
        )
        
        return self._add_safety_considerations(prompt)
    
    def generate_receipt_analysis_prompt(self, context: PromptContext) -> str:
        """生成小票分析prompt"""
        template = self.templates["receipt_analysis"]
        
        user_profile = context.user_profile
        purchased_items = context.purchased_items or []
        
        # 用户画像信息
        age = user_profile.get("age", "未知")
        gender = self._translate_gender(user_profile.get("gender", ""))
        height_cm = user_profile.get("height_cm", "未知")
        weight_kg = user_profile.get("weight_kg", "未知")
        nutrition_goal_cn = self._translate_nutrition_goal(user_profile.get("nutrition_goal", "maintain"))
        allergens_list = self._format_allergens_list(user_profile.get("allergens", []))
        
        # 营养目标
        daily_nutrition_targets = self._format_daily_targets(user_profile)
        
        # 购买清单分析
        purchased_items_analysis = self._format_purchased_items_analysis(purchased_items)
        
        # 整体营养分析
        overall_nutrition = self._calculate_overall_nutrition_from_items(purchased_items)
        
        # 单品改进建议
        item_replacement_suggestions = self._format_item_replacements(purchased_items)
        
        # 填充模板
        prompt = template.format(
            age=age,
            gender=gender,
            height_cm=height_cm,
            weight_kg=weight_kg,
            nutrition_goal_cn=nutrition_goal_cn,
            allergens_list=allergens_list,
            daily_nutrition_targets=daily_nutrition_targets,
            purchased_items_analysis=purchased_items_analysis,
            total_estimated_calories=overall_nutrition.get("total_calories", "未知"),
            total_protein=overall_nutrition.get("total_protein", "未知"),
            total_fat=overall_nutrition.get("total_fat", "未知"),
            total_carbs=overall_nutrition.get("total_carbs", "未知"),
            goal_match_percentage=overall_nutrition.get("goal_match_percentage", "未知"),
            item_replacement_suggestions=item_replacement_suggestions
        )
        
        return self._add_safety_considerations(prompt)
    
    def _get_barcode_scan_template(self) -> str:
        """条形码扫描Prompt模板"""
        return """你是一位专业的营养师和食品安全专家，拥有丰富的食品营养学知识和实践经验。用户扫描了一个商品条形码，请为其提供专业、个性化的替代品推荐分析。

用户画像：
- 基本信息：{age}岁{gender}，身高{height_cm}cm，体重{weight_kg}kg
- 营养目标：{nutrition_goal_cn}
- 活动水平：{activity_level_cn}
- 已知过敏原：{allergens_list}
- 每日营养目标：{daily_nutrition_targets}

扫描的原商品：
- 商品名称：{original_product_name}
- 品牌：{original_product_brand}
- 营养成分（每100g）：
  * 热量：{original_calories}kcal
  * 蛋白质：{original_protein}g
  * 脂肪：{original_fat}g
  * 碳水化合物：{original_carbs}g
  * 糖分：{original_sugar}g

推荐的替代品：
{recommended_products_details}

营养对比分析：
{nutrition_comparison}

请提供一份详细的个性化分析，包括：

1. **推荐理由**（结合用户的营养目标和健康状况）
   - 为什么推荐这些替代品？
   - 这些替代品如何更好地匹配用户的营养目标？

2. **营养优势分析**（提供具体的量化对比）
   - 热量、蛋白质、脂肪、糖分等关键指标的改善
   - 用具体数字说明营养改善程度

3. **健康影响评估**
   - 对用户实现营养目标的潜在帮助
   - 长期健康效益分析

4. **使用建议**
   - 具体的食用建议和注意事项
   - 如何融入日常饮食计划

要求：
- 语言专业但易懂，避免过于技术性的术语
- 提供具体的数字对比，突出改善程度
- 给出实用的行动建议
- 保持客观科学的态度
- 字数控制在400-600字"""

    def _get_receipt_analysis_template(self) -> str:
        """小票分析Prompt模板"""
        return """你是一位资深的营养咨询师和健康生活指导专家。用户上传了一张购物小票，请对其购买习惯进行全面分析并提供专业的改进建议。

用户画像：
- 基本信息：{age}岁{gender}，{height_cm}cm，{weight_kg}kg
- 营养目标：{nutrition_goal_cn}
- 已知过敏原：{allergens_list}
- 每日营养目标：{daily_nutrition_targets}

本次购买清单：
{purchased_items_analysis}

整体营养分析：
- 估算总热量：{total_estimated_calories}kcal
- 总蛋白质：{total_protein}g
- 总脂肪：{total_fat}g
- 总碳水化合物：{total_carbs}g
- 营养目标匹配度：{goal_match_percentage}%

单品改进建议：
{item_replacement_suggestions}

请提供一份综合的购买习惯分析和改进建议，包括：

1. **整体购买模式评估**
   - 购买选择是否符合营养目标？
   - 商品种类的多样性和平衡性如何？

2. **营养结构分析**
   - 蛋白质、碳水化合物、脂肪的比例是否合理？
   - 是否存在营养过剩或不足的问题？

3. **具体改进建议**
   - 哪些商品建议替换？为什么？
   - 推荐具体的替代商品和品牌

4. **长期饮食规划**
   - 如何调整购买习惯以更好地支持营养目标？
   - 季节性饮食调整建议

5. **下次购物重点**
   - 优先购买的商品类型
   - 需要避免或减少的商品

要求：
- 分析客观具体，建议实用可行
- 突出与用户营养目标的相关性
- 提供具体的改进方向和量化指标
- 语言友好鼓励，避免批评性语言
- 字数控制在500-700字"""

    def _get_nutrition_comparison_template(self) -> str:
        """营养对比分析模板"""
        return """请对以下商品进行详细的营养对比分析：

原商品：{original_product}
替代商品：{alternative_product}
用户目标：{nutrition_goal}

请从以下角度进行对比：
1. 热量对比及其对用户目标的影响
2. 三大营养素（蛋白质、碳水、脂肪）的变化
3. 微量营养素和有益成分的差异
4. 整体健康价值评估

要求：提供具体数据支持，评估要客观准确。"""

    def _get_allergen_warning_template(self) -> str:
        """过敏原警告模板"""
        return """⚠️ 过敏原安全警告 ⚠️

检测到该商品可能包含以下过敏原：
{detected_allergens}

您的已知过敏原：{user_allergens}

安全建议：
{safety_recommendations}

请在购买前仔细检查商品标签，如有疑问请咨询医生。"""

    def _get_health_assessment_template(self) -> str:
        """健康评估模板"""
        return """基于您的健康档案进行个性化评估：

用户信息：
- 年龄：{age}岁
- BMI：{bmi}
- 营养目标：{nutrition_goal}
- 活动水平：{activity_level}

商品健康评估：
{health_assessment}

个性化建议：
{personalized_recommendations}"""

    def _translate_gender(self, gender: str) -> str:
        """翻译性别"""
        gender_map = {
            "male": "男性",
            "female": "女性",
            "other": "其他"
        }
        return gender_map.get(gender, "")

    def _translate_nutrition_goal(self, goal: str) -> str:
        """翻译营养目标"""
        goal_map = {
            "lose_weight": "减脂塑形",
            "gain_muscle": "增肌健体",
            "maintain": "维持健康",
            "general_health": "一般健康"
        }
        return goal_map.get(goal, "维持健康")

    def _translate_activity_level(self, level: str) -> str:
        """翻译活动水平"""
        level_map = {
            "sedentary": "久坐少动",
            "light": "轻度活动",
            "moderate": "中度活动",
            "active": "积极活动",
            "very_active": "高强度活动"
        }
        return level_map.get(level, "中度活动")

    def _format_allergens_list(self, allergens: List[Dict]) -> str:
        """格式化过敏原列表"""
        if not allergens:
            return "无已知过敏原"
        
        allergen_names = []
        for allergen in allergens:
            name = allergen.get("name", "")
            severity = allergen.get("severity_level", "")
            if name:
                if severity:
                    allergen_names.append(f"{name}({severity})")
                else:
                    allergen_names.append(name)
        
        return "、".join(allergen_names) if allergen_names else "无已知过敏原"

    def _format_daily_targets(self, user_profile: Dict) -> str:
        """格式化每日营养目标"""
        targets = []
        
        calories = user_profile.get("daily_calories_target")
        if calories:
            targets.append(f"热量{calories}kcal")
        
        protein = user_profile.get("daily_protein_target")
        if protein:
            targets.append(f"蛋白质{protein}g")
        
        carbs = user_profile.get("daily_carb_target")
        if carbs:
            targets.append(f"碳水化合物{carbs}g")
        
        fat = user_profile.get("daily_fat_target")
        if fat:
            targets.append(f"脂肪{fat}g")
        
        return "，".join(targets) if targets else "未设置具体目标"

    def _format_recommended_products(self, products: List[Dict]) -> str:
        """格式化推荐商品详情"""
        if not products:
            return "暂无推荐商品"
        
        formatted_products = []
        for i, product in enumerate(products[:5], 1):  # 最多显示5个推荐
            name = product.get("name", "未知商品")
            brand = product.get("brand", "未知品牌")
            calories = product.get("energy_kcal_100g", "未知")
            protein = product.get("proteins_100g", "未知")
            fat = product.get("fat_100g", "未知")
            sugar = product.get("sugars_100g", "未知")
            
            product_info = f"""
推荐商品{i}：{name}（{brand}）
- 热量：{calories}kcal/100g
- 蛋白质：{protein}g/100g  
- 脂肪：{fat}g/100g
- 糖分：{sugar}g/100g"""
            
            formatted_products.append(product_info)
        
        return "\n".join(formatted_products)

    def _format_nutrition_comparison(self, comparison: Dict) -> str:
        """格式化营养对比信息"""
        if not comparison:
            return "暂无详细营养对比数据"
        
        nutrition_comparison = comparison.get("nutrition_comparison", {})
        if not nutrition_comparison:
            return "暂无营养成分对比"
        
        comparisons = []
        for field, data in nutrition_comparison.items():
            if isinstance(data, dict):
                name = data.get("name", field)
                original = data.get("original_value", 0)
                alternative = data.get("alternative_value", 0)
                change = data.get("absolute_change", 0)
                percent_change = data.get("percent_change", 0)
                
                direction_symbol = "↑" if change > 0 else "↓" if change < 0 else "→"
                
                comparison_text = f"- {name}：{original} → {alternative} ({direction_symbol}{percent_change:+.1f}%)"
                comparisons.append(comparison_text)
        
        return "\n".join(comparisons) if comparisons else "营养成分基本相似"

    def _format_purchased_items_analysis(self, items: List[Dict]) -> str:
        """格式化购买商品分析"""
        if not items:
            return "购买清单为空"
        
        formatted_items = []
        for item in items:
            name = item.get("name", item.get("item_name_ocr", "未知商品"))
            quantity = item.get("quantity", 1)
            calories = item.get("energy_kcal_100g", "未知")
            protein = item.get("proteins_100g", "未知")
            category = item.get("category", "未分类")
            
            item_info = f"- {name} × {quantity} ({category}) - {calories}kcal/100g，蛋白质{protein}g/100g"
            formatted_items.append(item_info)
        
        return "\n".join(formatted_items)

    def _calculate_overall_nutrition_from_items(self, items: List[Dict]) -> Dict:
        """从购买商品计算整体营养"""
        total_calories = 0
        total_protein = 0
        total_fat = 0
        total_carbs = 0
        
        for item in items:
            quantity = item.get("quantity", 1)
            
            # 假设每个商品约100g
            calories = item.get("energy_kcal_100g", 0) * quantity
            protein = item.get("proteins_100g", 0) * quantity
            fat = item.get("fat_100g", 0) * quantity
            carbs = item.get("carbohydrates_100g", 0) * quantity
            
            total_calories += calories
            total_protein += protein
            total_fat += fat
            total_carbs += carbs
        
        # 简单的目标匹配度计算（示例）
        goal_match_percentage = min(100, (total_protein / 150) * 100) if total_protein > 0 else 0
        
        return {
            "total_calories": round(total_calories, 1),
            "total_protein": round(total_protein, 1),
            "total_fat": round(total_fat, 1),
            "total_carbs": round(total_carbs, 1),
            "goal_match_percentage": round(goal_match_percentage, 1)
        }

    def _format_item_replacements(self, items: List[Dict]) -> str:
        """格式化单品替换建议"""
        if not items:
            return "无替换建议"
        
        suggestions = []
        for item in items:
            name = item.get("name", item.get("item_name_ocr", "未知商品"))
            category = item.get("category", "")
            
            # 基于分类提供通用建议
            if "beverages" in category.lower() or "饮料" in name:
                suggestions.append(f"- {name} → 建议选择无糖或低糖饮料")
            elif "snacks" in category.lower() or any(keyword in name for keyword in ["薯片", "饼干", "糖果"]):
                suggestions.append(f"- {name} → 建议选择坚果、水果等健康零食")
            elif "food" in category.lower():
                suggestions.append(f"- {name} → 建议选择更高蛋白质、低加工的同类商品")
        
        if not suggestions:
            suggestions.append("- 购买的商品整体较为健康，建议继续保持")
        
        return "\n".join(suggestions[:5])  # 最多5个建议

    def _add_safety_considerations(self, prompt: str) -> str:
        """添加安全考虑和免责声明"""
        # 检查是否包含医疗相关内容
        medical_keywords = ["治疗", "诊断", "疾病", "药物", "医生", "健康问题"]
        
        if any(keyword in prompt for keyword in medical_keywords):
            return prompt + f"\n\n{self.safety_disclaimer}"
        
        return prompt

    def optimize_prompt_length(self, prompt: str, max_tokens: int = 3000) -> str:
        """优化prompt长度"""
        if len(prompt.split()) <= max_tokens:
            return prompt
        
        # 简化策略：保留关键信息，压缩次要信息
        lines = prompt.split('\n')
        essential_lines = []
        optional_lines = []
        
        for line in lines:
            if any(keyword in line for keyword in ["用户画像", "商品", "要求", "请提供"]):
                essential_lines.append(line)
            else:
                optional_lines.append(line)
        
        # 重新组合，优先保留关键信息
        optimized_prompt = '\n'.join(essential_lines)
        
        # 如果还有空间，添加次要信息
        remaining_tokens = max_tokens - len(optimized_prompt.split())
        if remaining_tokens > 0:
            additional_content = '\n'.join(optional_lines)
            additional_words = additional_content.split()[:remaining_tokens]
            optimized_prompt += '\n' + ' '.join(additional_words)
        
        return optimized_prompt

    def validate_template_variables(self, template_name: str, context: PromptContext) -> Dict[str, Any]:
        """验证模板变量完整性"""
        validation_result = {
            "valid": True,
            "missing_variables": [],
            "warnings": []
        }
        
        if template_name == "barcode_scan":
            required_vars = ["user_profile", "original_product", "recommended_products"]
            for var in required_vars:
                if not getattr(context, var, None):
                    validation_result["missing_variables"].append(var)
                    validation_result["valid"] = False
        
        elif template_name == "receipt_analysis":
            required_vars = ["user_profile", "purchased_items"]
            for var in required_vars:
                if not getattr(context, var, None):
                    validation_result["missing_variables"].append(var)
                    validation_result["valid"] = False
        
        # 检查用户画像完整性
        user_profile = context.user_profile or {}
        essential_profile_fields = ["nutrition_goal", "age"]
        for field in essential_profile_fields:
            if field not in user_profile:
                validation_result["warnings"].append(f"用户画像缺少{field}字段")
        
        return validation_result

# 全局模板管理器实例
_template_manager = None

def get_template_manager() -> PromptTemplateManager:
    """获取全局模板管理器实例"""
    global _template_manager
    if _template_manager is None:
        _template_manager = PromptTemplateManager()
    return _template_manager

# 便捷函数
def generate_barcode_prompt(user_profile: Dict, original_product: Dict, 
                          recommended_products: List[Dict], 
                          nutrition_comparison: Optional[Dict] = None) -> str:
    """便捷的条形码扫描prompt生成"""
    context = PromptContext(
        user_profile=user_profile,
        original_product=original_product,
        recommended_products=recommended_products,
        nutrition_comparison=nutrition_comparison,
        request_type="barcode_scan"
    )
    
    template_manager = get_template_manager()
    return template_manager.generate_barcode_scan_prompt(context)

def generate_receipt_prompt(user_profile: Dict, purchased_items: List[Dict]) -> str:
    """便捷的小票分析prompt生成"""
    context = PromptContext(
        user_profile=user_profile,
        purchased_items=purchased_items,
        request_type="receipt_analysis"
    )
    
    template_manager = get_template_manager()
    return template_manager.generate_receipt_analysis_prompt(context)