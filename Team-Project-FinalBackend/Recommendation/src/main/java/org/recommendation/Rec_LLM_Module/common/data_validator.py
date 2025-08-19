"""
数据验证和清洗器
支持多种请求类型的数据验证、清洗和安全检查
"""

import re
import json
import logging
from typing import Dict, List, Optional, Any, Union
from dataclasses import dataclass
from datetime import datetime
from enum import Enum

logger = logging.getLogger(__name__)

class ValidationSeverity(Enum):
    """验证严重程度"""
    ERROR = "error"      # 阻止请求处理
    WARNING = "warning"  # 记录但继续处理
    INFO = "info"       # 信息性提示

@dataclass
class ValidationIssue:
    """验证问题"""
    field: str
    severity: ValidationSeverity
    message: str
    suggested_fix: Optional[str] = None

@dataclass
class ValidationResult:
    """验证结果"""
    is_valid: bool
    cleaned_data: Dict[str, Any]
    issues: List[ValidationIssue]
    
    @property
    def errors(self) -> List[ValidationIssue]:
        """获取错误级别的问题"""
        return [issue for issue in self.issues if issue.severity == ValidationSeverity.ERROR]
    
    @property
    def warnings(self) -> List[ValidationIssue]:
        """获取警告级别的问题"""
        return [issue for issue in self.issues if issue.severity == ValidationSeverity.WARNING]
    
    @property
    def has_errors(self) -> bool:
        """是否有错误"""
        return len(self.errors) > 0

