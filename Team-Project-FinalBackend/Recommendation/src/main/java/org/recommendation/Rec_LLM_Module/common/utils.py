"""
通用工具函数库
包含模块内部共享的实用函数，避免代码重复
"""

import logging
from typing import Dict, List, Optional, Any, Union
from datetime import datetime
import hashlib
import json

logger = logging.getLogger(__name__)

def safe_get_nutrition_value(product: Dict, field: str, default: float = 0.0) -> float:
    """
    安全获取营养值，确保不为None且为数值类型
    
    Args:
        product: 商品信息字典
        field: 营养字段名
        default: 默认值
    
    Returns:
        营养值 (float)
    """
    value = product.get(field)
    if value is None:
        return default
    try:
        return float(value)
    except (TypeError, ValueError):
        return default

def safe_get_string_value(data: Dict, field: str, default: str = "") -> str:
    """
    安全获取字符串值
    
    Args:
        data: 数据字典
        field: 字段名
        default: 默认值
    
    Returns:
        字符串值
    """
    value = data.get(field)
    if value is None:
        return default
    try:
        return str(value).strip()
    except (TypeError, ValueError):
        return default

def safe_get_int_value(data: Dict, field: str, default: int = 0) -> int:
    """
    安全获取整数值
    
    Args:
        data: 数据字典
        field: 字段名
        default: 默认值
    
    Returns:
        整数值
    """
    value = data.get(field)
    if value is None:
        return default
    try:
        return int(value)
    except (TypeError, ValueError):
        return default

def calculate_nutrition_score_difference(original: Dict, alternative: Dict, field: str) -> float:
    """
    计算两个商品在某个营养指标上的差值
    
    Args:
        original: 原商品信息
        alternative: 替代商品信息
        field: 营养字段名
    
    Returns:
        差值 (alternative - original)
    """
    original_value = safe_get_nutrition_value(original, field)
    alternative_value = safe_get_nutrition_value(alternative, field)
    return alternative_value - original_value

def normalize_product_name(product_name: str) -> str:
    """
    标准化商品名称，用于匹配和比较
    
    Args:
        product_name: 原始商品名称
    
    Returns:
        标准化后的商品名称
    """
    if not product_name:
        return ""
    
    # 转为小写并去除前后空格
    normalized = product_name.lower().strip()
    
    # 移除常见的品牌后缀和前缀
    common_suffixes = [" ltd", " inc", " co", " limited", " company"]
    for suffix in common_suffixes:
        if normalized.endswith(suffix):
            normalized = normalized[:-len(suffix)].strip()
    
    return normalized

def generate_recommendation_id() -> str:
    """
    生成推荐请求的唯一ID
    
    Returns:
        唯一ID字符串
    """
    timestamp = datetime.now().isoformat()
    hash_input = f"{timestamp}_{datetime.now().microsecond}"
    return hashlib.md5(hash_input.encode()).hexdigest()[:12]

def validate_nutrition_data(product: Dict) -> Dict[str, bool]:
    """
    验证商品营养数据的完整性和合理性
    
    Args:
        product: 商品信息
    
    Returns:
        验证结果字典
    """
    from config.constants import NUTRITION_VALIDATION_RANGES
    
    results = {
        "has_basic_nutrition": False,
        "calories_valid": False,
        "protein_valid": False,
        "fat_valid": False,
        "carbs_valid": False,
        "overall_valid": False
    }
    
    # 检查基础营养信息
    basic_fields = ["energy_kcal_100g", "proteins_100g", "fat_100g", "carbohydrates_100g"]
    has_basic = all(product.get(field) is not None for field in basic_fields)
    results["has_basic_nutrition"] = has_basic
    
    # 验证各项营养数据范围
    for field, (min_val, max_val) in NUTRITION_VALIDATION_RANGES.items():
        value = safe_get_nutrition_value(product, field)
        is_valid = min_val <= value <= max_val
        
        if field == "energy_kcal_100g":
            results["calories_valid"] = is_valid
        elif field == "proteins_100g":
            results["protein_valid"] = is_valid
        elif field == "fat_100g":
            results["fat_valid"] = is_valid
        elif field == "carbohydrates_100g":
            results["carbs_valid"] = is_valid
    
    # 总体验证结果
    results["overall_valid"] = (
        results["has_basic_nutrition"] and 
        results["calories_valid"] and 
        results["protein_valid"] and 
        results["fat_valid"] and 
        results["carbs_valid"]
    )
    
    return results

