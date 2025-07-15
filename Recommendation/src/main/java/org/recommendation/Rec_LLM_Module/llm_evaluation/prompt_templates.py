"""
Prompt Template Management
Specialized prompt design for barcode scanning and receipt analysis
"""

import logging
from typing import Dict, List, Optional, Any
from datetime import datetime
from dataclasses import dataclass

from config.constants import NutritionGoal, LLM_CONSTANTS

logger = logging.getLogger(__name__)

@dataclass
class PromptContext:
    """Prompt context data"""
    user_profile: Dict[str, Any]
    original_product: Optional[Dict[str, Any]] = None
    recommended_products: Optional[List[Dict[str, Any]]] = None
    purchased_items: Optional[List[Dict[str, Any]]] = None
    nutrition_comparison: Optional[Dict[str, Any]] = None
    request_type: str = "unknown"

class PromptTemplateManager:
    """Prompt template manager"""
    
    def __init__(self):
        self.templates = self._load_templates()
        self.safety_disclaimer = "Note: The above recommendations are for reference only and cannot replace professional medical advice. Please consult a doctor if you have health concerns."
        
    def _load_templates(self) -> Dict[str, str]:
        """Load all prompt templates"""
        return {
            "barcode_scan": self._get_barcode_scan_template(),
            "receipt_analysis": self._get_receipt_analysis_template(),
            "nutrition_comparison": self._get_nutrition_comparison_template(),
            "allergen_warning": self._get_allergen_warning_template(),
            "health_assessment": self._get_health_assessment_template(),
            "maintain_health": self._get_maintain_health_template()
        }
    
    def generate_barcode_scan_prompt(self, context: PromptContext) -> str:
        """Generate barcode scan recommendation analysis prompt"""
        template = self.templates["barcode_scan"]
        
        # 准备模板变量
        user_profile = context.user_profile
        original_product = context.original_product or {}
        recommended_products = context.recommended_products or []
        nutrition_comparison = context.nutrition_comparison or {}
        
        # 用户画像信息
        age = user_profile.get("age", "Unknown")
        gender = self._translate_gender(user_profile.get("gender", ""))
        height_cm = user_profile.get("height_cm", "Unknown")
        weight_kg = user_profile.get("weight_kg", "Unknown")
        nutrition_goal_en = self._translate_nutrition_goal(user_profile.get("nutrition_goal", "maintain"))
        activity_level_en = self._translate_activity_level(user_profile.get("activity_level", "moderate"))
        
        # 过敏原信息
        allergens_list = self._format_allergens_list(user_profile.get("allergens", []))
        
        # 营养目标信息
        daily_calories = user_profile.get("daily_calories_target", "Not set")
        daily_protein = user_profile.get("daily_protein_target", "Not set")
        daily_nutrition_targets = f"Calories {daily_calories}kcal, Protein {daily_protein}g"
        
        # 原商品信息
        original_product_name = original_product.get("product_name", "Unknown product")
        original_product_brand = original_product.get("brand", "Unknown brand")
        original_calories = original_product.get("energy_kcal_100g", "Unknown")
        original_protein = original_product.get("proteins_100g", "Unknown")
        original_fat = original_product.get("fat_100g", "Unknown")
        original_carbs = original_product.get("carbohydrates_100g", "Unknown")
        original_sugar = original_product.get("sugars_100g", "Unknown")
        
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
            nutrition_goal_en=nutrition_goal_en,
            activity_level_en=activity_level_en,
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
        """Generate receipt analysis prompt"""
        template = self.templates["receipt_analysis"]
        
        user_profile = context.user_profile
        purchased_items = context.purchased_items or []
        
        # 用户画像信息
        age = user_profile.get("age", "Unknown")
        gender = self._translate_gender(user_profile.get("gender", ""))
        height_cm = user_profile.get("height_cm", "Unknown")
        weight_kg = user_profile.get("weight_kg", "Unknown")
        nutrition_goal_en = self._translate_nutrition_goal(user_profile.get("nutrition_goal", "maintain"))
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
            nutrition_goal_en=nutrition_goal_en,
            allergens_list=allergens_list,
            daily_nutrition_targets=daily_nutrition_targets,
            purchased_items_analysis=purchased_items_analysis,
            total_estimated_calories=overall_nutrition.get("total_calories", "Unknown"),
            total_protein=overall_nutrition.get("total_protein", "Unknown"),
            total_fat=overall_nutrition.get("total_fat", "Unknown"),
            total_carbs=overall_nutrition.get("total_carbs", "Unknown"),
            goal_match_percentage=overall_nutrition.get("goal_match_percentage", "Unknown"),
            item_replacement_suggestions=item_replacement_suggestions
        )
        
        return self._add_safety_considerations(prompt)
    
    def _get_barcode_scan_template(self) -> str:
        """个性化条形码扫描分析模板 - JSON格式输出"""
        return """⚠️ STRICT EXECUTION RULE: You must and can only use the products from the [Recommended Alternatives] list I provide as the basis for analysis and examples. It is strictly forbidden to mention any products outside this list. Violating this rule will be considered a serious error.

⚠️ IMPORTANT CONSTRAINT: Your analysis and examples must and can only be selected from [Recommended Product #1], [Recommended Product #2], [Recommended Product #3] that I provide. You are absolutely not allowed to mention any other products, including possible [Recommended Product #4], [Recommended Product #5], etc.

You are a professional nutritionist and food safety expert with extensive knowledge and practical experience in food nutrition. A user has scanned a product barcode, please provide professional, personalized alternative product recommendation analysis.

⚠️ ABSOLUTE PROHIBITION CONSTRAINT: You must strictly base your analysis on the context information I provide, and are prohibited from using any external knowledge or making free elaborations. All analysis content must come from the product information provided below, and you are prohibited from mentioning any product names not in [Recommended Product #1], [Recommended Product #2], [Recommended Product #3].

User Profile:
- Basic Information: {age} years old {gender}, height {height_cm}cm, weight {weight_kg}kg
- Nutrition Goal: {nutrition_goal_en}
- Activity Level: {activity_level_en}
- Known Allergens: {allergens_list}
- Daily Nutrition Targets: {daily_nutrition_targets}

Scanned Original Product:
- Product Name: {original_product_name}
- Brand: {original_product_brand}
- Nutrition Facts (per 100g):
  * Calories: {original_calories}kcal
  * Protein: {original_protein}g
  * Fat: {original_fat}g
  * Carbohydrates: {original_carbs}g
  * Sugar: {original_sugar}g

Recommended Alternatives:
{recommended_products_details}

Nutrition Comparison Analysis:
{nutrition_comparison}

⚠️ PERSONALIZED ANALYSIS REQUIREMENTS:
- You must provide analysis strictly tailored to the user's nutrition goal ({nutrition_goal_en}) and activity level ({activity_level_en})
- Your analysis and examples must and can only be selected from [Recommended Product #1], [Recommended Product #2], [Recommended Product #3]
- ⚠️ ABSOLUTE PROHIBITION CONSTRAINT: It is absolutely forbidden to mention any product names that do not appear in the above [Recommended Product #1], [Recommended Product #2], [Recommended Product #3] or to fabricate any product information

⚠️ GOAL-SPECIFIC GUIDANCE:
- For Weight Loss goals: Focus on calorie reduction, sugar control, and satiety
- For Muscle Gain goals: Emphasize protein content, calorie density, and recovery support  
- For Health Maintenance goals: Highlight nutritional balance, variety, and moderation
- Always reference the specific activity level when making recommendations

### Output Format Requirements ###
Please return your analysis strictly in the following JSON format, without any extra explanations, Markdown formatting, or code blocks:

{{
  "summary": "One sentence core assessment based on user's {nutrition_goal_en} goal and {activity_level_en} activity level (40-60 words)",
  "detailedAnalysis": "Detailed nutrition analysis with specific data from comparison above, explaining why this product aligns or doesn't align with user goals (80-120 words). All output fields (summary, detailedAnalysis, actionSuggestions) must be in English.", 
  "actionSuggestions": [
    "Specific actionable suggestion 1 based on recommended alternatives",
    "Specific actionable suggestion 2 for achieving nutrition goals",
    "Specific actionable suggestion 3 for better choices"
  ]
}}

### Example Output Format ###
{{
  "summary": "Based on your {nutrition_goal_en} goal and {activity_level_en} activity level, this product has high sugar content that may not align with your targets",
  "detailedAnalysis": "This product contains {original_sugar}g sugar per 100g, which exceeds recommended intake. Compared to recommended alternatives, it has higher calorie density that may not support your {nutrition_goal_en} goals. Consider choosing recommended lower-sugar alternatives that better support your health objectives while meeting your {activity_level_en} nutritional needs.",
  "actionSuggestions": [
    "Choose recommended lower-sugar alternatives with less than 10g sugar per 100g",
    "Based on your {activity_level_en} activity level, moderate intake frequency of high-sugar products", 
    "Prioritize the first recommended option as it better aligns with your {nutrition_goal_en} goals"
  ]
}}

Please ensure your reply is in pure JSON format for easy program parsing."""

    def _get_receipt_analysis_template(self) -> str:
        """Receipt analysis template - Enhanced JSON format constraints"""
        return """
As a professional nutrition analyst, please analyze the user's shopping receipt and provide in-depth insights.

## User Information
- Nutrition Goal: {nutrition_goal_en}
- Allergens: {allergens_list}

## Purchased Product Details
{purchased_items_analysis}

## Overall Nutrition Summary
- Total Calories: {total_estimated_calories}kcal
- Total Protein: {total_protein}g
- Total Fat: {total_fat}g
- Total Carbohydrates: {total_carbs}g
- Nutrition Goal Match: {goal_match_percentage}%

## Analysis Requirements
Please provide professional nutrition analysis, including:
1. Core Insight - Identify major nutrition issues or highlights
2. Key Findings - Specific nutrition data analysis (list 2-3 specific findings)
3. Improvement Suggestions - Practical shopping adjustment recommendations (provide 2-3 suggestions)

### Output Format Requirements ###
Please return your analysis strictly in the following JSON format, without any extra explanations, Markdown formatting, or code blocks:

{{
  "core_insight": "One sentence summarizing major nutrition issues or highlights",
  "key_findings": [
    "Specific nutrition finding 1 (with data support)",
    "Specific nutrition finding 2 (with data support)",
    "Specific nutrition finding 3 (with data support)"
  ],
  "improvement_suggestions": [
    "Practical improvement suggestion 1",
    "Practical improvement suggestion 2", 
    "Practical improvement suggestion 3"
  ]
}}

### Example Output ###
{{
  "core_insight": "Purchased snacks are too high in calories and sugar, affecting weight loss goals",
  "key_findings": [
    "Chocolate bars total 110g sugar, exceeding daily recommended intake by 220%",
    "High-calorie dense products account for 80%, average 520kcal/100g",
    "Protein intake insufficient, only 12% of total calories"
  ],
  "improvement_suggestions": [
    "Replace chocolate snacks with nuts and yogurt, reducing 50% sugar intake",
    "Increase lean meat and legume purchases, boost protein ratio to 25%",
    "Choose whole grains and vegetables, increase fiber and satiety"
  ]
}}

Please ensure your reply is in pure JSON format for easy program parsing.
"""

    def _get_nutrition_comparison_template(self) -> str:
        """Nutrition comparison analysis template"""
        return """Please provide detailed nutrition comparison analysis for the following products:

Original Product: {original_product}
Alternative Product: {alternative_product}
User Goal: {nutrition_goal}

Please compare from the following perspectives:
1. Calorie comparison and its impact on user goals
2. Changes in macronutrients (protein, carbohydrates, fat)
3. Differences in micronutrients and beneficial components
4. Overall health value assessment

Requirements: Provide specific data support, and evaluations should be objective and accurate."""

    def _get_allergen_warning_template(self) -> str:
        """Allergen warning template"""
        return """⚠️ ALLERGEN SAFETY WARNING ⚠️

This product may contain the following allergens:
{detected_allergens}

Your known allergens: {user_allergens}

Safety Recommendations:
{safety_recommendations}

Please carefully check product labels before purchasing, and consult a doctor if you have any questions."""

    def _get_health_assessment_template(self) -> str:
        """Health assessment template"""
        return """Personalized assessment based on your health profile:

User Information:
- Age: {age} years old
- BMI: {bmi}
- Nutrition Goal: {nutrition_goal}
- Activity Level: {activity_level}

Product Health Assessment:
{health_assessment}

Personalized Recommendations:
{personalized_recommendations}"""

    def _get_maintain_health_template(self) -> str:
        """Health maintenance template - legacy support"""
        return """As a nutrition expert focused on health maintenance, please analyze:

User Profile: Health maintenance goal
Product: {original_product}
Alternatives: {recommendations}

Please provide balanced nutrition recommendations emphasizing sustainable, long-term healthy choices. Analysis should be 70-90 words covering balance, variety, and moderation."""

    def _translate_gender(self, gender: str) -> str:
        """Translate gender"""
        gender_map = {
            "male": "Male",
            "female": "Female",
            "other": "Other"
        }
        return gender_map.get(gender, "")

    def _translate_nutrition_goal(self, goal: str) -> str:
        """Translate nutrition goal - legacy support"""
        goal_map = {
            "lose_weight": "Weight Loss",
            "gain_muscle": "Muscle Gain",
            "maintain": "Health Maintenance"
        }
        return goal_map.get(goal, "Health Maintenance")

    def _translate_activity_level(self, level: str) -> str:
        """Translate activity level"""
        level_map = {
            "sedentary": "Sedentary",
            "light": "Light Activity",
            "moderate": "Moderate Activity",
            "active": "Active",
            "very_active": "Very Active"
        }
        return level_map.get(level, "Moderate Activity")

    def _format_allergens_list(self, allergens: List[Dict]) -> str:
        """Format allergen list"""
        if not allergens:
            return "No known allergens"
        
        allergen_names = []
        for allergen in allergens:
            name = allergen.get("name", "")
            severity = allergen.get("severity_level", "")
            if name:
                if severity:
                    allergen_names.append(f"{name} ({severity})")
                else:
                    allergen_names.append(name)
        
        return ", ".join(allergen_names) if allergen_names else "No known allergens"

    def _format_daily_targets(self, user_profile: Dict) -> str:
        """Format daily nutrition targets"""
        targets = []
        
        calories = user_profile.get("daily_calories_target")
        if calories:
            targets.append(f"Calories {calories}kcal")
        
        protein = user_profile.get("daily_protein_target")
        if protein:
            targets.append(f"Protein {protein}g")
        
        carbs = user_profile.get("daily_carb_target")
        if carbs:
            targets.append(f"Carbohydrates {carbs}g")
        
        fat = user_profile.get("daily_fat_target")
        if fat:
            targets.append(f"Fat {fat}g")
        
        return ", ".join(targets) if targets else "No specific targets set"

    def _format_recommended_products(self, products: List) -> str:
        """Format recommended product details - handles both RecommendationResult objects and dict"""
        if not products:
            return "No recommended products available"
        
        formatted_products = []
        for i, item in enumerate(products[:5], 1):  # 最多显示5个推荐
            # Handle RecommendationResult objects
            if hasattr(item, 'product'):
                product = item.product
                name = product.get("product_name", "Unknown product")
                brand = product.get("brand", "Unknown brand")
                calories = product.get("energy_kcal_100g", "Unknown")
                protein = product.get("proteins_100g", "Unknown")
                fat = product.get("fat_100g", "Unknown")
                sugar = product.get("sugars_100g", "Unknown")
            # Handle dict objects (legacy support)
            elif isinstance(item, dict):
                name = item.get("product_name", "Unknown product")
                brand = item.get("brand", "Unknown brand")
                calories = item.get("energy_kcal_100g", "Unknown")
                protein = item.get("proteins_100g", "Unknown")
                fat = item.get("fat_100g", "Unknown")
                sugar = item.get("sugars_100g", "Unknown")
            else:
                continue  # Skip invalid items
            
            product_info = f"""
Recommended Product {i}: {name} ({brand})
- Calories: {calories}kcal/100g
- Protein: {protein}g/100g  
- Fat: {fat}g/100g
- Sugar: {sugar}g/100g"""
            
            formatted_products.append(product_info)
        
        return "\n".join(formatted_products)

    def _format_nutrition_comparison(self, comparison: Dict) -> str:
        """Format nutrition comparison information"""
        if not comparison:
            return "No detailed nutrition comparison data available"
        
        nutrition_comparison = comparison.get("nutrition_comparison", {})
        if not nutrition_comparison:
            return "No nutrition component comparison available"
        
        comparisons = []
        for field, data in nutrition_comparison.items():
            if isinstance(data, dict):
                name = data.get("name", field)
                original = data.get("original_value", 0)
                alternative = data.get("alternative_value", 0)
                change = data.get("absolute_change", 0)
                percent_change = data.get("percent_change", 0)
                
                direction_symbol = "↑" if change > 0 else "↓" if change < 0 else "→"
                
                comparison_text = f"- {name}: {original} → {alternative} ({direction_symbol}{percent_change:+.1f}%)"
                comparisons.append(comparison_text)
        
        return "\n".join(comparisons) if comparisons else "Nutrition components are basically similar"

    def _format_purchased_items_analysis(self, items: List[Dict]) -> str:
        """Format purchased items analysis"""
        if not items:
            return "Shopping list is empty"
        
        formatted_items = []
        for item in items:
            name = item.get("product_name", item.get("item_name_ocr", "Unknown product"))
            quantity = item.get("quantity", 1)
            calories = item.get("energy_kcal_100g", "Unknown")
            protein = item.get("proteins_100g", "Unknown")
            sugar = item.get("sugars_100g", "Unknown")
            category = item.get("category", "Uncategorized")
            
            # 突出显示糖分含量
            sugar_warning = ""
            if sugar != "Unknown" and float(sugar) > 10:
                sugar_warning = f"⚠️ High Sugar Warning: {sugar}g/100g"
            
            item_info = f"- {name} × {quantity} ({category})\n  * Calories: {calories}kcal/100g\n  * Protein: {protein}g/100g\n  * Sugar: {sugar}g/100g {sugar_warning}"
            formatted_items.append(item_info)
        
        return "\n".join(formatted_items)

    def _calculate_overall_nutrition_from_items(self, items: List[Dict]) -> Dict:
        """Calculate overall nutrition from purchased items"""
        total_calories = 0
        total_protein = 0
        total_fat = 0
        total_carbs = 0
        
        for item in items:
            quantity = item.get("quantity", 1)
            
            # 安全获取营养成分
            try:
                calories = float(item.get("energy_kcal_100g", 0)) * quantity * 0.01  # 假设每份100g
                protein = float(item.get("proteins_100g", 0)) * quantity * 0.01
                fat = float(item.get("fat_100g", 0)) * quantity * 0.01
                carbs = float(item.get("carbohydrates_100g", 0)) * quantity * 0.01
                
                total_calories += calories
                total_protein += protein
                total_fat += fat
                total_carbs += carbs
            except (ValueError, TypeError):
                continue
        
        return {
            "total_calories": round(total_calories, 1),
            "total_protein": round(total_protein, 1),
            "total_fat": round(total_fat, 1),
            "total_carbs": round(total_carbs, 1),
            "goal_match_percentage": 75  # 简化计算
        }

    def _format_item_replacements(self, items: List[Dict]) -> str:
        """Format item replacement suggestions"""
        if not items:
            return "No replacement suggestions available"
        
        suggestions = []
        for item in items[:3]:  # 最多显示3个建议
            name = item.get("product_name", "Unknown product")
            category = item.get("category", "")
            
            if category == "Snacks":
                suggestion = f"Replace {name} with nuts or fruit for healthier snacking"
            elif category == "Beverages":
                suggestion = f"Replace {name} with water or unsweetened tea"
            else:
                suggestion = f"Consider healthier alternatives to {name}"
            
            suggestions.append(f"- {suggestion}")
        
        return "\n".join(suggestions)

    def _add_safety_considerations(self, prompt: str) -> str:
        """Add safety considerations to prompt"""
        return f"{prompt}\n\n{self.safety_disclaimer}"

    def optimize_prompt_length(self, prompt: str, max_tokens: int = 3000) -> str:
        """Optimize prompt length to fit token limits"""
        try:
            # 简单的长度估算：1个token约等于4个字符
            estimated_tokens = len(prompt) // 4
            
            if estimated_tokens <= max_tokens:
                return prompt
            
            # 如果超长，进行智能截断
            target_length = max_tokens * 4
            
            # 优先保留关键部分
            lines = prompt.split('\n')
            essential_lines = []
            optional_lines = []
            
            for line in lines:
                if any(keyword in line for keyword in ['User Profile', 'Product Name', 'Nutrition Facts', 'STRICT']):
                    essential_lines.append(line)
                else:
                    optional_lines.append(line)
            
            # 重新组合
            essential_text = '\n'.join(essential_lines)
            if len(essential_text) <= target_length:
                # 添加部分可选内容
                remaining_length = target_length - len(essential_text)
                optional_text = '\n'.join(optional_lines)[:remaining_length]
                return essential_text + '\n' + optional_text
            else:
                return essential_text[:target_length]
                
        except Exception as e:
            logger.error(f"Prompt optimization failed: {e}")
            return prompt[:max_tokens * 4]  # 简单截断

    def validate_template_variables(self, template_name: str, context: PromptContext) -> Dict[str, Any]:
        """Validate template variables"""
        validation_results = {
            "template_name": template_name,
            "valid": True,
            "missing_variables": [],
            "validation_errors": []
        }
        
        try:
            if template_name == "barcode_scan":
                required_vars = ["user_profile", "original_product", "recommended_products"]
                for var in required_vars:
                    if not hasattr(context, var) or getattr(context, var) is None:
                        validation_results["missing_variables"].append(var)
                        validation_results["valid"] = False
            
            elif template_name == "receipt_analysis":
                required_vars = ["user_profile", "purchased_items"]
                for var in required_vars:
                    if not hasattr(context, var) or getattr(context, var) is None:
                        validation_results["missing_variables"].append(var)
                        validation_results["valid"] = False
                        
        except Exception as e:
            validation_results["validation_errors"].append(str(e))
            validation_results["valid"] = False
        
        return validation_results

