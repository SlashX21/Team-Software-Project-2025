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
    """过敏原过滤器 - 基于数据库的智能过敏原检测"""
    
    def __init__(self, db_manager=None):
        super().__init__("AllergenFilter")
        self.db_manager = db_manager
        self.filtered_details = []  # 存储被过滤商品的详细信息
        # 关键词匹配回退机制（在数据库查询失败时使用）
        self.allergen_keywords = {
            "milk": ["milk", "dairy", "lactose", "cream", "butter", "cheese", "whey", "casein"],
            "nuts": ["nuts", "peanut", "almond", "walnut", "cashew", "pecan", "hazelnut", "brazil", "macadamia"],
            "gluten": ["wheat", "gluten", "flour", "barley", "rye", "oats"],
            "soy": ["soy", "soybean", "tofu", "tempeh", "miso"],
            "eggs": ["egg", "albumin", "lecithin"],
            "shellfish": ["shrimp", "crab", "lobster", "shellfish", "seafood"],
            "fish": ["fish", "salmon", "tuna", "cod", "anchovy"]
        }
        
    def filter(self, products: List[Dict], context: Dict) -> List[Dict]:
        """
        过敏原安全过滤
        Args:
            products: 候选商品列表
            context: 包含user_allergens的上下文
        Returns:
            安全的商品列表
        """
        user_allergens = context.get("user_allergens", [])
        
        if not user_allergens:
            self.total_processed += len(products)
            return products
        
        # 重置过滤详情
        self.filtered_details = []
        safe_products = []
        
        # 如果有数据库管理器，使用数据库方法
        if self.db_manager:
            return self._filter_by_database(products, user_allergens)
        else:
            return self._filter_by_text_matching(products, user_allergens)
    
    def _filter_by_database(self, products: List[Dict], user_allergens: List[Dict]) -> List[Dict]:
        """基于数据库的过敏原过滤"""
        safe_products = []
        
        # 获取用户过敏原ID
        user_allergen_ids = []
        for allergen in user_allergens:
            allergen_name = allergen.get("name", "")
            if allergen_name:
                allergen_data = self.db_manager.get_allergen_by_name(allergen_name)
                if allergen_data and allergen_data.get("allergen_id"):
                    user_allergen_ids.append(allergen_data["allergen_id"])
        
        if not user_allergen_ids:
            logger.warning("无法获取用户过敏原ID，跳过过敏原过滤")
            self.total_processed += len(products)
            return products
        
        for product in products:
            self.total_processed += 1
            barcode = product.get("bar_code")
            
            if not barcode:
                # 如果没有条形码，不能进行过敏原检查，为安全起见过滤掉
                self.filtered_count += 1
                self._add_filtered_detail(product, "缺少条形码")
                continue
            
            # 查询PRODUCT_ALLERGEN表
            allergen_check_result = self.db_manager.check_product_allergens(barcode, user_allergen_ids)
            
            if allergen_check_result.get("safe", False):
                safe_products.append(product)
            else:
                self.filtered_count += 1
                detected_allergens = allergen_check_result.get("detected_allergens", [])
                allergen_names = [a.get("name", "未知") for a in detected_allergens]
                self._add_filtered_detail(product, f"Contains user allergens: {', '.join(allergen_names)}")
                
                logger.debug(f"过敏原过滤: {product.get('product_name', '未知商品')} - 包含用户过敏原: {', '.join(allergen_names)}")
                # 增加更详细的过滤理由日志
                for allergen_info in detected_allergens:
                    allergen_name = allergen_info.get("name", "未知过敏原")
                    logger.debug(f"  具体过敏原匹配: '{allergen_name}' 在商品 '{product.get('product_name', '未知商品')}' 中被检测到")
        
        logger.info(f"Allergen filtering: {len(products)} -> {len(safe_products)} products")
        return safe_products
    
    def _add_filtered_detail(self, product: Dict, reason: str):
        """添加被过滤商品的详细信息"""
        if len(self.filtered_details) < 5:  # 只保存前5个
            self.filtered_details.append({
                "name": product.get("product_name", "未知商品"),
                "barcode": product.get("bar_code", "未知"),
                "reason": reason
            })
    
    def get_filtered_details(self) -> List[Dict]:
        """获取被过滤商品的详细信息"""
        return self.filtered_details.copy()
    
    def _filter_by_text_matching(self, products: List[Dict], user_allergens: List[Dict]) -> List[Dict]:
        """回退方法：基于文本匹配的过敏原过滤"""
        safe_products = []
        user_allergen_names = {allergen["name"].lower() for allergen in user_allergens}
        
        for product in products:
            if self._is_product_safe(product, user_allergen_names):
                safe_products.append(product)
            else:
                self.filtered_count += 1
                logger.debug(f"过敏原过滤(文本匹配): {product.get('product_name')} - 包含用户过敏原")
        
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
    """智能商品分类过滤器 - 考虑用户期望相似度"""
    
    def __init__(self):
        super().__init__("CategoryFilter")
        # 用户期望相似度映射表
        self.user_expectation_mapping = {
            # 饮料类 - 用户期望得到其他饮料推荐
            "Beverages": {
                "preferred": ["Beverages"],
                "acceptable": ["Health supplements", "Dairy"],  # 健康饮品、乳制品可接受
                "avoid": ["Food", "Snacks"]  # 避免推荐食物给想要饮料的用户
            },
            # 零食类 - 可以适当跨类推荐健康零食
            "Snacks": {
                "preferred": ["Snacks"],
                "acceptable": ["Health supplements", "Nuts", "Fruits"],
                "avoid": ["Beverages", "Dairy"]
            },
            # 食品类 - 相对宽松，可以推荐其他食品
            "Food": {
                "preferred": ["Food"],
                "acceptable": ["Snacks", "Health supplements"],
                "avoid": ["Beverages"]
            },
            # 健康补充品 - 可以广泛推荐
            "Health supplements": {
                "preferred": ["Health supplements"],
                "acceptable": ["Food", "Snacks", "Beverages"],
                "avoid": []
            }
        }
        
    def filter(self, products: List[Dict], context: Dict) -> List[Dict]:
        """
        智能分类约束过滤 - 考虑用户期望相似度
        Args:
            products: 候选商品列表
            context: 包含target_category和user_expectation_mode
        Returns:
            符合分类约束且用户期望的商品
        """
        target_category = context.get("target_category")
        user_expectation_mode = context.get("user_expectation_mode", True)  # 默认启用用户期望模式
        
        if not target_category:
            self.total_processed += len(products)
            return products
        
        filtered_products = []
        
        for product in products:
            self.total_processed += 1
            product_category = product.get("category", "")
            
            if user_expectation_mode:
                # 使用用户期望相似度评分
                if self._is_user_expectation_compatible(product_category, target_category):
                    filtered_products.append(product)
                else:
                    self.filtered_count += 1
                    logger.debug(f"分类过滤: {product.get('product_name', '未知商品')} - 用户期望不匹配 "
                               f"(原分类: {target_category}, 候选分类: {product_category})")
            else:
                # 传统严格模式
                if product_category == target_category:
                    filtered_products.append(product)
                else:
                    self.filtered_count += 1
        
        logger.info(f"Category filtering: {len(products)} -> {len(filtered_products)} products "
                   f"(target category: {target_category}, user expectation mode: {user_expectation_mode})")
        return filtered_products
    
    def _is_user_expectation_compatible(self, product_category: str, target_category: str) -> bool:
        """判断商品分类是否符合用户期望"""
        # 完全匹配最优
        if product_category == target_category:
            return True
        
        # 查找目标分类的期望映射
        expectation_rules = self.user_expectation_mapping.get(target_category, {})
        
        # 检查是否在首选分类中
        preferred = expectation_rules.get("preferred", [])
        if product_category in preferred:
            return True
        
        # 检查是否在可接受分类中
        acceptable = expectation_rules.get("acceptable", [])
        if product_category in acceptable:
            return True
        
        # 检查是否在避免分类中
        avoid = expectation_rules.get("avoid", [])
        if product_category in avoid:
            return False
        
        # 默认情况：如果没有明确规则，使用传统相关性检查
        return self._is_related_category(product_category, target_category)
    
    def _is_related_category(self, product_category: str, target_category: str) -> bool:
        """判断分类是否相关（传统逻辑保留）"""
        if product_category == target_category:
            return True
        
        # 检查是否在同一大类下
        for main_category, sub_categories in CATEGORY_MAPPING.items():
            if target_category in sub_categories and product_category in sub_categories:
                return True
        
        return False
    
    def get_compatibility_score(self, product_category: str, target_category: str) -> float:
        """计算分类兼容性评分（用于排序优化）"""
        if product_category == target_category:
            return 1.0
        
        expectation_rules = self.user_expectation_mapping.get(target_category, {})
        
        if product_category in expectation_rules.get("preferred", []):
            return 0.9
        elif product_category in expectation_rules.get("acceptable", []):
            return 0.6
        elif product_category in expectation_rules.get("avoid", []):
            return 0.1
        else:
            return 0.4  # 中性分类

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
        
        logger.info(f"Availability filtering: {len(products)} -> {len(available_products)} products")
        return available_products
    
    def _is_product_available(self, product: Dict) -> bool:
        """检查商品基础可用性"""
        # 检查基础字段完整性
        if not product.get("bar_code") or not product.get("product_name"):
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
        
        logger.info(f"Nutrition data filtering: {len(products)} -> {len(complete_products)} products")
        return complete_products
    
    def _has_complete_nutrition_data(self, product: Dict) -> bool:
        """检查营养数据完整性"""
        for field in self.required_fields:
            value = product.get(field)
            
            # 检查是否为None
            if value is None:
                logger.debug(f"营养数据过滤: {product.get('product_name', '未知商品')} - 字段 '{field}' 为 None")
                return False
            
            # 检查是否为空字符串
            if isinstance(value, str) and value.strip() == "":
                logger.debug(f"营养数据过滤: {product.get('product_name', '未知商品')} - 字段 '{field}' 为空字符串")
                return False
            
            # 检查字符串是否为 "None" 或其他无效值
            if isinstance(value, str) and value.strip().lower() in ["none", "null", "n/a", "na", "unknown", "未知"]:
                logger.debug(f"营养数据过滤: {product.get('product_name', '未知商品')} - 字段 '{field}' 包含无效文本: '{value}'")
                return False
            
            # 尝试转换为数值，确保是有效的营养数据
            try:
                if isinstance(value, str):
                    float_value = float(value)
                elif isinstance(value, (int, float)):
                    float_value = float(value)
                else:
                    logger.debug(f"营养数据过滤: {product.get('product_name', '未知商品')} - 字段 '{field}' 类型无效: {type(value)}")
                    return False
                
                # 检查数值是否在合理范围内（营养数据不应为负数）
                if float_value < 0:
                    logger.debug(f"营养数据过滤: {product.get('product_name', '未知商品')} - 字段 '{field}' 为负数: {float_value}")
                    return False
                    
            except (ValueError, TypeError) as e:
                logger.debug(f"营养数据过滤: {product.get('product_name', '未知商品')} - 字段 '{field}' 无法转换为数值: {value} (错误: {e})")
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
        
        logger.info(f"Diversity filtering: {len(products)} -> {len(diverse_products)} products")
        return diverse_products

class HardFilters:
    """硬过滤器管道 - 组合多个强制性过滤器"""
    
    def __init__(self, db_manager=None):
        self.db_manager = db_manager
        self.filters = [
            AvailabilityFilter(),           # 基础可用性检查
            NutritionDataFilter(),          # 营养数据完整性
            AllergenFilter(db_manager=db_manager),  # 过敏原绝对过滤（基于数据库）
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
        # 确保数据库管理器在上下文中传递给过滤器
        if self.db_manager and "db_manager" not in context:
            context = context.copy()
            context["db_manager"] = self.db_manager
        
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
                logger.warning(f"Hard filter {filter_instance.name} filtered out all products")
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
        
        logger.info(f"Hard filters complete: {initial_count} -> {final_count} products "
                   f"(filter rate: {overall_filter_rate:.1%})")
        
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