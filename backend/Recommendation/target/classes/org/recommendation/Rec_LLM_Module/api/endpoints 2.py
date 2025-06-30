from fastapi import APIRouter, HTTPException, Depends
from typing import Dict, Any
import logging
from datetime import datetime
import uuid

from .models import (
    ApiResponse, BarcodeRecommendationRequest, ReceiptRecommendationRequest,
    BarcodeRecommendationResponse, ReceiptRecommendationResponse
)
from recommendation.recommender import get_recommendation_engine, RecommendationEngine

logger = logging.getLogger(__name__)
router = APIRouter()

def get_recommendation_service() -> RecommendationEngine:
    """获取推荐引擎实例"""
    return get_recommendation_engine()

@router.post("/recommendations/barcode", response_model=ApiResponse)
async def recommend_barcode_alternatives(
    request: BarcodeRecommendationRequest,
    rec_engine: RecommendationEngine = Depends(get_recommendation_service)
) -> ApiResponse:
    """
    条形码推荐端点
    根据用户扫描的商品条形码，推荐更健康的替代商品
    """
    try:
        # 转换为内部推荐请求格式
        from recommendation.recommender import BarcodeRecommendationRequest as InternalRequest
        internal_request = InternalRequest(
            user_id=request.user_id,
            product_barcode=request.product_barcode,
            max_recommendations=5
        )
        
        # 执行推荐
        recommendation_response = await rec_engine.recommend_alternatives(internal_request)
        
        # 转换为API响应格式
        api_data = {
            "recommendationId": recommendation_response.recommendation_id,
            "scanType": recommendation_response.scan_type,
            "userProfileSummary": recommendation_response.user_profile_summary,
            "recommendations": [
                {
                    "rank": rec.rank,
                    "product": _convert_product_to_api_format(rec.product),
                    "recommendationScore": rec.recommendation_score,
                    "reasoning": rec.reasoning
                }
                for rec in recommendation_response.recommendations
            ],
            "llmAnalysis": {
                "summary": recommendation_response.llm_analysis.get("summary", ""),
                "detailedAnalysis": recommendation_response.llm_analysis.get("detailed_analysis", ""),
                "actionSuggestions": recommendation_response.llm_analysis.get("action_suggestions", [])
            },
            "processingMetadata": recommendation_response.processing_metadata
        }
        
        return ApiResponse(
            success=True,
            message="Recommendation generated successfully",
            data=api_data,
            timestamp=datetime.now().isoformat()
        )
        
    except Exception as e:
        logger.error(f"Barcode recommendation failed: {e}")
        return ApiResponse(
            success=False,
            message="Failed to generate recommendation",
            error={
                "code": "RECOMMENDATION_ERROR",
                "message": str(e),
                "details": {"user_id": request.user_id, "barcode": request.product_barcode}
            },
            timestamp=datetime.now().isoformat()
        )

@router.post("/recommendations/receipt", response_model=ApiResponse)
async def analyze_receipt_recommendations(
    request: ReceiptRecommendationRequest,
    rec_engine: RecommendationEngine = Depends(get_recommendation_service)
) -> ApiResponse:
    """
    小票分析推荐端点
    分析用户购买的商品清单，提供营养分析和推荐建议
    """
    try:
        # 转换为内部推荐请求格式
        from recommendation.recommender import ReceiptRecommendationRequest as InternalRequest
        internal_request = InternalRequest(
            user_id=request.user_id,
            purchased_items=[
                {"barcode": item.barcode, "quantity": item.quantity}
                for item in request.purchased_items
            ]
        )
        
        # 执行分析
        analysis_result = await rec_engine.analyze_receipt_recommendations(internal_request)
        
        # 转换为API响应格式
        api_data = {
            "recommendationId": str(uuid.uuid4()),
            "scanType": "receipt",
            "userProfileSummary": {
                "userId": request.user_id,
                "nutritionGoal": analysis_result.get("user_nutrition_goal", "maintain")
            },
            "itemAnalyses": [
                {
                    "originalItem": {
                        "barcode": item["original_item"]["barcode"],
                        "quantity": item["original_item"]["quantity"],
                        "productInfo": _convert_product_to_api_format(item["original_item"]["product_info"])
                    },
                    "alternatives": [
                        {
                            "rank": i + 1,
                            "product": _convert_product_to_api_format(alt["product"]),
                            "recommendationScore": alt["recommendation_score"],
                            "reasoning": alt["reasoning"]
                        }
                        for i, alt in enumerate(item["alternatives"])
                    ]
                }
                for item in analysis_result.get("item_analyses", [])
            ],
            "overallNutritionAnalysis": {
                "totalCalories": analysis_result.get("overall_nutrition", {}).get("total_calories", 0),
                "totalProtein": analysis_result.get("overall_nutrition", {}).get("total_protein", 0),
                "totalFat": analysis_result.get("overall_nutrition", {}).get("total_fat", 0),
                "goalMatchPercentage": analysis_result.get("overall_nutrition", {}).get("goal_match_percentage", 0)
            },
            "llmInsights": {
                "summary": analysis_result.get("llm_insights", {}).get("summary", ""),
                "keyFindings": analysis_result.get("llm_insights", {}).get("key_findings", []),
                "improvementSuggestions": analysis_result.get("llm_insights", {}).get("improvement_suggestions", [])
            },
            "processingMetadata": {
                "algorithmVersion": analysis_result.get("algorithm_version", "v1.0"),
                "processingTimeMs": analysis_result.get("processing_time_ms", 0),
                "llmTokensUsed": analysis_result.get("llm_tokens_used", 0),
                "confidenceScore": analysis_result.get("confidence_score", 0.8)
            }
        }
        
        return ApiResponse(
            success=True,
            message="Receipt analysis completed successfully",
            data=api_data,
            timestamp=datetime.now().isoformat()
        )
        
    except Exception as e:
        logger.error(f"Receipt analysis failed: {e}")
        return ApiResponse(
            success=False,
            message="Failed to analyze receipt",
            error={
                "code": "ANALYSIS_ERROR",
                "message": str(e),
                "details": {"user_id": request.user_id, "items_count": len(request.purchased_items)}
            },
            timestamp=datetime.now().isoformat()
        )

def _convert_product_to_api_format(product: Dict[str, Any]) -> Dict[str, Any]:
    """
    将数据库product格式转换为API响应格式
    数据库使用snake_case，API使用camelCase
    """
    if not product:
        return {}
    
    return {
        "barCode": product.get("bar_code", ""),
        "productName": product.get("product_name", ""),
        "brand": product.get("brand", ""),
        "ingredients": product.get("ingredients", ""),
        "allergens": product.get("allergens", ""),
        "energy100g": product.get("energy_100g"),
        "energyKcal100g": product.get("energy_kcal_100g"),
        "fat100g": product.get("fat_100g"),
        "saturatedFat100g": product.get("saturated_fat_100g"),
        "carbohydrates100g": product.get("carbohydrates_100g"),
        "sugars100g": product.get("sugars_100g"),
        "proteins100g": product.get("proteins_100g"),
        "servingSize": product.get("serving_size"),
        "category": product.get("category", ""),
        "createdAt": product.get("created_at"),
        "updatedAt": product.get("updated_at")
    }