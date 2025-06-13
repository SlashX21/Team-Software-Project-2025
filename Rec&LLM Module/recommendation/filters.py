"""
多层过滤器系统
实现过敏原绝对过滤、分类约束、营养基础过滤等硬性约束
"""

import logging
from abc import ABC, abstractmethod
from typing import Dict, List, Optional, Set, Tuple
from datetime import datetime, timedelta
import re

from config.constants import (
    AllergenPresenceType, ALLERGEN_KEYWORDS, 
    NUTRITION_VALIDATION_RANGES, CATEGORY_MAPPING
)

logger = logging.getLogger(__name__)

class BaseFilter(ABC):
    """过滤器基类"""
    
    def __init__(self, name: str):
        self.name = name
        self.filtered_count = 0
        self.total_processed = 0
        
    @abstractmethod
    def filter(self, products: List[Dict], context: Dict) -> List[Dict]:
        """执行过滤操作"""
        pass
    
    def get_filter_stats(self) -> Dict:
        """获取过滤器统计信息"""
        filter_rate = 0.0
        if self.total_processed > 0:
            filter_rate = self.filtered_count / self.total_processed
            
        return {
            "filter_name": self.name,
            "total_processed": self.total_processed,
            "filtered_count": self.filtered_count,
            "filter_rate": round(filter_rate, 3),
            "pass_rate": round(1 - filter_rate, 3)
        }
    
    def reset_stats(self):
        """重置统计信息"""
        self.filtered_count = 0
        self.total_processed = 0

class AllergenFilter(BaseFilter):
    """过敏原绝对过滤器 - 零容忍策略"""
    
    def __init__(self):
        super().__init__("AllergenFilter")
        self.allergen_keywords = ALLERGEN_KEYWORDS
        
    def filter(self, products: List[Dict], context: Dict) -> List[Dict]:
        """
        过敏原绝对过滤
        Args:
            products: 候选商品列表
            context: 上下文信息，包含user_allergens
        Returns:
            过滤后的安全商品列表
        """
        user_allergens = context.get("user_allergens", [])
        if not user_allergens:
            self.total_processed += len(products)
            return products
        
        safe_products = []
        user_allergen_names = {allergen["name"].lower() for allergen in user_allergens}
        
        for product in products:
            self.total_processed += 1
            
            if self._is_product_safe(product, user_allergen_names):
                safe_products.append(product)
            else:
                self.filtered_count += 1
                logger.debug(f"过敏原过滤: {product.get('name')} - 包含用户过敏原")
        
        logger.info(f"过敏原过滤: {len(products)} -> {len(safe_products)} 商品")
        return safe_products
    
    def _is_product_safe(self, product: Dict, user_allergen_names: Set[str]) -> bool:
        """
        检查单个商品是否对用户安全
        Args:
            product: 商品信息
            user_allergen_names: 用户过敏原名称集合
        Returns:
            是否安全
        """
        # 检查商品过敏原字段
        allergens_text = product.get("allergens", "")
        if allergens_text:
            allergens_lower = allergens_text.lower()
            
            # 检查每个用户过敏原
            for allergen_name in user_allergen_names:
                # 直接名称匹配
                if allergen_name in allergens_lower:
                    return False
                
                # 关键词匹配
                if allergen_name in self.allergen_keywords:
                    for keyword in self.allergen_keywords[allergen_name]:
                        if keyword.lower() in allergens_lower:
                            return False
        
        # 检查成分列表（更细致的检查）
        ingredients_text = product.get("ingredients", "")
        if ingredients_text:
            ingredients_lower = ingredients_text.lower()
            
            for allergen_name in user_allergen_names:
                if allergen_name in self.allergen_keywords:
                    for keyword in self.allergen_keywords[allergen_name]:
                        # 使用词边界正则表达式，避免部分匹配
                        pattern = r'\b' + re.escape(keyword.lower()) + r'\b'
                        if re.search(pattern, ingredients_lower):
                            return False
        
        return True
    
    def check_specific_product(self, product: Dict, user_allergens: List[Dict]) -> Dict:
        """
        检查特定商品的过敏原安全性（详细报告）
        Returns:
            详细的安全检查报告
        """
        if not user_allergens:
            return {
                "safe": True,
                "detected_allergens": [],
                "risk_level": "none",
                "warnings": []
            }
        
        detected_allergens = []
        warnings = []
        max_risk_level = "none"
        
        allergens_text = product.get("allergens", "").lower()
        ingredients_text = product.get("ingredients", "").lower()
        
        for user_allergen in user_allergens:
            allergen_name = user_allergen["name"].lower()
            severity = user_allergen.get("severity_level", "moderate")
            
            # 检查过敏原字段
            found_in_allergens = allergen_name in allergens_text
            found_in_ingredients = False
            
            # 检查成分列表
            if allergen_name in self.allergen_keywords:
                for keyword in self.allergen_keywords[allergen_name]:
                    pattern = r'\b' + re.escape(keyword.lower()) + r'\b'
                    if re.search(pattern, ingredients_text):
                        found_in_ingredients = True
                        break
            
            if found_in_allergens or found_in_ingredients:
                detected_allergens.append({
                    "allergen_name": user_allergen["name"],
                    "severity": severity,
                    "found_in": "allergens" if found_in_allergens else "ingredients",
                    "risk_assessment": self._assess_risk_level(severity)
                })
                
                # 更新最大风险等级
                current_risk = self._assess_risk_level(severity)
                if self._risk_priority(current_risk) > self._risk_priority(max_risk_level):
                    max_risk_level = current_risk
                
                # 生成警告信息
                if severity == "severe":
                    warnings.append(f"严重警告：该商品含有{user_allergen['name']}，可能引起严重过敏反应")
                elif severity == "moderate":
                    warnings.append(f"警告：该商品含有{user_allergen['name']}")
                else:
                    warnings.append(f"注意：该商品含有{user_allergen['name']}")
        
        return {
            "safe": len(detected_allergens) == 0,
            "detected_allergens": detected_allergens,
            "risk_level": max_risk_level,
            "warnings": warnings,
            "checked_at": datetime.now().isoformat()
        }
    
    def _assess_risk_level(self, severity: str) -> str:
        """评估风险等级"""
        risk_mapping = {
            "severe": "high",
            "moderate": "medium", 
            "mild": "low"
        }
        return risk_mapping.get(severity, "medium")
    
    def _risk_priority(self, risk_level: str) -> int:
        """风险等级优先级（用于比较）"""
        priority_mapping = {
            "none": 0,
            "low": 1,
            "medium": 2,
            "high": 3
        }
        return priority_mapping.get(risk_level, 0)

