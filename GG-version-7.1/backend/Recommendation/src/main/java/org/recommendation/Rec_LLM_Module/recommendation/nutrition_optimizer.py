"""
营养优化策略模块
实现基于用户营养目标的商品评分和排序算法
"""

import logging
import math
from typing import Dict, List, Optional, Tuple
from datetime import datetime
import numpy as np

from config.constants import (
    NutritionGoal, NUTRITION_STRATEGIES, 
    NUTRITION_VALIDATION_RANGES, USER_VALIDATION_RANGES
)

logger = logging.getLogger(__name__)

class NutritionOptimizer:
    """营养优化评分器"""
    
    def __init__(self):
        self.strategies = NUTRITION_STRATEGIES.copy()
        self.validation_ranges = NUTRITION_VALIDATION_RANGES.copy()
    
    def _safe_get_nutrition_value(self, product: Dict, field: str, default: float = 0.0) -> float:
        """安全获取营养值，确保不为None且为数值类型"""
        value = product.get(field)
        if value is None:
            return default
        try:
            return float(value)
        except (TypeError, ValueError):
            return default
        
    def calculate_nutrition_score(self, product: Dict, user_goal: str, 
                                user_profile: Optional[Dict] = None) -> float:
        """
        计算商品营养评分
        Args:
            product: 商品营养信息
            user_goal: 用户营养目标
            user_profile: 用户画像（用于个性化调整）
        Returns:
            营养评分 (0.0 - 1.0)
        """
        try:
            if user_goal not in self.strategies:
                logger.warning(f"未知营养目标: {user_goal}，使用默认策略")
                user_goal = NutritionGoal.MAINTAIN.value
            
            strategy = self.strategies[user_goal]
            
            # 基础营养评分
            if user_goal == NutritionGoal.LOSE_WEIGHT.value:
                score = self._calculate_weight_loss_score(product, strategy)
            elif user_goal == NutritionGoal.GAIN_MUSCLE.value:
                score = self._calculate_muscle_gain_score(product, strategy)
            elif user_goal == NutritionGoal.MAINTAIN.value:
                score = self._calculate_maintenance_score(product, strategy)
            else:
                score = self._calculate_general_health_score(product, strategy)
            
            # 个性化调整
            if user_profile:
                score = self._apply_personalization_factors(score, product, user_profile)
            
            # 确保评分在有效范围内
            return max(0.0, min(1.0, score))
        except Exception as e:
            logger.error(f"营养评分计算失败: {e}")
            logger.error(f"产品: {product.get('product_name', 'Unknown')}")
            logger.error(f"用户画像: {user_profile}")
            raise
    
    def _calculate_weight_loss_score(self, product: Dict, strategy: Dict) -> float:
        """计算减脂策略评分 - 修复版本"""
        score = 0.5  # 基础分数
        
        # 热量评分（权重 -0.4）
        calories = self._safe_get_nutrition_value(product, "energy_kcal_100g")
        if calories > 0:
            # 低热量商品得分更高，直接使用权重*归一化分数（避免双重负数）
            calorie_score = self._normalize_reverse(calories, 0, 600)  # 0-600kcal/100g范围
            # 修复：对于负权重，使用 base_score + weight * (score - 0.5) 的方式
            score += strategy["energy_kcal_100g"] * (calorie_score - 0.5)
        
        # 脂肪评分（权重 -0.3）
        fat = self._safe_get_nutrition_value(product, "fat_100g")
        if fat > 0:
            # 低脂肪商品得分更高
            fat_score = self._normalize_reverse(fat, 0, 50)  # 0-50g/100g范围
            score += strategy["fat_100g"] * (fat_score - 0.5)
        
        # 糖分评分（权重 -0.3）- 关键修复点
        sugar = self._safe_get_nutrition_value(product, "sugars_100g")
        if sugar > 0:
            # 低糖商品得分更高
            sugar_score = self._normalize_reverse(sugar, 0, 50)  # 0-50g/100g范围
            score += strategy["sugars_100g"] * (sugar_score - 0.5)
        
        # 蛋白质评分（权重 0.2）
        protein = self._safe_get_nutrition_value(product, "proteins_100g")
        if protein > 0:
            # 适量蛋白质加分
            protein_score = self._normalize_forward(protein, 0, 30)  # 0-30g/100g范围
            score += strategy["proteins_100g"] * (protein_score - 0.5)
        
        # 纤维加分（如果有数据）
        fiber = self._safe_get_nutrition_value(product, "fiber_100g")
        if fiber > 0:
            fiber_score = self._normalize_forward(fiber, 0, 20)  # 0-20g/100g范围
            score += strategy.get("fiber_bonus", 0.3) * (fiber_score - 0.5)
        
        # 营养密度调整
        score = self._apply_nutrient_density_bonus(score, product)
        
        return score
    
    def _calculate_muscle_gain_score(self, product: Dict, strategy: Dict) -> float:
        """计算增肌策略评分"""
        score = 0.5  # 基础分数
        
        # 蛋白质评分（权重 0.5，核心指标）
        protein = self._safe_get_nutrition_value(product, "proteins_100g")
        if protein > 0:
            # 高蛋白商品得分更高
            protein_score = self._normalize_forward(protein, 0, 50)  # 0-50g/100g范围
            score += strategy["proteins_100g"] * protein_score
        
        # 碳水化合物评分（权重 0.2）
        carbs = self._safe_get_nutrition_value(product, "carbohydrates_100g")
        if carbs > 0:
            # 适量碳水化合物
            carbs_score = self._normalize_optimal(carbs, 15, 45)  # 15-45g/100g最优范围
            score += strategy["carbohydrates_100g"] * carbs_score
        
        # 热量评分（权重 0.3）
        calories = self._safe_get_nutrition_value(product, "energy_kcal_100g")
        if calories > 0:
            # 充足热量但不过高
            calorie_score = self._normalize_optimal(calories, 200, 500)  # 200-500kcal/100g最优
            score += strategy["energy_kcal_100g"] * calorie_score
        
        # 脂肪评分（权重 0.1）
        fat = self._safe_get_nutrition_value(product, "fat_100g")
        if fat > 0:
            # 适量健康脂肪
            fat_score = self._normalize_optimal(fat, 5, 20)  # 5-20g/100g最优范围
            score += strategy["fat_100g"] * fat_score
        
        # BCAA/完整蛋白质加分
        if self._is_complete_protein_source(product):
            score += strategy.get("bcaa_bonus", 0.4) * 0.5
        
        return score
    
    def _calculate_maintenance_score(self, product: Dict, strategy: Dict) -> float:
        """计算维持策略评分"""
        score = 0.5  # 基础分数
        
        # 营养均衡评分（权重 0.4）
        balance_score = self._calculate_nutrition_balance(product)
        score += strategy["balance_score"] * balance_score
        
        # 营养多样性评分（权重 0.3）
        variety_score = self._calculate_nutrition_variety(product)
        score += strategy["variety_score"] * variety_score
        
        # 天然成分加分（权重 0.3）
        natural_score = self._assess_natural_content(product)
        score += strategy["natural_bonus"] * natural_score
        
        return score
    
    def _calculate_general_health_score(self, product: Dict, strategy: Dict) -> float:
        """计算一般健康策略评分"""
        score = 0.5  # 基础分数
        
        # 营养密度评分
        nutrient_density = self._calculate_nutrient_density(product)
        score += strategy.get("nutrient_density", 0.4) * nutrient_density
        
        # 天然成分评分
        natural_score = self._assess_natural_content(product)
        score += strategy.get("natural_bonus", 0.3) * natural_score
        
        # 营养平衡评分
        balance_score = self._calculate_nutrition_balance(product)
        score += strategy.get("balance_score", 0.3) * balance_score
        
        return score
    
    def _normalize_forward(self, value: float, min_val: float, max_val: float) -> float:
        """正向归一化（值越大分数越高）"""
        if value <= min_val:
            return 0.0
        elif value >= max_val:
            return 1.0
        else:
            return (value - min_val) / (max_val - min_val)
    
    def _normalize_reverse(self, value: float, min_val: float, max_val: float) -> float:
        """反向归一化（值越小分数越高）- 修复版本，确保返回值在0-1范围内"""
        if value <= min_val:
            return 1.0
        elif value >= max_val:
            return 0.0
        else:
            return max(0.0, 1.0 - (value - min_val) / (max_val - min_val))
    
    def _normalize_optimal(self, value: float, optimal_min: float, optimal_max: float) -> float:
        """最优区间归一化（在最优区间内分数最高）"""
        if optimal_min <= value <= optimal_max:
            return 1.0
        elif value < optimal_min:
            # 低于最优区间
            return max(0.0, value / optimal_min)
        else:
            # 高于最优区间，分数逐渐降低
            excess_ratio = (value - optimal_max) / optimal_max
            return max(0.0, 1.0 - excess_ratio)
    
    def _calculate_nutrition_balance(self, product: Dict) -> float:
        """计算营养平衡评分"""
        # 获取三大营养素，确保安全
        protein = self._safe_get_nutrition_value(product, "proteins_100g")
        carbs = self._safe_get_nutrition_value(product, "carbohydrates_100g")
        fat = self._safe_get_nutrition_value(product, "fat_100g")
        
        total = protein + carbs + fat
        if total == 0:
            return 0.0
        
        # 计算比例
        protein_ratio = protein / total
        carbs_ratio = carbs / total
        fat_ratio = fat / total
        
        # 理想比例（可调整）
        ideal_protein = 0.3
        ideal_carbs = 0.5
        ideal_fat = 0.2
        
        # 计算与理想比例的偏差
        protein_diff = abs(protein_ratio - ideal_protein)
        carbs_diff = abs(carbs_ratio - ideal_carbs)
        fat_diff = abs(fat_ratio - ideal_fat)
        
        # 平均偏差越小，平衡性越好
        avg_diff = (protein_diff + carbs_diff + fat_diff) / 3
        balance_score = max(0.0, 1.0 - avg_diff * 2)  # 放大偏差影响
        
        return balance_score
    
    def _calculate_nutrition_variety(self, product: Dict) -> float:
        """计算营养多样性评分"""
        # 检查多种营养成分的存在
        nutrition_fields = [
            "proteins_100g", "carbohydrates_100g", "fat_100g",
            "fiber_100g", "sodium_100g", "sugars_100g"
        ]
        
        present_nutrients = 0
        total_possible = len(nutrition_fields)
        
        for field in nutrition_fields:
            value = product.get(field)
            if value is not None and value > 0:
                present_nutrients += 1
        
        variety_score = present_nutrients / total_possible
        return variety_score
    
    def _calculate_nutrient_density(self, product: Dict) -> float:
        """计算营养密度评分"""
        calories = self._safe_get_nutrition_value(product, "energy_kcal_100g", 1)  # 避免除零
        if calories <= 0:
            return 0.0
        
        # 计算有益营养素密度
        protein = self._safe_get_nutrition_value(product, "proteins_100g")
        fiber = self._safe_get_nutrition_value(product, "fiber_100g")
        
        # 计算营养密度（蛋白质 + 纤维）/ 热量
        beneficial_nutrients = protein + fiber
        nutrient_density = beneficial_nutrients / calories * 100  # 每100卡路里的有益营养素
        
        # 归一化到0-1范围
        return min(1.0, nutrient_density / 10)  # 假设10为高营养密度阈值
    
    def _assess_natural_content(self, product: Dict) -> float:
        """评估天然成分评分"""
        # 基于成分列表和商品名称判断天然程度
        ingredients = product.get("ingredients", "").lower()
        name = product.get("product_name", "").lower()
        
        # 天然指标词汇
        natural_keywords = [
            "organic", "natural", "whole", "fresh", "raw", "unprocessed",
            "有机", "天然", "新鲜", "全麦", "纯天然"
        ]
        
        # 添加剂指标词汇
        additive_keywords = [
            "preservative", "artificial", "color", "flavor", "stabilizer",
            "防腐剂", "人工", "色素", "香精", "稳定剂", "添加剂"
        ]
        
        natural_score = 0.5  # 基础分数
        
        # 天然关键词加分
        for keyword in natural_keywords:
            if keyword in name or keyword in ingredients:
                natural_score += 0.1
        
        # 添加剂关键词扣分
        for keyword in additive_keywords:
            if keyword in ingredients:
                natural_score -= 0.1
        
        return max(0.0, min(1.0, natural_score))
    
    def _is_complete_protein_source(self, product: Dict) -> bool:
        """判断是否为完整蛋白质来源"""
        name = product.get("product_name", "").lower()
        ingredients = product.get("ingredients", "").lower()
        
        complete_protein_sources = [
            "meat", "chicken", "beef", "pork", "fish", "salmon", "tuna",
            "egg", "milk", "cheese", "yogurt", "quinoa", "soy",
            "肉", "鸡肉", "牛肉", "猪肉", "鱼", "蛋", "牛奶", "奶酪", "酸奶", "大豆"
        ]
        
        for source in complete_protein_sources:
            if source in name or source in ingredients:
                return True
        
        return False
    
    def _apply_nutrient_density_bonus(self, base_score: float, product: Dict) -> float:
        """应用营养密度奖励"""
        density_score = self._calculate_nutrient_density(product)
        # 高营养密度商品获得额外奖励
        bonus = density_score * 0.1  # 最多10%的额外奖励
        return base_score + bonus
    
    def _apply_personalization_factors(self, base_score: float, product: Dict, 
                                     user_profile: Dict) -> float:
        """应用个性化调整因子"""
        adjusted_score = base_score
        
        # 年龄调整
        age = user_profile.get("age") or 30
        try:
            age = float(age) if age is not None else 30.0
        except (TypeError, ValueError):
            age = 30.0
            
        if age > 60:
            # 老年人偏好低钠
            sodium = self._safe_get_nutrition_value(product, "sodium_100g")
            if sodium > 0:
                sodium_penalty = min(0.1, sodium / 2000)  # 钠含量惩罚
                adjusted_score -= sodium_penalty
        elif age < 25:
            # 年轻人对热量敏感度较低
            calories = self._safe_get_nutrition_value(product, "energy_kcal_100g")
            if calories > 300:
                adjusted_score += 0.05  # 轻微加分
        
        # 性别调整
        gender = user_profile.get("gender", "")
        if gender == "female":
            # 女性通常对铁含量更敏感（如果有数据）
            if "iron" in product.get("ingredients", "").lower():
                adjusted_score += 0.05
        
        # 活动水平调整
        activity_level = user_profile.get("activity_level", "moderate")
        if activity_level in ["active", "very_active"]:
            # 高活动水平的用户可以接受更多碳水化合物
            carbs = self._safe_get_nutrition_value(product, "carbohydrates_100g")
            if carbs > 20:
                adjusted_score += 0.05
        
        return adjusted_score
    
    def compare_nutrition_improvement(self, original: Dict, alternative: Dict, 
                                    user_goal: str) -> Dict:
        """
        计算营养改善度
        Args:
            original: 原商品
            alternative: 替代商品  
            user_goal: 用户营养目标
        Returns:
            详细的营养对比分析
        """
        improvements = {}
        
        # 基础营养指标对比
        nutrition_fields = [
            ("energy_kcal_100g", "热量", "kcal"),
            ("proteins_100g", "蛋白质", "g"),
            ("fat_100g", "脂肪", "g"),
            ("saturated_fat_100g", "饱和脂肪", "g"),
            ("carbohydrates_100g", "碳水化合物", "g"),
            ("sugars_100g", "糖分", "g")
        ]
        
        for field, name, unit in nutrition_fields:
            original_value = self._safe_get_nutrition_value(original, field)
            alternative_value = self._safe_get_nutrition_value(alternative, field)
            
            if original_value > 0:  # 避免除零错误
                change = alternative_value - original_value
                change_percent = (change / original_value) * 100
                
                improvements[field] = {
                    "name": name,
                    "unit": unit,
                    "original_value": round(original_value, 2),
                    "alternative_value": round(alternative_value, 2),
                    "absolute_change": round(change, 2),
                    "percent_change": round(change_percent, 1),
                    "improvement_direction": self._get_improvement_direction(field, change, user_goal)
                }
        
        # 整体改善评估
        overall_improvement = self._calculate_overall_improvement(improvements, user_goal)
        
        # 生成改善建议
        recommendations = self._generate_improvement_recommendations(improvements, user_goal)
        
        return {
            "nutrition_comparison": improvements,
            "overall_improvement_score": overall_improvement,
            "improvement_recommendations": recommendations,
            "user_goal": user_goal,
            "analysis_timestamp": datetime.now().isoformat()
        }
    
    def _get_improvement_direction(self, field: str, change: float, user_goal: str) -> str:
        """获取改善方向"""
        if user_goal == NutritionGoal.LOSE_WEIGHT.value:
            if field in ["energy_kcal_100g", "fat_100g", "sugars_100g"]:
                return "positive" if change < 0 else "negative"
            elif field == "proteins_100g":
                return "positive" if change > 0 else "negative"
        elif user_goal == NutritionGoal.GAIN_MUSCLE.value:
            if field == "proteins_100g":
                return "positive" if change > 0 else "negative"
            elif field in ["energy_kcal_100g", "carbohydrates_100g"]:
                return "positive" if change > 0 else "neutral"
        
        return "neutral"
    
    def _calculate_overall_improvement(self, improvements: Dict, user_goal: str) -> float:
        """计算整体改善评分"""
        if not improvements:
            return 0.0
        
        total_score = 0.0
        weight_sum = 0.0
        
        # 根据营养目标设置权重
        field_weights = self._get_field_weights(user_goal)
        
        for field, data in improvements.items():
            if field in field_weights:
                weight = field_weights[field]
                direction = data["improvement_direction"]
                change_percent = abs(data["percent_change"])
                
                if direction == "positive":
                    score = min(1.0, change_percent / 20)  # 20%改善为满分
                elif direction == "negative":
                    score = -min(1.0, change_percent / 20)
                else:
                    score = 0.0
                
                total_score += score * weight
                weight_sum += weight
        
        if weight_sum > 0:
            return total_score / weight_sum
        else:
            return 0.0
    
    def _get_field_weights(self, user_goal: str) -> Dict[str, float]:
        """获取字段权重"""
        if user_goal == NutritionGoal.LOSE_WEIGHT.value:
            return {
                "energy_kcal_100g": 0.4,
                "fat_100g": 0.3,
                "sugars_100g": 0.2,
                "proteins_100g": 0.1
            }
        elif user_goal == NutritionGoal.GAIN_MUSCLE.value:
            return {
                "proteins_100g": 0.5,
                "energy_kcal_100g": 0.3,
                "carbohydrates_100g": 0.2
            }
        else:
            return {
                "energy_kcal_100g": 0.25,
                "proteins_100g": 0.25,
                "fat_100g": 0.25,
                "sugars_100g": 0.25
            }
    
    def _generate_improvement_recommendations(self, improvements: Dict, user_goal: str) -> List[str]:
        """生成改善建议"""
        recommendations = []
        
        for field, data in improvements.items():
            if data["improvement_direction"] == "positive" and abs(data["percent_change"]) > 10:
                if field == "proteins_100g":
                    recommendations.append(f"蛋白质含量提升{data['percent_change']:.1f}%，有助于肌肉建设")
                elif field == "energy_kcal_100g" and data["percent_change"] < 0:
                    recommendations.append(f"热量降低{abs(data['percent_change']):.1f}%，支持减脂目标")
                elif field == "sugars_100g" and data["percent_change"] < 0:
                    recommendations.append(f"糖分减少{abs(data['percent_change']):.1f}%，更加健康")
        
        if not recommendations:
            recommendations.append("此替代品在营养成分上与原商品相似")
        
        return recommendations
    
    def calculate_health_impact_score(self, product: Dict, user_profile: Dict) -> float:
        """
        计算健康影响评分
        Args:
            product: 商品信息
            user_profile: 用户完整画像
        Returns:
            健康影响评分 (0.0 - 1.0)
        """
        # 基础健康评分
        base_score = 0.5
        
        # BMR和需求计算
        bmr = self._calculate_bmr(user_profile)
        if bmr > 0:
            # 计算商品对每日营养需求的贡献比例
            daily_calories_target = user_profile.get("daily_calories_target") or (bmr * 1.5)
            if daily_calories_target is None or daily_calories_target <= 0:
                daily_calories_target = bmr * 1.5
            
            product_calories = self._safe_get_nutrition_value(product, "energy_kcal_100g")
            
            # 假设一份商品约100g
            calorie_contribution = product_calories / daily_calories_target
            
            if 0.05 <= calorie_contribution <= 0.3:  # 5%-30%的日需求量为合理范围
                base_score += 0.2
            elif calorie_contribution > 0.5:  # 超过50%日需求量
                base_score -= 0.3
        
        # 年龄相关调整
        age = user_profile.get("age", 30)
        if age is not None and age > 60:
            # 老年人需要更多关注钠和纤维
            sodium = self._safe_get_nutrition_value(product, "sodium_100g")
            if sodium < 300:  # 低钠
                base_score += 0.1
            
            fiber = self._safe_get_nutrition_value(product, "fiber_100g")
            if fiber > 5:  # 高纤维
                base_score += 0.1
        
        # 性别相关调整
        gender = user_profile.get("gender", "")
        if gender == "female":
            # 女性需要更多铁和钙（如果有数据）
            ingredients = product.get("ingredients", "").lower()
            if any(keyword in ingredients for keyword in ["iron", "calcium", "铁", "钙"]):
                base_score += 0.05
        
        return max(0.0, min(1.0, base_score))
    
    def _calculate_bmr(self, user_profile: Dict) -> float:
        """计算基础代谢率（BMR）"""
        age = user_profile.get("age") or 30
        gender = user_profile.get("gender") or "male"
        height_cm = user_profile.get("height_cm") or 170
        weight_kg = user_profile.get("weight_kg") or 70
        
        # 确保所有值都是数字
        try:
            age = float(age) if age is not None else 30.0
            height_cm = float(height_cm) if height_cm is not None else 170.0
            weight_kg = float(weight_kg) if weight_kg is not None else 70.0
        except (TypeError, ValueError):
            age, height_cm, weight_kg = 30.0, 170.0, 70.0
        
        if gender == "male":
            # Mifflin-St Jeor方程（男性）
            bmr = 10 * weight_kg + 6.25 * height_cm - 5 * age + 5
        else:
            # Mifflin-St Jeor方程（女性）
            bmr = 10 * weight_kg + 6.25 * height_cm - 5 * age - 161
        
        return max(0.0, bmr)
    
    def get_optimizer_stats(self) -> Dict:
        """获取优化器配置统计"""
        return {
            "supported_goals": list(self.strategies.keys()),
            "strategy_count": len(self.strategies),
            "validation_ranges": self.validation_ranges,
            "features": [
                "多营养目标支持",
                "个性化权重调整", 
                "营养密度计算",
                "健康影响评估",
                "改善度量分析"
            ]
        }