class DataValidator:
    """数据验证和清洗器"""
    
    # 常用正则表达式
    BARCODE_PATTERN = re.compile(r'^[0-9]{8,14}$')
    EMAIL_PATTERN = re.compile(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
    PHONE_PATTERN = re.compile(r'^\+?[1-9]\d{1,14}$')
    
    # 安全关键词检测
    SECURITY_KEYWORDS = [
        'script', 'javascript', 'eval', 'exec', 'system', 'cmd',
        'drop', 'delete', 'truncate', 'insert', 'update', 'union',
        '<script', '</script>', 'onload', 'onerror', 'onclick'
    ]
    
    # 营养成分有效范围
    NUTRITION_RANGES = {
        'energy_kcal_100g': (0, 9000),      # 每100g热量
        'proteins_100g': (0, 100),          # 每100g蛋白质
        'fat_100g': (0, 100),               # 每100g脂肪
        'carbohydrates_100g': (0, 100),     # 每100g碳水化合物
        'sugars_100g': (0, 100),            # 每100g糖分
        'fiber_100g': (0, 50),              # 每100g纤维
        'sodium_100g': (0, 10000),          # 每100g钠含量(mg)
        'calcium_100g': (0, 5000),          # 每100g钙含量(mg)
        'vitamin_c_100g': (0, 1000)         # 每100g维生素C(mg)
    }
    
    @classmethod
    def validate_barcode_request(cls, request: Dict[str, Any]) -> ValidationResult:
        """验证条码推荐请求"""
        issues = []
        cleaned_data = {}
        
        # 用户ID验证
        user_id = request.get('userId')
        if user_id is None:
            issues.append(ValidationIssue(
                field='userId',
                severity=ValidationSeverity.ERROR,
                message='用户ID不能为空',
                suggested_fix='请提供有效的用户ID'
            ))
        elif not isinstance(user_id, int) or user_id <= 0:
            issues.append(ValidationIssue(
                field='userId',
                severity=ValidationSeverity.ERROR,
                message='用户ID必须为正整数',
                suggested_fix='请提供有效的正整数用户ID'
            ))
        else:
            cleaned_data['userId'] = user_id
        
        # 条码验证
        barcode = request.get('productBarcode', '').strip()
        if not barcode:
            issues.append(ValidationIssue(
                field='productBarcode',
                severity=ValidationSeverity.ERROR,
                message='商品条码不能为空',
                suggested_fix='请提供有效的商品条码'
            ))
        elif not cls.BARCODE_PATTERN.match(barcode):
            issues.append(ValidationIssue(
                field='productBarcode',
                severity=ValidationSeverity.ERROR,
                message='条码格式不正确，必须为8-14位数字',
                suggested_fix='请提供有效的8-14位数字条码'
            ))
        else:
            cleaned_data['productBarcode'] = barcode
        
        # 可选字段验证
        # 用户偏好验证
        user_preferences = request.get('userPreferences', {})
        if user_preferences:
            cleaned_preferences = cls._validate_user_preferences(user_preferences)
            if cleaned_preferences['issues']:
                issues.extend(cleaned_preferences['issues'])
            cleaned_data['userPreferences'] = cleaned_preferences['data']
        
        # 上下文信息验证
        context = request.get('context', {})
        if context:
            cleaned_context = cls._validate_context_info(context)
            if cleaned_context['issues']:
                issues.extend(cleaned_context['issues'])
            cleaned_data['context'] = cleaned_context['data']
        
        return ValidationResult(
            is_valid=not any(issue.severity == ValidationSeverity.ERROR for issue in issues),
            cleaned_data=cleaned_data,
            issues=issues
        )
    
    @classmethod
    def validate_receipt_request(cls, request: Dict[str, Any]) -> ValidationResult:
        """验证小票推荐请求"""
        issues = []
        cleaned_data = {}
        
        # 用户ID验证
        user_id = request.get('userId')
        if user_id is None:
            issues.append(ValidationIssue(
                field='userId',
                severity=ValidationSeverity.ERROR,
                message='用户ID不能为空'
            ))
        elif not isinstance(user_id, int) or user_id <= 0:
            issues.append(ValidationIssue(
                field='userId',
                severity=ValidationSeverity.ERROR,
                message='用户ID必须为正整数'
            ))
        else:
            cleaned_data['userId'] = user_id
        
        # 购买商品列表验证
        purchased_items = request.get('purchasedItems', [])
        if not purchased_items:
            issues.append(ValidationIssue(
                field='purchasedItems',
                severity=ValidationSeverity.ERROR,
                message='购买商品列表不能为空'
            ))
        elif not isinstance(purchased_items, list):
            issues.append(ValidationIssue(
                field='purchasedItems',
                severity=ValidationSeverity.ERROR,
                message='购买商品列表必须为数组格式'
            ))
        else:
            cleaned_items = []
            for i, item in enumerate(purchased_items):
                item_validation = cls._validate_purchased_item(item, i)
                if item_validation['issues']:
                    issues.extend(item_validation['issues'])
                if item_validation['data']:
                    cleaned_items.append(item_validation['data'])
            
            if not cleaned_items:
                issues.append(ValidationIssue(
                    field='purchasedItems',
                    severity=ValidationSeverity.ERROR,
                    message='没有有效的购买商品'
                ))
            else:
                cleaned_data['purchasedItems'] = cleaned_items
        
        # 小票信息验证（可选）
        receipt_info = request.get('receiptInfo', {})
        if receipt_info:
            cleaned_receipt = cls._validate_receipt_info(receipt_info)
            if cleaned_receipt['issues']:
                issues.extend(cleaned_receipt['issues'])
            cleaned_data['receiptInfo'] = cleaned_receipt['data']
        
        return ValidationResult(
            is_valid=not any(issue.severity == ValidationSeverity.ERROR for issue in issues),
            cleaned_data=cleaned_data,
            issues=issues
        )
    
    @classmethod
    def validate_nutrition_data(cls, nutrition: Dict[str, Any]) -> ValidationResult:
        """验证营养成分数据"""
        issues = []
        cleaned_data = {}
        
        for field, value in nutrition.items():
            if field in cls.NUTRITION_RANGES:
                min_val, max_val = cls.NUTRITION_RANGES[field]
                
                # 类型转换
                try:
                    numeric_value = float(value) if value is not None else None
                except (ValueError, TypeError):
                    issues.append(ValidationIssue(
                        field=field,
                        severity=ValidationSeverity.WARNING,
                        message=f'营养成分 {field} 不是有效数值',
                        suggested_fix='请提供数值类型的营养成分数据'
                    ))
                    continue
                
                # 范围检查
                if numeric_value is not None:
                    if numeric_value < min_val:
                        issues.append(ValidationIssue(
                            field=field,
                            severity=ValidationSeverity.WARNING,
                            message=f'营养成分 {field} 值过小: {numeric_value}',
                            suggested_fix=f'建议值应大于等于 {min_val}'
                        ))
                        cleaned_data[field] = min_val
                    elif numeric_value > max_val:
                        issues.append(ValidationIssue(
                            field=field,
                            severity=ValidationSeverity.WARNING,
                            message=f'营养成分 {field} 值过大: {numeric_value}',
                            suggested_fix=f'建议值应小于等于 {max_val}'
                        ))
                        cleaned_data[field] = max_val
                    else:
                        cleaned_data[field] = numeric_value
            else:
                # 未知营养成分字段
                cleaned_data[field] = value
                issues.append(ValidationIssue(
                    field=field,
                    severity=ValidationSeverity.INFO,
                    message=f'未知的营养成分字段: {field}'
                ))
        
        return ValidationResult(
            is_valid=True,  # 营养数据验证不阻止处理
            cleaned_data=cleaned_data,
            issues=issues
        )
    
    @classmethod
    def validate_product_data(cls, product: Dict[str, Any]) -> ValidationResult:
        """验证商品数据"""
        issues = []
        cleaned_data = {}
        
        # 商品名称验证
        product_name = product.get('productName', '').strip()
        if not product_name:
            issues.append(ValidationIssue(
                field='productName',
                severity=ValidationSeverity.WARNING,
                message='商品名称为空'
            ))
        else:
            # 安全检查
            if cls._contains_security_keywords(product_name):
                issues.append(ValidationIssue(
                    field='productName',
                    severity=ValidationSeverity.ERROR,
                    message='商品名称包含不安全内容'
                ))
            else:
                cleaned_data['productName'] = product_name
        
        # 品牌验证
        brand = product.get('brand', '').strip()
        if brand:
            if cls._contains_security_keywords(brand):
                issues.append(ValidationIssue(
                    field='brand',
                    severity=ValidationSeverity.ERROR,
                    message='品牌信息包含不安全内容'
                ))
            else:
                cleaned_data['brand'] = brand
        
        # 分类验证
        categories = product.get('categories', [])
        if categories:
            if isinstance(categories, list):
                cleaned_categories = []
                for category in categories:
                    if isinstance(category, str) and not cls._contains_security_keywords(category):
                        cleaned_categories.append(category.strip())
                cleaned_data['categories'] = cleaned_categories
            else:
                issues.append(ValidationIssue(
                    field='categories',
                    severity=ValidationSeverity.WARNING,
                    message='商品分类应为数组格式'
                ))
        
        # 营养数据验证
        nutrition = product.get('nutrition', {})
        if nutrition:
            nutrition_validation = cls.validate_nutrition_data(nutrition)
            cleaned_data['nutrition'] = nutrition_validation.cleaned_data
            issues.extend(nutrition_validation.issues)
        
        return ValidationResult(
            is_valid=not any(issue.severity == ValidationSeverity.ERROR for issue in issues),
            cleaned_data=cleaned_data,
            issues=issues
        )
    
    @classmethod
    def _validate_user_preferences(cls, preferences: Dict[str, Any]) -> Dict[str, Any]:
        """验证用户偏好数据"""
        issues = []
        cleaned_data = {}
        
        # 健康目标验证
        health_goal = preferences.get('healthGoal', '').strip()
        if health_goal:
            if cls._contains_security_keywords(health_goal):
                issues.append(ValidationIssue(
                    field='healthGoal',
                    severity=ValidationSeverity.ERROR,
                    message=f'健康目标包含不安全内容: {health_goal}',
                    suggested_fix='请提供有效的健康目标'
                ))
            else:
                health_goal_lower = health_goal.lower()
                valid_goals = ['lose_weight', 'gain_muscle', 'maintain', 'general_health']
                if health_goal_lower in valid_goals:
                    cleaned_data['healthGoal'] = health_goal_lower
                else:
                    issues.append(ValidationIssue(
                        field='healthGoal',
                        severity=ValidationSeverity.WARNING,
                        message=f'无效的健康目标: {health_goal}',
                        suggested_fix=f'有效值: {", ".join(valid_goals)}'
                    ))
        
        # 过敏原验证
        allergens = preferences.get('allergens', [])
        if allergens and isinstance(allergens, list):
            cleaned_allergens = []
            for allergen in allergens:
                if isinstance(allergen, str):
                    if cls._contains_security_keywords(allergen):
                        issues.append(ValidationIssue(
                            field='allergens',
                            severity=ValidationSeverity.ERROR,
                            message=f'过敏原信息包含不安全内容: {allergen}',
                            suggested_fix='请提供有效的过敏原信息'
                        ))
                    else:
                        cleaned_allergens.append(allergen.strip())
            cleaned_data['allergens'] = cleaned_allergens
        
        # 饮食限制验证
        dietary_restrictions = preferences.get('dietaryRestrictions', [])
        if dietary_restrictions and isinstance(dietary_restrictions, list):
            valid_restrictions = ['vegetarian', 'vegan', 'halal', 'kosher', 'gluten_free', 'dairy_free']
            cleaned_restrictions = []
            for restriction in dietary_restrictions:
                if restriction in valid_restrictions:
                    cleaned_restrictions.append(restriction)
                else:
                    issues.append(ValidationIssue(
                        field='dietaryRestrictions',
                        severity=ValidationSeverity.WARNING,
                        message=f'无效的饮食限制: {restriction}'
                    ))
            cleaned_data['dietaryRestrictions'] = cleaned_restrictions
        
        return {'data': cleaned_data, 'issues': issues}
    
    @classmethod
    def _validate_context_info(cls, context: Dict[str, Any]) -> Dict[str, Any]:
        """验证上下文信息"""
        issues = []
        cleaned_data = {}
        
        # 购物场景验证
        shopping_context = context.get('shoppingContext', '').strip()
        valid_contexts = ['daily_shopping', 'special_occasion', 'bulk_buying', 'healthy_eating']
        if shopping_context and shopping_context in valid_contexts:
            cleaned_data['shoppingContext'] = shopping_context
        elif shopping_context:
            issues.append(ValidationIssue(
                field='shoppingContext',
                severity=ValidationSeverity.INFO,
                message=f'未知的购物场景: {shopping_context}'
            ))
        
        # 时间上下文验证
        time_context = context.get('timeContext')
        if time_context:
            try:
                # 尝试解析为datetime
                if isinstance(time_context, str):
                    datetime.fromisoformat(time_context.replace('Z', '+00:00'))
                cleaned_data['timeContext'] = time_context
            except ValueError:
                issues.append(ValidationIssue(
                    field='timeContext',
                    severity=ValidationSeverity.WARNING,
                    message='时间上下文格式无效',
                    suggested_fix='请使用ISO格式时间字符串'
                ))
        
        return {'data': cleaned_data, 'issues': issues}
    
    @classmethod
    def _validate_purchased_item(cls, item: Dict[str, Any], index: int) -> Dict[str, Any]:
        """验证购买商品项"""
        issues = []
        cleaned_data = {}
        
        if not isinstance(item, dict):
            issues.append(ValidationIssue(
                field=f'purchasedItems[{index}]',
                severity=ValidationSeverity.ERROR,
                message=f'商品项 {index + 1} 格式错误，应为对象'
            ))
            return {'data': None, 'issues': issues}
        
        # 条码验证
        barcode = item.get('barcode', '').strip()
        if not barcode:
            issues.append(ValidationIssue(
                field=f'purchasedItems[{index}].barcode',
                severity=ValidationSeverity.WARNING,
                message=f'商品项 {index + 1} 缺少条码'
            ))
        elif not cls.BARCODE_PATTERN.match(barcode):
            issues.append(ValidationIssue(
                field=f'purchasedItems[{index}].barcode',
                severity=ValidationSeverity.WARNING,
                message=f'商品项 {index + 1} 条码格式无效'
            ))
        else:
            cleaned_data['barcode'] = barcode
        
        # 数量验证
        quantity = item.get('quantity', 1)
        try:
            quantity = int(quantity) if quantity is not None else 1
            if quantity <= 0:
                quantity = 1
                issues.append(ValidationIssue(
                    field=f'purchasedItems[{index}].quantity',
                    severity=ValidationSeverity.WARNING,
                    message=f'商品项 {index + 1} 数量无效，已设为1'
                ))
        except (ValueError, TypeError):
            quantity = 1
            issues.append(ValidationIssue(
                field=f'purchasedItems[{index}].quantity',
                severity=ValidationSeverity.WARNING,
                message=f'商品项 {index + 1} 数量格式错误，已设为1'
            ))
        
        cleaned_data['quantity'] = quantity
        
        # 价格验证（可选）
        price = item.get('price')
        if price is not None:
            try:
                price = float(price)
                if price < 0:
                    issues.append(ValidationIssue(
                        field=f'purchasedItems[{index}].price',
                        severity=ValidationSeverity.WARNING,
                        message=f'商品项 {index + 1} 价格不能为负数'
                    ))
                else:
                    cleaned_data['price'] = price
            except (ValueError, TypeError):
                issues.append(ValidationIssue(
                    field=f'purchasedItems[{index}].price',
                    severity=ValidationSeverity.WARNING,
                    message=f'商品项 {index + 1} 价格格式无效'
                ))
        
        return {'data': cleaned_data if cleaned_data else None, 'issues': issues}
    
    @classmethod
    def _validate_receipt_info(cls, receipt_info: Dict[str, Any]) -> Dict[str, Any]:
        """验证小票信息"""
        issues = []
        cleaned_data = {}
        
        # 商店信息验证
        store_name = receipt_info.get('storeName', '').strip()
        if store_name:
            if cls._contains_security_keywords(store_name):
                issues.append(ValidationIssue(
                    field='receiptInfo.storeName',
                    severity=ValidationSeverity.ERROR,
                    message='商店名称包含不安全内容'
                ))
            else:
                cleaned_data['storeName'] = store_name
        
        # 总金额验证
        total_amount = receipt_info.get('totalAmount')
        if total_amount is not None:
            try:
                total_amount = float(total_amount)
                if total_amount < 0:
                    issues.append(ValidationIssue(
                        field='receiptInfo.totalAmount',
                        severity=ValidationSeverity.WARNING,
                        message='总金额不能为负数'
                    ))
                else:
                    cleaned_data['totalAmount'] = total_amount
            except (ValueError, TypeError):
                issues.append(ValidationIssue(
                    field='receiptInfo.totalAmount',
                    severity=ValidationSeverity.WARNING,
                    message='总金额格式无效'
                ))
        
        # 购买日期验证
        purchase_date = receipt_info.get('purchaseDate')
        if purchase_date:
            try:
                if isinstance(purchase_date, str):
                    datetime.fromisoformat(purchase_date.replace('Z', '+00:00'))
                cleaned_data['purchaseDate'] = purchase_date
            except ValueError:
                issues.append(ValidationIssue(
                    field='receiptInfo.purchaseDate',
                    severity=ValidationSeverity.WARNING,
                    message='购买日期格式无效'
                ))
        
        return {'data': cleaned_data, 'issues': issues}
    
    @classmethod
    def _contains_security_keywords(cls, text: str) -> bool:
        """检查文本是否包含安全关键词"""
        text_lower = text.lower()
        return any(keyword in text_lower for keyword in cls.SECURITY_KEYWORDS)
    
    @classmethod
    def sanitize_text_input(cls, text: str, max_length: int = 1000) -> str:
        """清理文本输入"""
        if not isinstance(text, str):
            return ""
        
        # 移除HTML标签
        text = re.sub(r'<[^>]*>', '', text)
        
        # 移除SQL注入风险字符
        text = re.sub(r'[\'";\\]', '', text)
        
        # 移除脚本标签
        text = re.sub(r'<script.*?</script>', '', text, flags=re.IGNORECASE | re.DOTALL)
        
        # 限制长度
        if len(text) > max_length:
            text = text[:max_length]
        
        return text.strip()
    
    @classmethod
    def validate_request_size(cls, request_data: Dict[str, Any], max_size_mb: float = 5.0) -> ValidationResult:
        """验证请求大小"""
        try:
            # 序列化请求数据以计算大小
            json_str = json.dumps(request_data, ensure_ascii=False)
            size_bytes = len(json_str.encode('utf-8'))
            size_mb = size_bytes / (1024 * 1024)
            
            if size_mb > max_size_mb:
                return ValidationResult(
                    is_valid=False,
                    cleaned_data={},
                    issues=[ValidationIssue(
                        field='request',
                        severity=ValidationSeverity.ERROR,
                        message=f'请求数据过大: {size_mb:.2f}MB，最大允许: {max_size_mb}MB'
                    )]
                )
            
            return ValidationResult(
                is_valid=True,
                cleaned_data={'size_mb': size_mb},
                issues=[]
            )
            
        except Exception as e:
            return ValidationResult(
                is_valid=False,
                cleaned_data={},
                issues=[ValidationIssue(
                    field='request',
                    severity=ValidationSeverity.ERROR,
                    message=f'请求数据格式错误: {str(e)}'
                )]
            )

# 便捷函数
def validate_recommendation_request(request_type: str, request_data: Dict[str, Any]) -> ValidationResult:
    """便捷的推荐请求验证函数"""
    # 首先检查请求大小
    size_validation = DataValidator.validate_request_size(request_data)
    if not size_validation.is_valid:
        return size_validation
    
    # 根据请求类型进行验证
    if request_type == 'barcode_recommendation':
        return DataValidator.validate_barcode_request(request_data)
    elif request_type == 'receipt_analysis':
        return DataValidator.validate_receipt_request(request_data)
    elif request_type == 'product_validation':
        return DataValidator.validate_product_data(request_data)
    else:
        return ValidationResult(
            is_valid=False,
            cleaned_data={},
            issues=[ValidationIssue(
                field='requestType',
                severity=ValidationSeverity.ERROR,
                message=f'不支持的请求类型: {request_type}'
            )]
        )