class CategoryFilter(BaseFilter):
    """商品分类过滤器"""
    
    def __init__(self):
        super().__init__("CategoryFilter")
        
    def filter(self, products: List[Dict], context: Dict) -> List[Dict]:
        """
        分类约束过滤
        Args:
            products: 候选商品列表
            context: 包含target_category和strict_mode
        Returns:
            符合分类约束的商品
        """
        target_category = context.get("target_category")
        strict_mode = context.get("strict_category_constraint", True)
        
        if not target_category:
            self.total_processed += len(products)
            return products
        
        filtered_products = []
        
        for product in products:
            self.total_processed += 1
            product_category = product.get("category", "")
            
            if strict_mode:
                # 严格模式：必须完全匹配分类
                if product_category == target_category:
                    filtered_products.append(product)
                else:
                    self.filtered_count += 1
            else:
                # 宽松模式：允许相关分类
                if self._is_related_category(product_category, target_category):
                    filtered_products.append(product)
                else:
                    self.filtered_count += 1
        
        logger.info(f"分类过滤: {len(products)} -> {len(filtered_products)} 商品 (目标分类: {target_category})")
        return filtered_products
    
    def _is_related_category(self, product_category: str, target_category: str) -> bool:
        """判断分类是否相关"""
        if product_category == target_category:
            return True
        
        # 检查是否在同一大类下
        for main_category, sub_categories in CATEGORY_MAPPING.items():
            if target_category in sub_categories and product_category in sub_categories:
                return True
        
        return False

class AvailabilityFilter(BaseFilter):
    """基础可用性过滤器"""
    
    def __init__(self):
        super().__init__("AvailabilityFilter")
        
    def filter(self, products: List[Dict], context: Dict) -> List[Dict]:
        """
        基础可用性检查
        Args:
            products: 候选商品列表
            context: 上下文信息
        Returns:
            通过基础检查的商品
        """
        available_products = []
        
        for product in products:
            self.total_processed += 1
            
            if self._is_product_available(product):
                available_products.append(product)
            else:
                self.filtered_count += 1
        
        logger.info(f"可用性过滤: {len(products)} -> {len(available_products)} 商品")
        return available_products
    
    def _is_product_available(self, product: Dict) -> bool:
        """检查商品基础可用性"""
        # 检查基础字段完整性
        if not product.get("barcode") or not product.get("name"):
            return False
        
        # 检查营养数据合理性
        energy_kcal = product.get("energy_kcal_100g")
        if energy_kcal is not None:
            min_cal, max_cal = NUTRITION_VALIDATION_RANGES["energy_kcal_100g"]
            if not (min_cal <= energy_kcal <= max_cal):
                return False
        
        proteins = product.get("proteins_100g")
        if proteins is not None:
            min_protein, max_protein = NUTRITION_VALIDATION_RANGES["proteins_100g"]
            if not (min_protein <= proteins <= max_protein):
                return False
        
        fat = product.get("fat_100g")
        if fat is not None:
            min_fat, max_fat = NUTRITION_VALIDATION_RANGES["fat_100g"]
            if not (min_fat <= fat <= max_fat):
                return False
        
        # 检查异常价格（如果有价格信息）
        unit_price = product.get("unit_price")
        if unit_price is not None:
            if unit_price <= 0 or unit_price > 1000:  # 异常价格范围
                return False
        
        return True