def format_nutrition_summary(product: Dict) -> str:
    """
    格式化商品营养信息摘要
    
    Args:
        product: 商品信息
    
    Returns:
        营养信息摘要字符串
    """
    calories = safe_get_nutrition_value(product, "energy_kcal_100g")
    protein = safe_get_nutrition_value(product, "proteins_100g")
    fat = safe_get_nutrition_value(product, "fat_100g")
    carbs = safe_get_nutrition_value(product, "carbohydrates_100g")
    sugar = safe_get_nutrition_value(product, "sugars_100g")
    
    return (f"Calories: {calories:.1f}kcal/100g, "
            f"Protein: {protein:.1f}g/100g, "
            f"Fat: {fat:.1f}g/100g, "
            f"Carbs: {carbs:.1f}g/100g, "
            f"Sugar: {sugar:.1f}g/100g")

def clean_json_response(response_text: str) -> str:
    """
    清理LLM响应中的JSON字符串，移除markdown标记等
    
    Args:
        response_text: 原始响应文本
    
    Returns:
        清理后的JSON字符串
    """
    if not response_text:
        return ""
    
    # 移除markdown代码块标记
    response_text = response_text.strip()
    if response_text.startswith("```json"):
        response_text = response_text[7:]
    if response_text.startswith("```"):
        response_text = response_text[3:]
    if response_text.endswith("```"):
        response_text = response_text[:-3]
    
    return response_text.strip()

def merge_product_data(base_product: Dict, additional_data: Dict) -> Dict:
    """
    合并商品数据，保持原有数据优先级
    
    Args:
        base_product: 基础商品数据
        additional_data: 额外数据
    
    Returns:
        合并后的商品数据
    """
    if not base_product:
        return additional_data.copy() if additional_data else {}
    
    if not additional_data:
        return base_product.copy()
    
    # 创建合并后的字典，base_product优先
    merged = additional_data.copy()
    merged.update(base_product)
    
    return merged

def log_performance_metrics(operation_name: str, start_time: datetime, 
                          additional_info: Optional[Dict] = None) -> None:
    """
    记录性能指标
    
    Args:
        operation_name: 操作名称
        start_time: 开始时间
        additional_info: 额外信息
    """
    end_time = datetime.now()
    duration_ms = (end_time - start_time).total_seconds() * 1000
    
    log_message = f"Performance: {operation_name} completed in {duration_ms:.1f}ms"
    
    if additional_info:
        info_str = ", ".join([f"{k}={v}" for k, v in additional_info.items()])
        log_message += f" ({info_str})"
    
    logger.info(log_message)

def calculate_similarity_score(product1: Dict, product2: Dict) -> float:
    """
    计算两个商品的相似度评分
    
    Args:
        product1: 商品1
        product2: 商品2
    
    Returns:
        相似度评分 (0.0 - 1.0)
    """
    if not product1 or not product2:
        return 0.0
    
    # 类别相似度 (权重: 0.4)
    category_score = 1.0 if product1.get("category") == product2.get("category") else 0.0
    
    # 营养相似度 (权重: 0.6)
    nutrition_fields = ["energy_kcal_100g", "proteins_100g", "fat_100g", "carbohydrates_100g"]
    nutrition_scores = []
    
    for field in nutrition_fields:
        val1 = safe_get_nutrition_value(product1, field)
        val2 = safe_get_nutrition_value(product2, field)
        
        if val1 == 0 and val2 == 0:
            nutrition_scores.append(1.0)
        elif val1 == 0 or val2 == 0:
            nutrition_scores.append(0.0)
        else:
            # 计算相对差异
            diff = abs(val1 - val2) / max(val1, val2)
            similarity = max(0.0, 1.0 - diff)
            nutrition_scores.append(similarity)
    
    nutrition_score = sum(nutrition_scores) / len(nutrition_scores) if nutrition_scores else 0.0
    
    # 加权总分
    total_score = category_score * 0.4 + nutrition_score * 0.6
    
    return min(1.0, max(0.0, total_score))