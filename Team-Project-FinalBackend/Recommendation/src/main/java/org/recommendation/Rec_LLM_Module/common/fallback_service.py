"""
降级服务提供器
当AI服务不可用时提供基于规则的推荐和基础功能
"""

import time
import logging
from typing import Dict, List, Optional, Any
from dataclasses import dataclass
from datetime import datetime
import json

logger = logging.getLogger(__name__)

@dataclass
class FallbackRecommendation:
    """降级推荐结果"""
    product_barcode: str
    product_name: str
    reason: str
    confidence: float
    nutrition_score: Optional[float] = None
    category: Optional[str] = None

class RuleBasedRecommender:
    """基于规则的推荐器"""
    
    def __init__(self):
        # 营养评分规则
        self.nutrition_rules = {
            "high_protein": {
                "criteria": {"proteins_100g": ">= 15"},
                "score_bonus": 0.2,
                "description": "高蛋白质食品"
            },
            "low_fat": {
                "criteria": {"fat_100g": "<= 3"},
                "score_bonus": 0.15,
                "description": "低脂肪食品"
            },
            "low_sugar": {
                "criteria": {"sugars_100g": "<= 5"},
                "score_bonus": 0.15,
                "description": "低糖食品"
            },
            "high_fiber": {
                "criteria": {"fiber_100g": ">= 5"},
                "score_bonus": 0.1,
                "description": "高纤维食品"
            },
            "low_sodium": {
                "criteria": {"sodium_100g": "<= 120"},
                "score_bonus": 0.1,
                "description": "低钠食品"
            }
        }
        
        # 分类替代规则
        self.category_substitutes = {
            "dairy": {
                "healthier_options": ["low_fat_dairy", "plant_based_alternatives"],
                "avoid": ["high_fat_dairy", "flavored_dairy"]
            },
            "snacks": {
                "healthier_options": ["nuts", "fruits", "whole_grain_snacks"],
                "avoid": ["fried_snacks", "candy", "high_sugar_snacks"]
            },
            "beverages": {
                "healthier_options": ["water", "unsweetened_tea", "low_sugar_drinks"],
                "avoid": ["soft_drinks", "energy_drinks", "high_sugar_juices"]
            },
            "grains": {
                "healthier_options": ["whole_grains", "brown_rice", "quinoa"],
                "avoid": ["refined_grains", "white_bread", "instant_noodles"]
            },
            "proteins": {
                "healthier_options": ["lean_meat", "fish", "legumes", "tofu"],
                "avoid": ["processed_meat", "fried_meat", "high_fat_meat"]
            }
        }
        
        # 健康目标映射
        self.health_goal_preferences = {
            "lose_weight": {
                "prioritize": ["low_calorie", "high_fiber", "low_fat"],
                "avoid": ["high_calorie", "high_sugar", "fried_foods"],
                "score_multiplier": {"energy_kcal_100g": -0.5, "proteins_100g": 0.3, "fiber_100g": 0.4}
            },
            "gain_muscle": {
                "prioritize": ["high_protein", "complex_carbs", "moderate_fat"],
                "avoid": ["low_protein", "empty_calories"],
                "score_multiplier": {"proteins_100g": 0.5, "carbohydrates_100g": 0.2, "energy_kcal_100g": 0.1}
            },
            "maintain": {
                "prioritize": ["balanced_nutrition", "natural_foods", "variety"],
                "avoid": ["highly_processed", "artificial_additives"],
                "score_multiplier": {"proteins_100g": 0.2, "fiber_100g": 0.2, "fat_100g": -0.1}
            }
        }
    
    def recommend_by_barcode(self, user_id: int, barcode: str, 
                           user_preferences: Optional[Dict] = None) -> List[FallbackRecommendation]:
        """基于条码的降级推荐"""
        try:
            # 模拟从数据库获取商品信息
            product_info = self._get_product_info(barcode)
            if not product_info:
                return self._get_generic_recommendations(user_preferences)
            
            # 分析商品类型
            category = self._classify_product(product_info)
            
            # 获取用户健康目标
            health_goal = user_preferences.get("healthGoal", "maintain") if user_preferences else "maintain"
            
            # 基于规则生成推荐
            recommendations = []
            
            # 分析当前商品的营养问题
            nutrition_issues = self._analyze_nutrition_issues(product_info, health_goal)
            
            # 根据问题生成替代建议
            for issue in nutrition_issues:
                alternatives = self._find_alternatives(category, issue, health_goal)
                recommendations.extend(alternatives)
            
            # 如果没有发现问题，提供通用健康建议
            if not recommendations:
                recommendations = self._get_general_healthy_alternatives(category, health_goal)
            
            # 限制推荐数量
            return recommendations[:3]
            
        except Exception as e:
            logger.error(f"基于规则推荐失败: {e}")
            return self._get_emergency_recommendations()
    
    def recommend_for_receipt(self, user_id: int, purchased_items: List[Dict],
                            user_preferences: Optional[Dict] = None) -> List[FallbackRecommendation]:
        """基于小票的降级推荐"""
        try:
            # 分析购买模式
            purchase_analysis = self._analyze_purchase_pattern(purchased_items)
            
            # 获取用户健康目标
            health_goal = user_preferences.get("healthGoal", "maintain") if user_preferences else "maintain"
            
            recommendations = []
            
            # 基于缺失营养素推荐
            missing_nutrients = self._identify_missing_nutrients(purchase_analysis, health_goal)
            for nutrient in missing_nutrients:
                nutrient_recs = self._recommend_for_nutrient(nutrient, health_goal)
                recommendations.extend(nutrient_recs)
            
            # 基于不健康项目推荐替代品
            unhealthy_items = self._identify_unhealthy_purchases(purchased_items, health_goal)
            for item in unhealthy_items:
                alternatives = self._suggest_healthier_alternatives(item, health_goal)
                recommendations.extend(alternatives)
            
            return recommendations[:5]
            
        except Exception as e:
            logger.error(f"小票分析推荐失败: {e}")
            return self._get_emergency_recommendations()
    
    def _get_product_info(self, barcode: str) -> Optional[Dict]:
        """获取商品信息（模拟）"""
        # 这里应该连接到实际的产品数据库
        # 现在返回模拟数据
        mock_products = {
            "1234567890123": {
                "name": "某品牌薯片",
                "category": "snacks",
                "nutrition": {
                    "energy_kcal_100g": 536,
                    "fat_100g": 34,
                    "carbohydrates_100g": 53,
                    "proteins_100g": 6,
                    "fiber_100g": 4,
                    "sodium_100g": 1200,
                    "sugars_100g": 3
                }
            }
        }
        return mock_products.get(barcode)
    
    def _classify_product(self, product_info: Dict) -> str:
        """分类商品"""
        category = product_info.get("category", "unknown")
        
        # 基于营养成分进一步分类
        nutrition = product_info.get("nutrition", {})
        
        if nutrition.get("fat_100g", 0) > 20:
            return f"{category}_high_fat"
        elif nutrition.get("sugars_100g", 0) > 15:
            return f"{category}_high_sugar"
        elif nutrition.get("proteins_100g", 0) > 15:
            return f"{category}_high_protein"
        
        return category
    
    def _analyze_nutrition_issues(self, product_info: Dict, health_goal: str) -> List[str]:
        """分析营养问题"""
        issues = []
        nutrition = product_info.get("nutrition", {})
        preferences = self.health_goal_preferences.get(health_goal, {})
        
        # 检查高热量
        if nutrition.get("energy_kcal_100g", 0) > 400 and health_goal == "lose_weight":
            issues.append("high_calorie")
        
        # 检查高脂肪
        if nutrition.get("fat_100g", 0) > 15:
            issues.append("high_fat")
        
        # 检查高糖
        if nutrition.get("sugars_100g", 0) > 10:
            issues.append("high_sugar")
        
        # 检查高钠
        if nutrition.get("sodium_100g", 0) > 600:
            issues.append("high_sodium")
        
        # 检查低蛋白质（针对增肌目标）
        if nutrition.get("proteins_100g", 0) < 5 and health_goal == "gain_muscle":
            issues.append("low_protein")
        
        return issues
    
    def _find_alternatives(self, category: str, issue: str, health_goal: str) -> List[FallbackRecommendation]:
        """查找替代品"""
        alternatives = []
        
        # 基于问题类型的替代品数据库（模拟）
        alternative_db = {
            "high_calorie": [
                {"barcode": "9876543210123", "name": "低卡路里饼干", "reason": "热量减少60%"},
                {"barcode": "5432109876543", "name": "蔬菜脆片", "reason": "天然低热量零食"}
            ],
            "high_fat": [
                {"barcode": "1111222233334", "name": "烘焙坚果", "reason": "健康脂肪来源"},
                {"barcode": "4444555566667", "name": "低脂酸奶", "reason": "脂肪含量<3%"}
            ],
            "high_sugar": [
                {"barcode": "7777888899990", "name": "无糖燕麦棒", "reason": "无添加糖"},
                {"barcode": "1010202030304", "name": "新鲜水果干", "reason": "天然果糖"}
            ],
            "high_sodium": [
                {"barcode": "5050606070708", "name": "低钠全麦饼干", "reason": "钠含量降低70%"},
                {"barcode": "9090101020304", "name": "天然坚果", "reason": "无添加盐"}
            ]
        }
        
        issue_alternatives = alternative_db.get(issue, [])
        for alt in issue_alternatives[:2]:  # 每个问题最多2个替代品
            alternatives.append(FallbackRecommendation(
                product_barcode=alt["barcode"],
                product_name=alt["name"],
                reason=alt["reason"],
                confidence=0.7,
                category=category
            ))
        
        return alternatives
    
    def _get_general_healthy_alternatives(self, category: str, health_goal: str) -> List[FallbackRecommendation]:
        """获取通用健康替代品"""
        healthy_options = {
            "snacks": [
                {"barcode": "2020303040405", "name": "混合坚果", "reason": "富含健康脂肪和蛋白质"},
                {"barcode": "6060707080809", "name": "全谷物饼干", "reason": "高纤维，提供持久能量"}
            ],
            "beverages": [
                {"barcode": "3030404050506", "name": "无糖气泡水", "reason": "零热量，解渴清爽"},
                {"barcode": "7070808090901", "name": "绿茶", "reason": "富含抗氧化物"}
            ],
            "dairy": [
                {"barcode": "4040505060607", "name": "希腊酸奶", "reason": "高蛋白质，有益肠道健康"},
                {"barcode": "8080909010102", "name": "低脂牛奶", "reason": "钙质丰富，脂肪含量低"}
            ]
        }
        
        options = healthy_options.get(category, healthy_options["snacks"])
        return [
            FallbackRecommendation(
                product_barcode=opt["barcode"],
                product_name=opt["name"],
                reason=opt["reason"],
                confidence=0.6,
                category=category
            )
            for opt in options
        ]
    
    def _analyze_purchase_pattern(self, purchased_items: List[Dict]) -> Dict:
        """分析购买模式"""
        analysis = {
            "total_items": len(purchased_items),
            "categories": {},
            "nutrition_totals": {
                "energy_kcal": 0,
                "proteins": 0,
                "fat": 0,
                "carbohydrates": 0,
                "fiber": 0,
                "sodium": 0
            },
            "health_score": 0.0
        }
        
        for item in purchased_items:
            # 这里应该查询实际的商品数据
            # 现在使用模拟数据
            category = "unknown"
            analysis["categories"][category] = analysis["categories"].get(category, 0) + 1
        
        return analysis
    
    def _identify_missing_nutrients(self, purchase_analysis: Dict, health_goal: str) -> List[str]:
        """识别缺失的营养素"""
        missing = []
        
        # 基于健康目标检查营养素
        if health_goal == "gain_muscle":
            if purchase_analysis["nutrition_totals"]["proteins"] < 50:  # 假设阈值
                missing.append("protein")
        
        if health_goal == "lose_weight":
            if purchase_analysis["nutrition_totals"]["fiber"] < 25:
                missing.append("fiber")
        
        # 通用营养素检查
        if purchase_analysis["categories"].get("vegetables", 0) < 2:
            missing.append("vegetables")
        
        if purchase_analysis["categories"].get("fruits", 0) < 2:
            missing.append("fruits")
        
        return missing
    
    def _recommend_for_nutrient(self, nutrient: str, health_goal: str) -> List[FallbackRecommendation]:
        """为特定营养素推荐食品"""
        nutrient_foods = {
            "protein": [
                {"barcode": "1212343456567", "name": "鸡胸肉", "reason": "优质蛋白质来源"},
                {"barcode": "2323454567678", "name": "豆腐", "reason": "植物蛋白，易消化"}
            ],
            "fiber": [
                {"barcode": "3434565678789", "name": "燕麦片", "reason": "高纤维，有助消化"},
                {"barcode": "4545676789890", "name": "苹果", "reason": "天然纤维，维生素丰富"}
            ],
            "vegetables": [
                {"barcode": "5656787890901", "name": "西兰花", "reason": "营养密度高的绿色蔬菜"},
                {"barcode": "6767898901012", "name": "胡萝卜", "reason": "富含β-胡萝卜素"}
            ],
            "fruits": [
                {"barcode": "7878909012123", "name": "蓝莓", "reason": "抗氧化物丰富"},
                {"barcode": "8989010123234", "name": "香蕉", "reason": "钾含量高，能量补充"}
            ]
        }
        
        foods = nutrient_foods.get(nutrient, [])
        return [
            FallbackRecommendation(
                product_barcode=food["barcode"],
                product_name=food["name"],
                reason=food["reason"],
                confidence=0.8,
                category=nutrient
            )
            for food in foods
        ]
    
    def _identify_unhealthy_purchases(self, purchased_items: List[Dict], health_goal: str) -> List[Dict]:
        """识别不健康的购买项目"""
        unhealthy = []
        
        for item in purchased_items:
            # 这里应该查询实际的商品营养数据
            # 现在基于简单规则判断
            barcode = item.get("barcode", "")
            
            # 模拟不健康商品检测
            if any(keyword in barcode for keyword in ["candy", "soda", "chips"]):
                unhealthy.append(item)
        
        return unhealthy
    
    def _suggest_healthier_alternatives(self, item: Dict, health_goal: str) -> List[FallbackRecommendation]:
        """为不健康商品建议替代品"""
        # 简化的替代品建议
        return [
            FallbackRecommendation(
                product_barcode="health_alt_001",
                product_name="健康替代品",
                reason="更健康的选择",
                confidence=0.6,
                category="alternative"
            )
        ]
    
    def _get_generic_recommendations(self, user_preferences: Optional[Dict] = None) -> List[FallbackRecommendation]:
        """获取通用推荐"""
        return [
            FallbackRecommendation(
                product_barcode="generic_001",
                product_name="新鲜蔬菜",
                reason="营养丰富，维生素充足",
                confidence=0.8,
                category="vegetables"
            ),
            FallbackRecommendation(
                product_barcode="generic_002",
                product_name="全谷物产品",
                reason="提供持久能量，富含纤维",
                confidence=0.8,
                category="grains"
            ),
            FallbackRecommendation(
                product_barcode="generic_003",
                product_name="瘦肉蛋白",
                reason="优质蛋白质来源",
                confidence=0.7,
                category="proteins"
            )
        ]
    
    def _get_emergency_recommendations(self) -> List[FallbackRecommendation]:
        """紧急情况下的推荐"""
        return [
            FallbackRecommendation(
                product_barcode="emergency_001",
                product_name="均衡饮食建议",
                reason="建议咨询营养师获取个性化建议",
                confidence=0.5,
                category="general"
            )
        ]

