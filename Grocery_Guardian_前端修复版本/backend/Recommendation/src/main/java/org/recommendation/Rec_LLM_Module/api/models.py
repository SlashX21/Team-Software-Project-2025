from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

# API Request/Response Models

class ApiResponse(BaseModel):
    success: bool
    message: str
    data: Optional[dict] = None
    error: Optional[dict] = None
    timestamp: str

class ApiError(BaseModel):
    code: str
    message: str
    details: Optional[dict] = None

# Database Entity Models

class User(BaseModel):
    user_id: Optional[int] = Field(None, alias='userId')
    user_name: str = Field(..., alias='userName')
    email: str = Field(...)
    password_hash: str = Field(..., alias='passwordHash')
    age: Optional[int] = None
    gender: Optional[str] = None
    height_cm: Optional[int] = Field(None, alias='heightCm')
    weight_kg: Optional[float] = Field(None, alias='weightKg')
    activity_level: Optional[str] = Field(None, alias='activityLevel')
    nutrition_goal: Optional[str] = Field(None, alias='nutritionGoal')
    daily_calories_target: Optional[float] = Field(None, alias='dailyCaloriesTarget')
    daily_protein_target: Optional[float] = Field(None, alias='dailyProteinTarget')
    daily_carb_target: Optional[float] = Field(None, alias='dailyCarbTarget')
    daily_fat_target: Optional[float] = Field(None, alias='dailyFatTarget')
    created_time: Optional[str] = Field(None, alias='createdTime')

class Product(BaseModel):
    bar_code: str = Field(..., alias='barCode')
    product_name: str = Field(..., alias='productName')
    brand: Optional[str] = None
    ingredients: Optional[str] = None
    allergens: Optional[str] = None
    energy_100g: Optional[float] = Field(None, alias='energy100g')
    energy_kcal_100g: Optional[float] = Field(None, alias='energyKcal100g')
    fat_100g: Optional[float] = Field(None, alias='fat100g')
    saturated_fat_100g: Optional[float] = Field(None, alias='saturatedFat100g')
    carbohydrates_100g: Optional[float] = Field(None, alias='carbohydrates100g')
    sugars_100g: Optional[float] = Field(None, alias='sugars100g')
    proteins_100g: Optional[float] = Field(None, alias='proteins100g')
    serving_size: Optional[str] = Field(None, alias='servingSize')
    category: str
    created_at: Optional[str] = Field(None, alias='createdAt')
    updated_at: Optional[str] = Field(None, alias='updatedAt')

class Allergen(BaseModel):
    allergen_id: Optional[int] = Field(None, alias='allergenId')
    name: str
    category: Optional[str] = None
    is_common: Optional[bool] = Field(None, alias='isCommon')
    description: Optional[str] = None
    created_time: Optional[str] = Field(None, alias='createdTime')

# Request Models

class BarcodeRecommendationRequest(BaseModel):
    user_id: int = Field(..., alias='userId')
    product_barcode: str = Field(..., alias='productBarcode')

class PurchasedItem(BaseModel):
    barcode: str
    quantity: int

class ReceiptRecommendationRequest(BaseModel):
    user_id: int = Field(..., alias='userId')
    purchased_items: List[PurchasedItem] = Field(..., alias='purchasedItems')

# Response Models

class UserProfileSummary(BaseModel):
    user_id: int = Field(..., alias='userId')
    nutrition_goal: str = Field(..., alias='nutritionGoal')

class RecommendationItem(BaseModel):
    rank: int
    product: Product
    recommendation_score: float = Field(..., alias='recommendationScore')
    reasoning: str

class LLMAnalysis(BaseModel):
    summary: str
    detailed_analysis: str = Field(..., alias='detailedAnalysis')
    action_suggestions: List[str] = Field(..., alias='actionSuggestions')

class ProcessingMetadata(BaseModel):
    algorithm_version: str = Field(..., alias='algorithmVersion')
    processing_time_ms: int = Field(..., alias='processingTimeMs')
    llm_tokens_used: int = Field(..., alias='llmTokensUsed')
    confidence_score: float = Field(..., alias='confidenceScore')

class BarcodeRecommendationResponse(BaseModel):
    recommendation_id: str = Field(..., alias='recommendationId')
    scan_type: str = Field(default='barcode', alias='scanType')
    user_profile_summary: UserProfileSummary = Field(..., alias='userProfileSummary')
    original_product: Product = Field(..., alias='originalProduct')
    recommendations: List[RecommendationItem]
    llm_analysis: LLMAnalysis = Field(..., alias='llmAnalysis')
    processing_metadata: ProcessingMetadata = Field(..., alias='processingMetadata')

class ItemAnalysis(BaseModel):
    original_item: dict = Field(..., alias='originalItem')
    alternatives: List[RecommendationItem]

class OverallNutritionAnalysis(BaseModel):
    total_calories: float = Field(..., alias='totalCalories')
    total_protein: float = Field(..., alias='totalProtein')
    total_fat: float = Field(..., alias='totalFat')
    goal_match_percentage: float = Field(..., alias='goalMatchPercentage')

class LLMInsights(BaseModel):
    summary: str
    key_findings: List[str] = Field(..., alias='keyFindings')
    improvement_suggestions: List[str] = Field(..., alias='improvementSuggestions')

class ReceiptRecommendationResponse(BaseModel):
    recommendation_id: str = Field(..., alias='recommendationId')
    scan_type: str = Field(default='receipt', alias='scanType')
    user_profile_summary: UserProfileSummary = Field(..., alias='userProfileSummary')
    item_analyses: List[ItemAnalysis] = Field(..., alias='itemAnalyses')
    overall_nutrition_analysis: OverallNutritionAnalysis = Field(..., alias='overallNutritionAnalysis')
    llm_insights: LLMInsights = Field(..., alias='llmInsights')
    processing_metadata: ProcessingMetadata = Field(..., alias='processingMetadata')