# 便捷函数
def get_template_manager() -> PromptTemplateManager:
    """Get template manager instance"""
    return PromptTemplateManager()

def generate_barcode_prompt(original_product: Dict, recommendations: List, 
                          user_profile: Dict, nutrition_comparison: Optional[Dict] = None) -> str:
    """Generate barcode scan prompt - convenience function"""
    try:
        manager = get_template_manager()
        
        context = PromptContext(
            user_profile=user_profile,
            original_product=original_product,
            recommended_products=recommendations,
            nutrition_comparison=nutrition_comparison,
            request_type="barcode_scan"
        )
        
        return manager.generate_barcode_scan_prompt(context)
    
    except Exception as e:
        logger.error(f"Barcode prompt generation failed: {e}")
        return f"""Error generating prompt: {e}
        
Please provide product recommendation analysis based on:
- Original Product: {original_product.get('product_name', 'Unknown')}
- User Goal: {user_profile.get('nutrition_goal', 'Unknown')}
- Available Recommendations: {len(recommendations) if recommendations else 0}

Please provide a 70-90 word professional analysis with core insights, detailed analysis, and action recommendations."""

def generate_receipt_prompt(user_profile: Dict, purchased_items: List[Dict]) -> str:
    """Generate receipt analysis prompt - convenience function"""
    manager = get_template_manager()
    context = PromptContext(
        user_profile=user_profile,
        purchased_items=purchased_items,
        request_type="receipt_analysis"
    )
    return manager.generate_receipt_analysis_prompt(context)

def _get_general_recommendation_template() -> str:
    """General recommendation template - legacy support"""
    return """As a professional nutritionist, please analyze the following products and provide personalized recommendations:

Original Product: {original_product}
User Goal: {nutrition_goal}
Allergens: {allergens}

Recommendations:
{recommendations}

Please provide 70-90 word professional analysis covering nutrition benefits and goal alignment."""

def _get_maintain_health_template() -> str:
    """Health maintenance template - legacy support"""
    return """As a nutrition expert focused on health maintenance, please analyze:

User Profile: Health maintenance goal
Product: {original_product}
Alternatives: {recommendations}

Please provide balanced nutrition recommendations emphasizing sustainable, long-term healthy choices. Analysis should be 70-90 words covering balance, variety, and moderation."""

def _translate_nutrition_goal(goal: str) -> str:
    """Translate nutrition goal - legacy support"""
    goal_map = {
        "lose_weight": "Weight Loss",
        "gain_muscle": "Muscle Gain",
        "maintain": "Health Maintenance"
    }
    return goal_map.get(goal, "Health Maintenance")