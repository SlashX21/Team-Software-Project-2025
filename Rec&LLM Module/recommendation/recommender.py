"""
推荐引擎主控制器
整合多层过滤、营养优化、协同过滤和LLM分析的完整推荐系统
"""

import asyncio
import logging
import time
from typing import Dict, List, Optional, Tuple, Any
from datetime import datetime
from dataclasses import dataclass, field
import json

from database.db_manager import DatabaseManager
from recommendation.filters import HardFilters
from recommendation.nutrition_optimizer import NutritionOptimizer
from llm_evaluation.openai_client import OpenAIClient, get_openai_client
from llm_evaluation.prompt_templates import (
    PromptTemplateManager, get_template_manager, 
    generate_barcode_prompt, generate_receipt_prompt
)
from config.settings import get_recommendation_config
from config.constants import (
    RecommendationType, NutritionGoal, API_RESPONSE_TEMPLATE,
    PERFORMANCE_METRICS
)

logger = logging.getLogger(__name__)

@dataclass
class RecommendationRequest:
    """推荐请求基类"""
    user_id: int
    request_type: str = field(init=False)
    product_barcode: Optional[str] = None  # 新增，条形码请求用
    purchased_items: Optional[List[Dict]] = None  # 新增，小票分析用
    scan_context: Optional[Dict] = None
    receipt_context: Optional[Dict] = None
    max_recommendations: int = 5

@dataclass
class BarcodeRecommendationRequest(RecommendationRequest):
    """条形码扫描推荐请求"""
    def __post_init__(self):
        self.request_type = RecommendationType.BARCODE_SCAN.value

@dataclass
class ReceiptRecommendationRequest(RecommendationRequest):
    """小票分析推荐请求"""
    def __post_init__(self):
        self.request_type = RecommendationType.RECEIPT_ANALYSIS.value

@dataclass
class RecommendationResult:
    """单个推荐结果"""
    rank: int
    product: Dict
    recommendation_score: float
    nutrition_improvement: Dict
    safety_check: Dict
    reasoning: str

@dataclass
class RecommendationResponse:
    """推荐响应类"""
    recommendation_id: str
    scan_type: str
    user_profile_summary: Dict
    recommendations: List[RecommendationResult]
    llm_analysis: Dict
    processing_metadata: Dict
    success: bool = True
    message: str = "推荐成功"
    error: Optional[str] = None
    timestamp: str = field(default_factory=lambda: datetime.now().isoformat())

    def to_dict(self) -> Dict:
        """转换为字典格式"""
        return {
            "recommendation_id": self.recommendation_id,
            "scan_type": self.scan_type,
            "user_profile_summary": self.user_profile_summary,
            "recommendations": [
                {
                    "rank": rec.rank,
                    "product": rec.product,
                    "recommendation_score": rec.recommendation_score,
                    "nutrition_improvement": rec.nutrition_improvement,
                    "safety_check": rec.safety_check,
                    "reasoning": rec.reasoning
                }
                for rec in self.recommendations
            ],
            "llm_analysis": self.llm_analysis,
            "processing_metadata": self.processing_metadata,
            "success": self.success,
            "message": self.message,
            "error": self.error,
            "timestamp": self.timestamp
        }

class CollaborativeFilter:
    """协同过滤算法"""
    
    def __init__(self, db_manager: DatabaseManager):
        self.db = db_manager
        self.min_interactions = 3
        self.similarity_threshold = 0.6
        
    def predict_user_preferences(self, user_id: int, 
                                candidate_products: List[str]) -> Dict[str, float]:
        """
        预测用户对候选商品的偏好度
        Args:
            user_id: 目标用户ID
            candidate_products: 候选商品条形码列表
        Returns:
            商品条形码 -> 偏好分数的映射
        """
        try:
            # 获取用户购买矩阵
            user_matrix = self.db.get_user_purchase_matrix(user_id)
            similar_users = user_matrix.get("similar_users", [])
            
            if not similar_users:
                # 没有相似用户，返回默认分数
                return {barcode: 0.5 for barcode in candidate_products}
            
            preferences = {}
            
            for barcode in candidate_products:
                preference_score = self._calculate_collaborative_score(
                    user_id, barcode, similar_users)
                preferences[barcode] = preference_score
            
            return preferences
            
        except Exception as e:
            logger.error(f"协同过滤预测失败 {user_id}: {e}")
            return {barcode: 0.5 for barcode in candidate_products}
    
    def _calculate_collaborative_score(self, user_id: int, barcode: str, 
                                    similar_users: List[Dict]) -> float:
        """计算协同过滤评分"""
        if not similar_users:
            return 0.5
        
        total_score = 0.0
        total_weight = 0.0
        
        for similar_user in similar_users[:10]:  # 最多考虑10个相似用户
            similarity_score = similar_user.get("common_products", 0) / 10.0  # 归一化
            similarity_weight = min(1.0, similarity_score)
            
            # 检查相似用户是否购买过该商品
            user_purchase_score = self._get_user_product_score(
                similar_user["user_id"], barcode)
            
            if user_purchase_score > 0:
                total_score += user_purchase_score * similarity_weight
                total_weight += similarity_weight
        
        if total_weight > 0:
            return min(1.0, total_score / total_weight)
        else:
            return 0.5
    
    def _get_user_product_score(self, user_id: int, barcode: str) -> float:
        """获取用户对特定商品的购买评分"""
        try:
            # 简化实现：基于购买频率计算评分
            purchase_history = self.db.get_purchase_history(user_id, days=180)
            
            purchase_count = 0
            total_quantity = 0
            
            for record in purchase_history:
                if record.get("barcode") == barcode:
                    purchase_count += 1
                    total_quantity += record.get("quantity", 1)
            
            if purchase_count == 0:
                return 0.0
            
            # 购买频率和数量的综合评分
            frequency_score = min(1.0, purchase_count / 5.0)  # 5次购买为满分
            quantity_score = min(1.0, total_quantity / 10.0)  # 10个总量为满分
            
            return (frequency_score + quantity_score) / 2.0
            
        except Exception as e:
            logger.error(f"获取用户商品评分失败 {user_id}-{barcode}: {e}")
            return 0.0