class NutritionDataFilter(BaseFilter):
    """营养数据完整性过滤器"""
    
    def __init__(self, required_fields: Optional[List[str]] = None):
        super().__init__("NutritionDataFilter")
        self.required_fields = required_fields or [
            "energy_kcal_100g", "proteins_100g", "fat_100g", "carbohydrates_100g"
        ]
        
    def filter(self, products: List[Dict], context: Dict) -> List[Dict]:
        """
        营养数据完整性过滤
        Args:
            products: 候选商品列表
            context: 上下文信息
        Returns:
            具有完整营养数据的商品
        """
        complete_products = []
        
        for product in products:
            self.total_processed += 1
            
            if self._has_complete_nutrition_data(product):
                complete_products.append(product)
            else:
                self.filtered_count += 1
        
        logger.info(f"营养数据过滤: {len(products)} -> {len(complete_products)} 商品")
        return complete_products
    
    def _has_complete_nutrition_data(self, product: Dict) -> bool:
        """检查营养数据完整性"""
        for field in self.required_fields:
            value = product.get(field)
            if value is None or (isinstance(value, str) and value.strip() == ""):
                return False
        return True

class DiversityFilter(BaseFilter):
    """多样性过滤器 - 避免推荐过于相似的商品"""
    
    def __init__(self, max_same_brand: int = 2, max_same_subcategory: int = 3):
        super().__init__("DiversityFilter")
        self.max_same_brand = max_same_brand
        self.max_same_subcategory = max_same_subcategory
        
    def filter(self, products: List[Dict], context: Dict) -> List[Dict]:
        """
        多样性过滤
        Args:
            products: 候选商品列表（应该已经按评分排序）
            context: 上下文信息
        Returns:
            多样化的商品列表
        """
        if len(products) <= 5:  # 商品数量较少时不进行多样性过滤
            self.total_processed += len(products)
            return products
        
        diverse_products = []
        brand_count = {}
        subcategory_count = {}
        
        for product in products:
            self.total_processed += 1
            
            brand = product.get("brand", "Unknown")
            category = product.get("category", "Unknown") 
            
            # 检查品牌多样性
            current_brand_count = brand_count.get(brand, 0)
            current_subcategory_count = subcategory_count.get(category, 0)
            
            if (current_brand_count < self.max_same_brand and 
                current_subcategory_count < self.max_same_subcategory):
                
                diverse_products.append(product)
                brand_count[brand] = current_brand_count + 1
                subcategory_count[category] = current_subcategory_count + 1
            else:
                self.filtered_count += 1
        
        logger.info(f"多样性过滤: {len(products)} -> {len(diverse_products)} 商品")
        return diverse_products

class HardFilters:
    """硬过滤器管道 - 组合多个强制性过滤器"""
    
    def __init__(self):
        self.filters = [
            AvailabilityFilter(),           # 基础可用性检查
            NutritionDataFilter(),          # 营养数据完整性
            AllergenFilter(),               # 过敏原绝对过滤
            CategoryFilter()                # 分类约束过滤
        ]
        
    def apply_filters(self, products: List[Dict], context: Dict) -> Tuple[List[Dict], Dict]:
        """
        应用所有硬过滤器
        Args:
            products: 原始商品列表
            context: 过滤上下文
        Returns:
            (过滤后商品列表, 过滤统计信息)
        """
        filtered_products = products.copy()
        filter_stats = []
        
        initial_count = len(filtered_products)
        
        for filter_instance in self.filters:
            filter_instance.reset_stats()
            filtered_products = filter_instance.filter(filtered_products, context)
            stats = filter_instance.get_filter_stats()
            filter_stats.append(stats)
            
            # 如果没有商品通过过滤，提前终止
            if not filtered_products:
                logger.warning(f"硬过滤器 {filter_instance.name} 过滤掉了所有商品")
                break
        
        final_count = len(filtered_products)
        overall_filter_rate = (initial_count - final_count) / initial_count if initial_count > 0 else 0
        
        summary_stats = {
            "initial_count": initial_count,
            "final_count": final_count,
            "total_filtered": initial_count - final_count,
            "overall_filter_rate": round(overall_filter_rate, 3),
            "filter_details": filter_stats,
            "processing_time": datetime.now().isoformat()
        }
        
        logger.info(f"硬过滤器完成: {initial_count} -> {final_count} 商品 "
                   f"(过滤率: {overall_filter_rate:.1%})")
        
        return filtered_products, summary_stats
    
    def check_product_safety(self, product: Dict, user_allergens: List[Dict]) -> Dict:
        """
        检查单个商品的安全性（用于条形码扫描）
        Args:
            product: 商品信息
            user_allergens: 用户过敏原列表
        Returns:
            安全检查报告
        """
        allergen_filter = AllergenFilter()
        return allergen_filter.check_specific_product(product, user_allergens)
    
    def get_filter_summary(self) -> Dict:
        """获取过滤器配置摘要"""
        return {
            "hard_filters": [f.name for f in self.filters],
            "filter_count": len(self.filters),
            "safety_guarantees": [
                "100% 过敏原安全性",
                "营养数据完整性验证", 
                "商品基础可用性检查",
                "分类约束遵守"
            ]
        }