class FallbackService:
    """降级服务提供器"""
    
    def __init__(self):
        self.rule_based_recommender = RuleBasedRecommender()
        self.static_responses = self._load_static_responses()
        
    def _load_static_responses(self) -> Dict[str, Dict]:
        """加载静态响应模板"""
        return {
            "barcode_recommendation": {
                "message": "基于营养数据的推荐结果（简化版）",
                "suggestions": [
                    "查看商品营养成分标签",
                    "对比推荐商品的营养价值",
                    "考虑个人健康目标"
                ]
            },
            "receipt_analysis": {
                "message": "基础营养分析结果（简化版）",
                "suggestions": [
                    "查看各商品详情",
                    "手动对比营养成分",
                    "关注均衡饮食搭配"
                ]
            },
            "general_health": {
                "message": "通用健康建议",
                "suggestions": [
                    "保持饮食多样化",
                    "增加蔬菜水果摄入",
                    "减少加工食品消费",
                    "注意适量运动"
                ]
            }
        }
    
    def get_barcode_fallback_recommendation(self, user_id: int, barcode: str, 
                                         user_preferences: Optional[Dict] = None) -> Dict[str, Any]:
        """条码推荐降级服务"""
        try:
            # 基于规则的推荐
            recommendations = self.rule_based_recommender.recommend_by_barcode(
                user_id, barcode, user_preferences
            )
            
            # 转换为API响应格式
            recommendation_data = []
            for rec in recommendations:
                recommendation_data.append({
                    "productBarcode": rec.product_barcode,
                    "productName": rec.product_name,
                    "recommendationReason": rec.reason,
                    "confidence": rec.confidence,
                    "category": rec.category,
                    "nutritionScore": rec.nutrition_score
                })
            
            return {
                "success": True,
                "message": self.static_responses["barcode_recommendation"]["message"],
                "data": {
                    "recommendationId": f"fallback_{int(time.time())}",
                    "scanType": "barcode_scan",
                    "scannedProduct": {
                        "barcode": barcode,
                        "analysisAvailable": False
                    },
                    "recommendations": recommendation_data,
                    "llmAnalysis": {
                        "summary": "AI分析服务暂时不可用，以下是基于营养数据的推荐结果。",
                        "healthAnalysis": "建议关注商品的营养成分标签，选择低糖、低盐、高纤维的健康选择。",
                        "actionSuggestions": self.static_responses["barcode_recommendation"]["suggestions"]
                    },
                    "fallbackMode": True,
                    "timestamp": datetime.now().isoformat()
                }
            }
            
        except Exception as e:
            logger.error(f"条码降级服务失败: {e}")
            return self._get_static_fallback_response("barcode_recommendation")
    
    def get_receipt_fallback_analysis(self, user_id: int, purchased_items: List[Dict],
                                    user_preferences: Optional[Dict] = None) -> Dict[str, Any]:
        """小票分析降级服务"""
        try:
            # 基础营养统计
            total_items = len(purchased_items)
            nutrition_summary = self._calculate_basic_nutrition(purchased_items)
            
            # 基于规则的推荐
            recommendations = self.rule_based_recommender.recommend_for_receipt(
                user_id, purchased_items, user_preferences
            )
            
            # 转换推荐格式
            recommendation_data = []
            for rec in recommendations:
                recommendation_data.append({
                    "productBarcode": rec.product_barcode,
                    "productName": rec.product_name,
                    "recommendationReason": rec.reason,
                    "confidence": rec.confidence,
                    "category": rec.category
                })
            
            return {
                "success": True,
                "message": self.static_responses["receipt_analysis"]["message"],
                "data": {
                    "recommendationId": f"fallback_receipt_{int(time.time())}",
                    "scanType": "receipt_scan",
                    "purchaseSummary": {
                        "totalItems": total_items,
                        "nutritionSummary": nutrition_summary,
                        "categories": self._categorize_purchases(purchased_items)
                    },
                    "recommendations": recommendation_data,
                    "llmAnalysis": {
                        "summary": "AI分析服务暂时不可用，已为您提供基础营养统计信息。",
                        "nutritionalInsights": self._generate_basic_insights(nutrition_summary),
                        "actionSuggestions": self.static_responses["receipt_analysis"]["suggestions"]
                    },
                    "fallbackMode": True,
                    "timestamp": datetime.now().isoformat()
                }
            }
            
        except Exception as e:
            logger.error(f"小票降级服务失败: {e}")
            return self._get_static_fallback_response("receipt_analysis")
    
    def _calculate_basic_nutrition(self, purchased_items: List[Dict]) -> Dict[str, Any]:
        """计算基础营养统计"""
        summary = {
            "estimatedCalories": 0,
            "itemsAnalyzed": 0,
            "healthyItemsCount": 0,
            "concerns": []
        }
        
        # 这里应该连接实际的营养数据库
        # 现在使用估算值
        for item in purchased_items:
            quantity = item.get("quantity", 1)
            summary["estimatedCalories"] += quantity * 200  # 估算值
            summary["itemsAnalyzed"] += 1
            
            # 简单的健康评估
            barcode = item.get("barcode", "")
            if any(healthy_keyword in barcode.lower() for healthy_keyword in ["vegetable", "fruit", "whole"]):
                summary["healthyItemsCount"] += 1
        
        # 生成关注点
        if summary["healthyItemsCount"] < summary["itemsAnalyzed"] * 0.3:
            summary["concerns"].append("建议增加蔬菜水果的比例")
        
        if summary["estimatedCalories"] > summary["itemsAnalyzed"] * 300:
            summary["concerns"].append("注意控制高热量食品的摄入")
        
        return summary
    
    def _categorize_purchases(self, purchased_items: List[Dict]) -> Dict[str, int]:
        """分类购买商品"""
        categories = {
            "蔬菜水果": 0,
            "蛋白质": 0,
            "谷物": 0,
            "零食": 0,
            "饮料": 0,
            "其他": 0
        }
        
        # 简化的分类逻辑
        for item in purchased_items:
            barcode = item.get("barcode", "").lower()
            quantity = item.get("quantity", 1)
            
            if any(keyword in barcode for keyword in ["vegetable", "fruit"]):
                categories["蔬菜水果"] += quantity
            elif any(keyword in barcode for keyword in ["meat", "fish", "protein"]):
                categories["蛋白质"] += quantity
            elif any(keyword in barcode for keyword in ["grain", "bread", "rice"]):
                categories["谷物"] += quantity
            elif any(keyword in barcode for keyword in ["snack", "chip", "candy"]):
                categories["零食"] += quantity
            elif any(keyword in barcode for keyword in ["drink", "juice", "soda"]):
                categories["饮料"] += quantity
            else:
                categories["其他"] += quantity
        
        return categories
    
    def _generate_basic_insights(self, nutrition_summary: Dict[str, Any]) -> List[str]:
        """生成基础营养洞察"""
        insights = []
        
        if nutrition_summary["healthyItemsCount"] > nutrition_summary["itemsAnalyzed"] * 0.5:
            insights.append("您的购物选择整体较为健康，继续保持！")
        else:
            insights.append("建议增加更多天然、未加工的食品。")
        
        if nutrition_summary["estimatedCalories"] > 2000:
            insights.append("注意控制总热量摄入，保持适量。")
        
        insights.extend(nutrition_summary.get("concerns", []))
        
        return insights
    
    def _get_static_fallback_response(self, response_type: str) -> Dict[str, Any]:
        """获取静态降级响应"""
        response_template = self.static_responses.get(response_type, self.static_responses["general_health"])
        
        return {
            "success": False,
            "message": "服务暂时不可用",
            "data": {
                "recommendationId": f"static_fallback_{int(time.time())}",
                "fallbackMode": True,
                "staticResponse": True,
                "message": response_template["message"],
                "suggestions": response_template["suggestions"],
                "timestamp": datetime.now().isoformat()
            }
        }

# 全局降级服务实例
_global_fallback_service = None

def get_fallback_service() -> FallbackService:
    """获取全局降级服务实例"""
    global _global_fallback_service
    if _global_fallback_service is None:
        _global_fallback_service = FallbackService()
    return _global_fallback_service

# 便捷函数
def get_fallback_barcode_recommendation(user_id: int, barcode: str, 
                                      user_preferences: Optional[Dict] = None) -> Dict[str, Any]:
    """便捷的条码降级推荐函数"""
    fallback_service = get_fallback_service()
    return fallback_service.get_barcode_fallback_recommendation(user_id, barcode, user_preferences)

def get_fallback_receipt_analysis(user_id: int, purchased_items: List[Dict],
                                user_preferences: Optional[Dict] = None) -> Dict[str, Any]:
    """便捷的小票降级分析函数"""
    fallback_service = get_fallback_service()
    return fallback_service.get_receipt_fallback_analysis(user_id, purchased_items, user_preferences)