class RecommendationEngine:
    """推荐引擎主控制器"""
    
    def __init__(self, db_manager: Optional[DatabaseManager] = None,
                 llm_client: Optional[OpenAIClient] = None):
        
        self.db = db_manager or DatabaseManager()
        self.llm = llm_client or get_openai_client()
        self.template_manager = get_template_manager()
        self.config = get_recommendation_config()
        
        # 初始化核心组件
        self.hard_filters = HardFilters()
        self.nutrition_optimizer = NutritionOptimizer()
        self.collaborative_filter = CollaborativeFilter(self.db)
        
        # 性能统计
        self.performance_stats = {
            "total_requests": 0,
            "successful_requests": 0,
            "failed_requests": 0,
            "average_response_time_ms": 0.0,
            "response_times": []
        }
        
    async def recommend_alternatives(self, 
                                   request: BarcodeRecommendationRequest) -> RecommendationResponse:
        """
        条形码扫描推荐主流程
        Args:
            request: 条形码推荐请求
        Returns:
            完整的推荐响应
        """
        start_time = time.time()
        recommendation_id = self._generate_recommendation_id()
        
        try:
            logger.info(f"开始处理条形码推荐请求: {request.product_barcode}")
            
            # 确保数据库连接
            if not self.db.adapter.connection:
                self.db.connect()
            
            # 1. 数据获取和验证
            original_product, user_profile, user_allergens = await self._load_basic_data(
                request.product_barcode, request.user_id)
            
            if not original_product:
                return self._create_error_response(
                    recommendation_id, "商品信息未找到", 
                    f"未找到条形码为 {request.product_barcode} 的商品信息")
            
            if not user_profile:
                return self._create_error_response(
                    recommendation_id, "用户信息未找到", 
                    f"未找到用户ID为 {request.user_id} 的用户信息")
            
            # 2. 执行推荐算法
            recommendations = await self._execute_barcode_recommendation_pipeline(
                original_product, user_profile, user_allergens, request)
            
            # 3. 生成LLM分析
            llm_analysis = await self._generate_llm_analysis(
                user_profile, original_product, recommendations, None)
            
            # 4. 构建完整响应
            processing_time_ms = int((time.time() - start_time) * 1000)
            response = self._build_barcode_recommendation_response(
                recommendation_id, original_product, recommendations, 
                llm_analysis, user_profile, processing_time_ms)
            
            # 5. 记录日志和统计
            await self._log_recommendation_request(request, response, processing_time_ms)
            self._update_performance_stats(processing_time_ms, success=True)
            
            logger.info(f"条形码推荐完成: {recommendation_id}, 耗时: {processing_time_ms}ms")
            return response
            
        except Exception as e:
            processing_time_ms = int((time.time() - start_time) * 1000)
            self._update_performance_stats(processing_time_ms, success=False)
            
            logger.error(f"条形码推荐失败: {e}")
            return self._create_error_response(
                recommendation_id, "推荐生成失败", str(e))
    
    async def analyze_receipt_recommendations(self, request: ReceiptRecommendationRequest) -> Dict:
        """小票分析推荐主流程"""
        start_time = time.time()
        recommendation_id = self._generate_recommendation_id()
        
        try:
            logger.info(f"开始处理小票分析请求: {len(request.purchased_items)}个商品")
            
            # 确保数据库连接
            if not self.db.adapter.connection:
                self.db.connect()
            
            # 1. 获取用户信息
            user_profile = self.db.get_user_profile(request.user_id)
            if not user_profile:
                return {
                    "success": False,
                    "error": "用户信息未找到",
                    "message": f"未找到用户ID为 {request.user_id} 的用户信息"
                }
            
            user_allergens = self.db.get_user_allergens(request.user_id)
            
            # 2. 批量获取购买商品信息
            purchased_products = await self._load_purchased_products(request.purchased_items)
            
            # 3. 逐商品推荐分析
            item_recommendations = await self._analyze_each_purchased_item(
                purchased_products, user_profile, user_allergens, request)
            
            # 4. 整体营养分析
            overall_nutrition = self._analyze_overall_nutrition(
                purchased_products, user_profile)
            
            # 5. 生成LLM综合分析
            llm_insights = await self._generate_receipt_insights(
                purchased_products, item_recommendations, overall_nutrition, user_profile)
            
            # 6. 构建小票分析响应
            processing_time_ms = int((time.time() - start_time) * 1000)
            
            response = {
                "recommendation_id": recommendation_id,
                "scan_type": "receipt_analysis",
                "user_profile_summary": self._create_user_profile_summary(user_profile),
                "purchased_items_count": len(purchased_products),
                "item_recommendations": item_recommendations,
                "overall_nutrition_analysis": overall_nutrition,
                "llm_insights": llm_insights,
                "processing_metadata": {
                    "algorithm_version": "v1.0",
                    "processing_time_ms": processing_time_ms,
                    "llm_tokens_used": llm_insights.get("tokens_used", 0),
                    "confidence_score": llm_insights.get("confidence_score", 0.7)
                },
                "success": True,
                "message": "小票分析完成",
                "timestamp": datetime.now().isoformat()
            }
            
            # 7. 记录日志和统计
            await self._log_recommendation_request(request, response, processing_time_ms)
            self._update_performance_stats(processing_time_ms, success=True)
            
            logger.info(f"小票分析完成: {recommendation_id}, 耗时: {processing_time_ms}ms")
            return response
            
        except Exception as e:
            processing_time_ms = int((time.time() - start_time) * 1000)
            self._update_performance_stats(processing_time_ms, success=False)
            
            logger.error(f"小票分析失败: {e}")
            return {
                "success": False,
                "error": str(e),
                "message": "小票分析失败"
            }
    
    async def _load_basic_data(self, barcode: str, user_id: int) -> Tuple[Optional[Dict], Optional[Dict], List[Dict]]:
        """加载基础数据：商品信息、用户画像、用户过敏原"""
        try:
            # 获取商品信息
            original_product = self.db.get_product_by_barcode(barcode)
            
            # 获取用户画像
            user_profile = self.db.get_user_profile(user_id)
            
            # 获取用户过敏原
            user_allergens = self.db.get_user_allergens(user_id)
            
            return original_product, user_profile, user_allergens
            
        except Exception as e:
            logger.error(f"加载基础数据失败: {e}")
            return None, None, []
    
    async def _execute_barcode_recommendation_pipeline(self, 
                                                     original_product: Dict,
                                                     user_profile: Dict,
                                                     user_allergens: List[Dict],
                                                     request: BarcodeRecommendationRequest) -> List[RecommendationResult]:
        """执行条形码推荐算法管道"""
        
        # 1. 获取同类候选商品
        category = original_product.get("category")
        candidates = self.db.get_products_by_category(category, limit=200)
        
        # 排除原商品本身
        candidates = [p for p in candidates if p.get("barcode") != original_product.get("barcode")]
        
        logger.info(f"获取到 {len(candidates)} 个同类候选商品")
        
        # 2. 硬过滤
        filter_context = {
            "user_allergens": user_allergens,
            "target_category": category,
            "strict_category_constraint": self.config.category_constraint
        }
        
        safe_products, filter_stats = self.hard_filters.apply_filters(candidates, filter_context)
        logger.info(f"硬过滤后剩余 {len(safe_products)} 个安全商品")
        
        if not safe_products:
            logger.warning("硬过滤后无可推荐商品")
            return []
        
        # 3. 营养优化评分
        nutrition_goal = user_profile.get("nutrition_goal", "maintain")
        scored_products = []
        
        for product in safe_products:
            nutrition_score = self.nutrition_optimizer.calculate_nutrition_score(
                product, nutrition_goal, user_profile)
            
            health_impact_score = self.nutrition_optimizer.calculate_health_impact_score(
                product, user_profile)
            
            # 营养改善度分析
            nutrition_improvement = self.nutrition_optimizer.compare_nutrition_improvement(
                original_product, product, nutrition_goal)
            
            scored_products.append({
                "product": product,
                "nutrition_score": nutrition_score,
                "health_impact_score": health_impact_score,
                "nutrition_improvement": nutrition_improvement,
                "combined_score": (nutrition_score + health_impact_score) / 2
            })
        
        # 按营养评分排序
        scored_products.sort(key=lambda x: x["combined_score"], reverse=True)
        
        # 4. 协同过滤增强
        candidate_barcodes = [sp["product"]["barcode"] for sp in scored_products[:20]]  # 取前20个进行协同过滤
        collaborative_scores = self.collaborative_filter.predict_user_preferences(
            request.user_id, candidate_barcodes)
        
        # 5. 综合评分和最终排序
        final_recommendations = []
        for scored_product in scored_products[:20]:
            barcode = scored_product["product"]["barcode"]
            collaborative_score = collaborative_scores.get(barcode, 0.5)
            
            # 综合评分（70%营养评分 + 30%协同过滤）
            final_score = (scored_product["combined_score"] * 0.7 + 
                          collaborative_score * 0.3)
            
            # 安全性检查
            safety_check = self.hard_filters.check_product_safety(
                scored_product["product"], user_allergens)
            
            recommendation = RecommendationResult(
                rank=0,  # 稍后设置
                product=scored_product["product"],
                recommendation_score=round(final_score, 3),
                nutrition_improvement=scored_product["nutrition_improvement"],
                safety_check=safety_check,
                reasoning=self._generate_recommendation_reasoning(scored_product, collaborative_score)
            )
            
            final_recommendations.append(recommendation)
        
        # 最终排序并设置排名
        final_recommendations.sort(key=lambda x: x.recommendation_score, reverse=True)
        
        # 取前N个推荐
        top_recommendations = final_recommendations[:request.max_recommendations]
        for i, rec in enumerate(top_recommendations, 1):
            rec.rank = i
        
        logger.info(f"生成 {len(top_recommendations)} 个最终推荐")
        return top_recommendations
    
    async def _load_purchased_products(self, purchased_items: List[Dict]) -> List[Dict]:
        """批量加载购买商品信息"""
        purchased_products = []
        
        for item in purchased_items:
            barcode = item.get("barcode")
            if barcode:
                product = self.db.get_product_by_barcode(barcode)
                if product:
                    # 合并购买信息和商品信息
                    combined_item = {**product, **item}
                    purchased_products.append(combined_item)
                else:
                    # 商品信息未找到，保留OCR信息
                    item["product_found"] = False
                    purchased_products.append(item)
            else:
                # 无条形码信息
                item["product_found"] = False
                purchased_products.append(item)
        
        return purchased_products
    
    async def _analyze_each_purchased_item(self, purchased_products: List[Dict],
                                         user_profile: Dict, user_allergens: List[Dict],
                                         request: ReceiptRecommendationRequest) -> List[Dict]:
        """分析每个购买商品并提供替代建议"""
        item_recommendations = []
        
        for item in purchased_products:
            if not item.get("product_found", True):
                # 商品信息未找到，跳过推荐
                item_recommendations.append({
                    "original_item": item,
                    "alternatives": [],
                    "reason": "商品信息未找到，无法提供推荐"
                })
                continue
            
            try:
                # 为每个商品生成推荐
                barcode_request = BarcodeRecommendationRequest(
                    user_id=request.user_id,
                    product_barcode=item.get("barcode"),
                    max_recommendations=3  # 每个商品推荐3个替代品
                )
                
                # 简化版推荐（避免递归调用）
                alternatives = await self._get_simple_alternatives(
                    item, user_profile, user_allergens)
                
                item_recommendations.append({
                    "original_item": item,
                    "alternatives": alternatives,
                    "nutrition_analysis": self._analyze_item_nutrition(item, user_profile)
                })
                
            except Exception as e:
                logger.error(f"分析商品推荐失败 {item.get('name', 'unknown')}: {e}")
                item_recommendations.append({
                    "original_item": item,
                    "alternatives": [],
                    "reason": f"推荐生成失败: {str(e)}"
                })
        
        return item_recommendations
    
    async def _get_simple_alternatives(self, item: Dict, user_profile: Dict, 
                                     user_allergens: List[Dict]) -> List[Dict]:
        """获取简化版商品替代建议"""
        category = item.get("category")
        if not category:
            return []
        
        # 获取同类商品
        candidates = self.db.get_products_by_category(category, limit=50)
        
        # 排除原商品
        original_barcode = item.get("barcode")
        candidates = [c for c in candidates if c.get("barcode") != original_barcode]
        
        if not candidates:
            return []
        
        # 简单过滤和评分
        nutrition_goal = user_profile.get("nutrition_goal", "maintain")
        scored_alternatives = []
        
        for candidate in candidates[:20]:  # 只处理前20个候选
            # 基础安全检查
            if user_allergens:
                safety_check = self.hard_filters.check_product_safety(candidate, user_allergens)
                if not safety_check.get("safe", False):
                    continue
            
            # 营养评分
            nutrition_score = self.nutrition_optimizer.calculate_nutrition_score(
                candidate, nutrition_goal, user_profile)
            
            # 营养改善度
            improvement = self.nutrition_optimizer.compare_nutrition_improvement(
                item, candidate, nutrition_goal)
            
            scored_alternatives.append({
                "product": candidate,
                "score": nutrition_score,
                "improvement": improvement
            })
        
        # 排序并返回前3个
        scored_alternatives.sort(key=lambda x: x["score"], reverse=True)
        return scored_alternatives[:3]
    
    def _analyze_overall_nutrition(self, purchased_products: List[Dict], 
                                 user_profile: Dict) -> Dict:
        """分析整体营养状况"""
        total_calories = 0
        total_protein = 0
        total_fat = 0
        total_carbs = 0
        total_sugar = 0
        
        valid_products = 0
        
        for item in purchased_products:
            if not item.get("product_found", True):
                continue
            
            quantity = item.get("quantity", 1)
            
            # 累计营养成分（假设每个商品约100g）
            calories = (item.get("energy_kcal_100g", 0) or 0) * quantity
            protein = (item.get("proteins_100g", 0) or 0) * quantity
            fat = (item.get("fat_100g", 0) or 0) * quantity
            carbs = (item.get("carbohydrates_100g", 0) or 0) * quantity
            sugar = (item.get("sugars_100g", 0) or 0) * quantity
            
            total_calories += calories
            total_protein += protein  
            total_fat += fat
            total_carbs += carbs
            total_sugar += sugar
            valid_products += 1
        
        # 计算与用户目标的匹配度
        daily_calories_target = user_profile.get("daily_calories_target", 2000)
        daily_protein_target = user_profile.get("daily_protein_target", 100)
        
        calorie_match = min(100, (total_calories / daily_calories_target) * 100) if daily_calories_target > 0 else 0
        protein_match = min(100, (total_protein / daily_protein_target) * 100) if daily_protein_target > 0 else 0
        
        overall_match = (calorie_match + protein_match) / 2
        
        return {
            "total_calories": round(total_calories, 1),
            "total_protein": round(total_protein, 1),
            "total_fat": round(total_fat, 1),
            "total_carbs": round(total_carbs, 1),
            "total_sugar": round(total_sugar, 1),
            "valid_products_count": valid_products,
            "calorie_target_percentage": round(calorie_match, 1),
            "protein_target_percentage": round(protein_match, 1),
            "overall_goal_alignment": round(overall_match, 1),
            "nutrition_balance": self._assess_nutrition_balance(total_protein, total_carbs, total_fat),
            "analysis_timestamp": datetime.now().isoformat()
        }
    
    def _assess_nutrition_balance(self, protein: float, carbs: float, fat: float) -> Dict:
        """评估营养平衡"""
        total = protein + carbs + fat
        if total == 0:
            return {"balanced": False, "note": "无有效营养数据"}
        
        protein_ratio = protein / total
        carbs_ratio = carbs / total
        fat_ratio = fat / total
        
        # 理想比例 (可调整)
        ideal_protein = 0.3
        ideal_carbs = 0.5
        ideal_fat = 0.2
        
        # 计算偏差
        protein_diff = abs(protein_ratio - ideal_protein)
        carbs_diff = abs(carbs_ratio - ideal_carbs)
        fat_diff = abs(fat_ratio - ideal_fat)
        
        avg_deviation = (protein_diff + carbs_diff + fat_diff) / 3
        
        balance_score = max(0, 1 - avg_deviation * 2)  # 转换为0-1分数
        
        return {
            "balanced": balance_score > 0.7,
            "balance_score": round(balance_score, 2),
            "protein_ratio": round(protein_ratio, 2),
            "carbs_ratio": round(carbs_ratio, 2),
            "fat_ratio": round(fat_ratio, 2),
            "recommendations": self._get_balance_recommendations(protein_ratio, carbs_ratio, fat_ratio)
        }
    
    def _get_balance_recommendations(self, protein_ratio: float, carbs_ratio: float, fat_ratio: float) -> List[str]:
        """获取营养平衡建议"""
        recommendations = []
        
        if protein_ratio < 0.2:
            recommendations.append("建议增加蛋白质摄入，如鱼类、瘦肉、豆类")
        elif protein_ratio > 0.4:
            recommendations.append("蛋白质摄入充足，可适当减少")
        
        if carbs_ratio < 0.4:
            recommendations.append("建议增加健康碳水化合物，如全谷物、蔬菜")
        elif carbs_ratio > 0.6:
            recommendations.append("碳水化合物摄入较高，建议选择低GI食物")
        
        if fat_ratio < 0.15:
            recommendations.append("建议增加健康脂肪，如坚果、橄榄油")
        elif fat_ratio > 0.3:
            recommendations.append("脂肪摄入较高，建议选择低脂食物")
        
        return recommendations
    
    def _analyze_item_nutrition(self, item: Dict, user_profile: Dict) -> Dict:
        """分析单个商品的营养状况"""
        nutrition_goal = user_profile.get("nutrition_goal", "maintain")
        
        analysis = {
            "suitable_for_goal": True,
            "concerns": [],
            "benefits": []
        }
        
        calories = item.get("energy_kcal_100g", 0)
        protein = item.get("proteins_100g", 0)
        fat = item.get("fat_100g", 0)
        sugar = item.get("sugars_100g", 0)
        
        if nutrition_goal == "lose_weight":
            if calories > 300:
                analysis["concerns"].append("热量较高，不利于减脂")
                analysis["suitable_for_goal"] = False
            if sugar > 15:
                analysis["concerns"].append("糖分含量高")
            if fat < 5:
                analysis["benefits"].append("低脂肪含量")
        
        elif nutrition_goal == "gain_muscle":
            if protein > 15:
                analysis["benefits"].append("高蛋白质含量，有助增肌")
            elif protein < 5:
                analysis["concerns"].append("蛋白质含量较低")
                analysis["suitable_for_goal"] = False
        
        return analysis
    
    async def _generate_llm_analysis(self, user_profile: Dict, original_product: Dict,
                                   recommendations: List[RecommendationResult],
                                   nutrition_comparison: Optional[Dict]) -> Dict:
        """生成LLM个性化分析"""
        try:
            # 准备推荐商品数据
            recommended_products = [rec.product for rec in recommendations]
            
            # 生成prompt
            prompt = generate_barcode_prompt(
                user_profile=user_profile,
                original_product=original_product,
                recommended_products=recommended_products,
                nutrition_comparison=nutrition_comparison
            )
            
            # 调用LLM
            llm_response = await self.llm.generate_completion(prompt, {
                "max_tokens": 800,
                "temperature": 0.7
            })
            
            if llm_response.success:
                # 解析LLM响应
                analysis_result = self._parse_llm_response(llm_response.content)
                analysis_result.update({
                    "tokens_used": llm_response.usage.get("total_tokens", 0),
                    "processing_time_ms": llm_response.processing_time_ms,
                    "model_used": llm_response.model,
                    "confidence_score": 0.8  # 基于响应质量评估
                })
                return analysis_result
            else:
                # LLM调用失败，使用降级响应
                return {
                    "summary": "基于营养数据为您推荐了更健康的替代选择",
                    "nutrition_analysis": "推荐商品在营养成分上有所改善",
                    "health_impact": "建议的替代品可能对您的健康目标有积极影响",
                    "action_suggestions": ["查看推荐商品的详细营养信息"],
                    "confidence_score": 0.3,
                    "fallback_used": True,
                    "error": llm_response.error
                }
                
        except Exception as e:
            logger.error(f"LLM分析生成失败: {e}")
            return {
                "summary": "AI分析暂时不可用",
                "nutrition_analysis": "请查看推荐商品的营养数据进行对比",
                "health_impact": "建议咨询营养师获取专业建议",
                "action_suggestions": ["查看推荐商品详情", "稍后重试"],
                "confidence_score": 0.1,
                "error": str(e)
            }
    
    async def _generate_receipt_insights(self, purchased_products: List[Dict],
                                       item_recommendations: List[Dict],
                                       overall_nutrition: Dict,
                                       user_profile: Dict) -> Dict:
        """生成小票分析的LLM洞察"""
        try:
            # 生成小票分析prompt
            prompt = generate_receipt_prompt(
                user_profile=user_profile,
                purchased_items=purchased_products
            )
            
            # 调用LLM
            llm_response = await self.llm.generate_completion(prompt, {
                "max_tokens": 1000,
                "temperature": 0.7
            })
            
            if llm_response.success:
                insights = self._parse_llm_response(llm_response.content)
                insights.update({
                    "tokens_used": llm_response.usage.get("total_tokens", 0),
                    "processing_time_ms": llm_response.processing_time_ms,
                    "model_used": llm_response.model,
                    "confidence_score": 0.8
                })
                return insights
            else:
                return {
                    "summary": "购买习惯分析暂时不可用",
                    "key_insights": ["请查看各商品的营养分析"],
                    "improvement_suggestions": ["考虑选择更健康的替代品"],
                    "confidence_score": 0.3,
                    "fallback_used": True,
                    "error": llm_response.error
                }
                
        except Exception as e:
            logger.error(f"小票洞察生成失败: {e}")
            return {
                "summary": "分析生成失败",
                "key_insights": [],
                "improvement_suggestions": [],
                "confidence_score": 0.1,
                "error": str(e)
            }
    
    def _parse_llm_response(self, response_content: str) -> Dict:
        """解析LLM响应内容"""
        try:
            # 简单的响应解析逻辑
            lines = response_content.strip().split('\n')
            
            parsed_response = {
                "summary": "",
                "nutrition_analysis": "",
                "health_impact": "",
                "action_suggestions": []
            }
            
            current_section = None
            current_content = []
            
            for line in lines:
                line = line.strip()
                if not line:
                    continue
                
                # 检测段落标题
                if any(keyword in line for keyword in ["推荐理由", "1.", "一、"]):
                    if current_section and current_content:
                        parsed_response[current_section] = "\n".join(current_content)
                    current_section = "summary"
                    current_content = [line]
                elif any(keyword in line for keyword in ["营养优势", "营养分析", "2.", "二、"]):
                    if current_section and current_content:
                        parsed_response[current_section] = "\n".join(current_content)
                    current_section = "nutrition_analysis"
                    current_content = [line]
                elif any(keyword in line for keyword in ["健康影响", "健康效益", "3.", "三、"]):
                    if current_section and current_content:
                        parsed_response[current_section] = "\n".join(current_content)
                    current_section = "health_impact"
                    current_content = [line]
                elif any(keyword in line for keyword in ["使用建议", "建议", "4.", "四、"]):
                    if current_section and current_content:
                        parsed_response[current_section] = "\n".join(current_content)
                    current_section = "action_suggestions"
                    current_content = []
                elif line.startswith("-") or line.startswith("•"):
                    # 提取建议列表项
                    suggestion = line.lstrip("-•").strip()
                    if suggestion:
                        parsed_response["action_suggestions"].append(suggestion)
                else:
                    if current_section:
                        current_content.append(line)
            
            # 处理最后一个段落
            if current_section and current_content:
                if current_section == "action_suggestions":
                    parsed_response[current_section].extend(current_content)
                else:
                    parsed_response[current_section] = "\n".join(current_content)
            
            # 如果解析失败，使用原始内容作为摘要
            if not parsed_response["summary"] and response_content:
                parsed_response["summary"] = response_content[:200] + "..." if len(response_content) > 200 else response_content
            
            return parsed_response
            
        except Exception as e:
            logger.error(f"LLM响应解析失败: {e}")
            return {
                "summary": response_content[:200] + "..." if len(response_content) > 200 else response_content,
                "nutrition_analysis": "",
                "health_impact": "",
                "action_suggestions": []
            }
    
    def _generate_recommendation_reasoning(self, scored_product: Dict, collaborative_score: float) -> str:
        """生成推荐理由"""
        nutrition_score = scored_product["combined_score"]
        improvement = scored_product["nutrition_improvement"]
        
        reasons = []
        
        # 营养评分理由
        if nutrition_score > 0.8:
            reasons.append("营养评分优秀")
        elif nutrition_score > 0.6:
            reasons.append("营养评分良好")
        
        # 协同过滤理由
        if collaborative_score > 0.7:
            reasons.append("相似用户偏好推荐")
        
        # 营养改善理由
        overall_improvement = improvement.get("overall_improvement_score", 0)
        if overall_improvement > 0.3:
            reasons.append("营养成分显著改善")
        elif overall_improvement > 0.1:
            reasons.append("营养成分有所改善")
        
        return "；".join(reasons) if reasons else "综合评分推荐"
    
    def _build_barcode_recommendation_response(self, recommendation_id: str,
                                             original_product: Dict,
                                             recommendations: List[RecommendationResult],
                                             llm_analysis: Dict,
                                             user_profile: Dict,
                                             processing_time_ms: int) -> RecommendationResponse:
        """构建条形码推荐响应"""
        
        user_profile_summary = self._create_user_profile_summary(user_profile)
        
        processing_metadata = {
            "algorithm_version": "v1.0",
            "processing_time_ms": processing_time_ms,
            "llm_tokens_used": llm_analysis.get("tokens_used", 0),
            "confidence_score": llm_analysis.get("confidence_score", 0.7),
            "total_candidates": 0,  # 可以从filter_stats获取
            "filtered_candidates": len(recommendations)
        }
        
        return RecommendationResponse(
            recommendation_id=recommendation_id,
            scan_type="barcode_scan",
            user_profile_summary=user_profile_summary,
            recommendations=recommendations,
            llm_analysis=llm_analysis,
            processing_metadata=processing_metadata
        )
    
    def _create_user_profile_summary(self, user_profile: Dict) -> Dict:
        """创建用户画像摘要"""
        allergens_count = len(self.db.get_user_allergens(user_profile.get("user_id", 0)))
        
        return {
            "user_id": user_profile.get("user_id"),
            "nutrition_goal": user_profile.get("nutrition_goal"),
            "age": user_profile.get("age"),
            "gender": user_profile.get("gender"),
            "allergens_count": allergens_count,
            "daily_calories_target": user_profile.get("daily_calories_target"),
            "preference_confidence": 0.75  # 可以基于用户行为数据计算
        }
    
    def _create_error_response(self, recommendation_id: str, message: str, details: str) -> RecommendationResponse:
        """创建错误响应"""
        return RecommendationResponse(
            recommendation_id=recommendation_id,
            scan_type="error",
            user_profile_summary={},
            recommendations=[],
            llm_analysis={
                "summary": "推荐生成失败",
                "error": details
            },
            processing_metadata={
                "algorithm_version": "v1.0",
                "processing_time_ms": 0,
                "error": True
            },
            success=False,
            message=message
        )
    
    async def _log_recommendation_request(self, request: RecommendationRequest, 
                                        response: Dict, processing_time_ms: int):
        """记录推荐请求日志"""
        try:
            log_data = {
                "user_id": request.user_id,
                "request_type": request.request_type,
                "processing_time_ms": processing_time_ms,
                "algorithm_version": "v1.0"
            }
            
            if isinstance(request, BarcodeRecommendationRequest):
                log_data["request_barcode"] = request.product_barcode
                log_data["recommended_products"] = [
                    rec.product.get("barcode") for rec in response.get("recommendations", [])
                ]
            
            if "llm_analysis" in response:
                llm_analysis = response["llm_analysis"]
                log_data["llm_analysis"] = json.dumps(llm_analysis, ensure_ascii=False)
                log_data["llm_tokens_used"] = llm_analysis.get("tokens_used", 0)
            
            # 异步记录日志
            await asyncio.to_thread(self.db.log_recommendation, log_data)
            
        except Exception as e:
            logger.error(f"记录推荐日志失败: {e}")
    
    def _update_performance_stats(self, processing_time_ms: int, success: bool):
        """更新性能统计"""
        self.performance_stats["total_requests"] += 1
        
        if success:
            self.performance_stats["successful_requests"] += 1
        else:
            self.performance_stats["failed_requests"] += 1
        
        self.performance_stats["response_times"].append(processing_time_ms)
        
        # 计算平均响应时间
        if self.performance_stats["response_times"]:
            self.performance_stats["average_response_time_ms"] = (
                sum(self.performance_stats["response_times"]) / 
                len(self.performance_stats["response_times"])
            )
    
    def _generate_recommendation_id(self) -> str:
        """生成推荐ID"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        return f"rec_{timestamp}_{self.performance_stats['total_requests']:04d}"
    
    def get_performance_statistics(self) -> Dict:
        """获取性能统计信息"""
        stats = self.performance_stats.copy()
        
        if stats["total_requests"] > 0:
            stats["success_rate"] = stats["successful_requests"] / stats["total_requests"]
            stats["failure_rate"] = stats["failed_requests"] / stats["total_requests"]
        else:
            stats["success_rate"] = 0.0
            stats["failure_rate"] = 0.0
        
        # 响应时间统计
        if stats["response_times"]:
            response_times = sorted(stats["response_times"])
            stats["response_time_stats"] = {
                "min_ms": min(response_times),
                "max_ms": max(response_times),
                "median_ms": response_times[len(response_times)//2],
                "p95_ms": response_times[int(len(response_times) * 0.95)],
                "p99_ms": response_times[int(len(response_times) * 0.99)]
            }
        
        stats["generated_at"] = datetime.now().isoformat()
        return stats
    
    def health_check(self) -> Dict:
        """系统健康检查"""
        try:
            # 检查数据库连接
            with self.db:
                db_healthy = True
        except Exception as e:
            db_healthy = False
            logger.error(f"数据库健康检查失败: {e}")
        
        # 检查LLM服务
        llm_health = self.llm.health_check()
        
        overall_healthy = db_healthy and llm_health.get("status") == "healthy"
        
        return {
            "status": "healthy" if overall_healthy else "unhealthy",
            "components": {
                "database": "healthy" if db_healthy else "unhealthy",
                "llm_service": llm_health.get("status", "unknown"),
                "recommendation_engine": "healthy"
            },
            "performance": {
                "total_requests": self.performance_stats["total_requests"],
                "success_rate": self.performance_stats.get("success_rate", 0.0),
                "average_response_time_ms": self.performance_stats["average_response_time_ms"]
            },
            "timestamp": datetime.now().isoformat()
        }

# 全局推荐引擎实例
_global_engine = None

def get_recommendation_engine() -> RecommendationEngine:
    """获取全局推荐引擎实例"""
    global _global_engine
    if _global_engine is None:
        _global_engine = RecommendationEngine()
    return _global_engine

# 便捷函数
async def recommend_barcode_alternatives(user_id: int, product_barcode: str, 
                                       max_recommendations: int = 5) -> RecommendationResponse:
    """便捷的条形码推荐函数"""
    engine = get_recommendation_engine()
    request = BarcodeRecommendationRequest(
        user_id=user_id,
        product_barcode=product_barcode,
        max_recommendations=max_recommendations
    )
    return await engine.recommend_alternatives(request)

async def analyze_receipt_purchases(user_id: int, purchased_items: List[Dict]) -> Dict:
    """便捷的小票分析函数"""
    engine = get_recommendation_engine()
    request = ReceiptRecommendationRequest(
        user_id=user_id,
        purchased_items=purchased_items
    )
    return await engine.analyze_receipt_recommendations(request)