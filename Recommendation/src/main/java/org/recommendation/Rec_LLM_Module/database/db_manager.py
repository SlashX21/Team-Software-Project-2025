"""
数据库管理器 - 适配器模式实现
支持SQLite到SQL Server的无痛迁移
"""

import logging
from abc import ABC, abstractmethod
from typing import Dict, List, Optional, Any, Union
from datetime import datetime
import sqlite3
import json
from dataclasses import dataclass, field
import os

from config.settings import get_database_config, DatabaseConfig
from config.constants import AllergenPresenceType, PreferenceType

logger = logging.getLogger(__name__)

class DatabaseAdapter(ABC):
    """数据库适配器抽象基类"""
    
    def __init__(self, config: DatabaseConfig):
        self.config = config
        self.connection = None
        
    @abstractmethod
    def connect(self) -> bool:
        """建立数据库连接"""
        pass
    
    @abstractmethod
    def disconnect(self) -> None:
        """断开数据库连接"""
        pass
    
    # 商品相关操作
    @abstractmethod
    def get_product_by_barcode(self, barcode: str) -> Optional[Dict]:
        """根据条形码查询商品信息"""
        pass
    
    @abstractmethod
    def get_products_by_category(self, category: str, limit: int = 100) -> List[Dict]:
        """查询指定分类的商品列表"""
        pass
    
    @abstractmethod
    def search_products_by_nutrition(self, filters: Dict) -> List[Dict]:
        """根据营养条件筛选商品"""
        pass
    
    # 用户相关操作
    @abstractmethod
    def get_user_profile(self, user_id: int) -> Optional[Dict]:
        """获取用户完整画像"""
        pass
    
    @abstractmethod
    def get_user_allergens(self, user_id: int) -> List[Dict]:
        """获取用户过敏原列表"""
        pass
    
    @abstractmethod
    def get_user_preferences(self, user_id: int) -> Optional[Dict]:
        """获取用户动态偏好"""
        pass
    
    # 购买历史操作
    @abstractmethod
    def get_purchase_history(self, user_id: int, days: int = 90) -> List[Dict]:
        """获取用户购买历史记录"""
        pass
    
    @abstractmethod
    def get_user_purchase_matrix(self, user_id: int) -> Dict:
        """获取用户-商品购买矩阵（用于协同过滤）"""
        pass
    
    # 过敏原管理操作
    @abstractmethod
    def check_product_allergens(self, barcode: str, user_allergens: List[int]) -> Dict:
        """检查商品是否包含用户过敏原"""
        pass
    
    @abstractmethod
    def get_allergen_by_name(self, allergen_name: str) -> Optional[Dict]:
        """根据名称查询过敏原信息"""
        pass
    
    # 日志记录操作
    @abstractmethod
    def log_recommendation(self, log_data: Dict) -> bool:
        """记录推荐请求和结果"""
        pass
    
    @abstractmethod
    def get_recommendation_stats(self, user_id: int) -> Dict:
        """获取用户推荐统计信息"""
        pass

class SQLiteAdapter(DatabaseAdapter):
    """SQLite数据库适配器实现"""
    
    def __init__(self, config: DatabaseConfig):
        super().__init__(config)
        self.db_path = config.connection_string.replace("sqlite:///", "")
        
    def connect(self) -> bool:
        try:
            self.connection = sqlite3.connect(
                self.db_path,
                timeout=self.config.timeout,
                check_same_thread=False
            )
            self.connection.row_factory = sqlite3.Row
            return True
        except Exception as e:
            logger.error(f"SQLite连接失败: {e}")
            return False

    def disconnect(self) -> None:
        """断开SQLite连接"""
        if self.connection:
            self.connection.close()
            self.connection = None
            logger.info("SQLite database connection closed")
    
    def get_product_by_barcode(self, barcode: str) -> Optional[Dict]:
        """根据条形码查询商品信息"""
        try:
            cursor = self.connection.cursor()
            query = """
            SELECT bar_code, product_name, brand, ingredients, allergens,
                   energy_100g, energy_kcal_100g, fat_100g, saturated_fat_100g,
                   carbohydrates_100g, sugars_100g, proteins_100g,
                   serving_size, category, created_at, updated_at
            FROM product 
            WHERE bar_code = ?
            """
            
            cursor.execute(query, (barcode,))
            row = cursor.fetchone()
            
            if row:
                return dict(row)
            return None
            
        except Exception as e:
            logger.error(f"查询商品失败 {barcode}: {e}")
            return None
    
    def get_products_by_category(self, category: str, limit: int = 100) -> List[Dict]:
        """查询指定分类的商品列表"""
        try:
            cursor = self.connection.cursor()
            query = """
            SELECT bar_code, product_name, brand, category,
                   energy_kcal_100g, proteins_100g, fat_100g, sugars_100g,
                   carbohydrates_100g
            FROM product 
            WHERE category = ?
            ORDER BY product_name
            LIMIT ?
            """
            
            cursor.execute(query, (category, limit))
            rows = cursor.fetchall()
            
            # 后处理：确保营养数据不为None
            products = []
            for row in rows:
                product = dict(row)
                # 将None值替换为0
                nutrition_fields = [
                    "energy_kcal_100g", "proteins_100g", "fat_100g", 
                    "sugars_100g", "carbohydrates_100g"
                ]
                for field in nutrition_fields:
                    if product.get(field) is None:
                        product[field] = 0.0
                products.append(product)
            
            return products
            
        except Exception as e:
            logger.error(f"查询分类商品失败 {category}: {e}")
            return []
    
    def search_products_by_nutrition(self, filters: Dict) -> List[Dict]:
        """根据营养条件筛选商品"""
        try:
            cursor = self.connection.cursor()
            
            # 构建动态查询条件
            conditions = []
            params = []
            
            if "min_protein" in filters:
                conditions.append("proteins_100g >= ?")
                params.append(filters["min_protein"])
                
            if "max_calories" in filters:
                conditions.append("energy_kcal_100g <= ?")
                params.append(filters["max_calories"])
                
            if "max_fat" in filters:
                conditions.append("fat_100g <= ?")
                params.append(filters["max_fat"])
                
            if "max_sugar" in filters:
                conditions.append("sugars_100g <= ?")
                params.append(filters["max_sugar"])
                
            if "category" in filters:
                conditions.append("category = ?")
                params.append(filters["category"])
            
            where_clause = " AND ".join(conditions) if conditions else "1=1"
            
            query = f"""
            SELECT bar_code, product_name, brand, category,
                   energy_kcal_100g, proteins_100g, fat_100g, sugars_100g
            FROM product 
            WHERE {where_clause}
            ORDER BY energy_kcal_100g, proteins_100g DESC
            LIMIT ?
            """
            
            params.append(filters.get("limit", 50))
            cursor.execute(query, params)
            rows = cursor.fetchall()
            
            return [dict(row) for row in rows]
            
        except Exception as e:
            logger.error(f"营养筛选查询失败: {e}")
            return []
    
    def get_user_profile(self, user_id: int) -> Optional[Dict]:
        """获取用户完整画像"""
        try:
            cursor = self.connection.cursor()
            query = """
            SELECT user_id, user_name, email, age, gender, height_cm, weight_kg,
                   activity_level, nutrition_goal, daily_calories_target,
                   daily_protein_target, daily_carb_target, daily_fat_target,
                   created_time
            FROM user 
            WHERE user_id = ?
            """
            
            cursor.execute(query, (user_id,))
            row = cursor.fetchone()
            
            if row:
                return dict(row)
            return None
            
        except Exception as e:
            logger.error(f"查询用户画像失败 {user_id}: {e}")
            return None
    
    def get_user_allergens(self, user_id: int) -> List[Dict]:
        """获取用户过敏原列表"""
        try:
            cursor = self.connection.cursor()
            query = """
            SELECT ua.user_allergen_id, ua.user_id, ua.allergen_id,
                   ua.severity_level, ua.confirmed, ua.notes,
                   a.name, a.category, a.is_common, a.description
            FROM user_allergen ua
            JOIN allergen a ON ua.allergen_id = a.allergen_id
            WHERE ua.user_id = ? AND ua.confirmed = 1
            ORDER BY ua.severity_level DESC, a.name
            """
            
            cursor.execute(query, (user_id,))
            rows = cursor.fetchall()
            
            return [dict(row) for row in rows]
            
        except Exception as e:
            logger.error(f"查询用户过敏原失败 {user_id}: {e}")
            return []
    
    def get_user_preferences(self, user_id: int) -> Optional[Dict]:
        """获取用户动态偏好"""
        try:
            cursor = self.connection.cursor()
            query = """
            SELECT preference_id, user_id, prefer_low_sugar, prefer_low_fat,
                   prefer_high_protein, prefer_low_sodium, prefer_organic,
                   prefer_low_calorie, preference_source, inference_confidence,
                   version, updated_at
            FROM user_preference 
            WHERE user_id = ?
            ORDER BY version DESC
            LIMIT 1
            """
            
            cursor.execute(query, (user_id,))
            row = cursor.fetchone()
            
            if row:
                return dict(row)
            return None
            
        except Exception as e:
            logger.error(f"查询用户偏好失败 {user_id}: {e}")
            return None
    
    def get_purchase_history(self, user_id: int, days: int = 90) -> List[Dict]:
        """获取用户购买历史记录"""
        try:
            cursor = self.connection.cursor()
            query = """
            SELECT pr.purchase_id, pr.user_id, pr.receipt_date, pr.store_name,
                   pr.total_amount, pi.item_id, pi.bar_code, pi.item_name_ocr,
                   pi.quantity, pi.unit_price, pi.total_price,
                   p.product_name, p.brand, p.category, p.energy_kcal_100g, p.proteins_100g
            FROM purchase_record pr
            JOIN purchase_item pi ON pr.purchase_id = pi.purchase_id
            LEFT JOIN product p ON pi.bar_code = p.bar_code
            WHERE pr.user_id = ? 
              AND pr.receipt_date >= date('now', '-{} days')
            ORDER BY pr.receipt_date DESC, pr.purchase_id, pi.item_id
            """.format(days)
            
            cursor.execute(query, (user_id,))
            rows = cursor.fetchall()
            
            return [dict(row) for row in rows]
            
        except Exception as e:
            logger.error(f"查询购买历史失败 {user_id}: {e}")
            return []
    
    def get_user_purchase_matrix(self, user_id: int) -> Dict:
        """获取用户-商品购买矩阵（用于协同过滤）"""
        try:
            cursor = self.connection.cursor()
            
            # 获取用户购买的商品及权重
            query = """
            SELECT pi.bar_code, p.product_name, p.category,
                   SUM(pi.quantity) as total_quantity,
                   COUNT(DISTINCT pr.purchase_id) as purchase_frequency,
                   MAX(pr.receipt_date) as last_purchase_date
            FROM purchase_record pr
            JOIN purchase_item pi ON pr.purchase_id = pi.purchase_id
            LEFT JOIN product p ON pi.bar_code = p.bar_code
            WHERE pr.user_id = ?
            GROUP BY pi.bar_code, p.product_name, p.category
            ORDER BY total_quantity DESC, purchase_frequency DESC
            """
            
            cursor.execute(query, (user_id,))
            rows = cursor.fetchall()
            
            # 计算相似用户（基于共同购买商品）
            similar_users_query = """
            SELECT pr2.user_id, COUNT(DISTINCT pi2.bar_code) as common_products
            FROM purchase_record pr1
            JOIN purchase_item pi1 ON pr1.purchase_id = pi1.purchase_id
            JOIN purchase_item pi2 ON pi1.bar_code = pi2.bar_code
            JOIN purchase_record pr2 ON pi2.purchase_id = pr2.purchase_id
            WHERE pr1.user_id = ? AND pr2.user_id != ?
            GROUP BY pr2.user_id
            HAVING common_products >= 3
            ORDER BY common_products DESC
            LIMIT 10
            """
            
            cursor.execute(similar_users_query, (user_id, user_id))
            similar_users = cursor.fetchall()
            
            return {
                "user_id": user_id,
                "purchased_products": [dict(row) for row in rows],
                "similar_users": [dict(row) for row in similar_users],
                "matrix_generated_at": datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.error(f"生成购买矩阵失败 {user_id}: {e}")
            return {"user_id": user_id, "purchased_products": [], "similar_users": []}
    
    def check_product_allergens(self, barcode: str, user_allergens: List[int]) -> Dict:
        """检查商品是否包含用户过敏原"""
        try:
            if not user_allergens:
                return {"safe": True, "detected_allergens": [], "warnings": []}
            
            cursor = self.connection.cursor()
            
            # 查询商品包含的过敏原
            placeholders = ",".join("?" * len(user_allergens))
            query = f"""
            SELECT pa.allergen_id, pa.presence_type, pa.confidence_score,
                   a.name, a.category, a.description
            FROM product_allergen pa
            JOIN allergen a ON pa.allergen_id = a.allergen_id
            WHERE pa.bar_code = ? AND pa.allergen_id IN ({placeholders})
            ORDER BY pa.presence_type, a.name
            """
            
            params = [barcode] + user_allergens
            cursor.execute(query, params)
            rows = cursor.fetchall()
            
            detected_allergens = []
            warnings = []
            
            for row in rows:
                allergen_info = dict(row)
                detected_allergens.append(allergen_info)
                
                # 根据包含类型生成警告
                if allergen_info["presence_type"] == AllergenPresenceType.CONTAINS.value:
                    warnings.append(f"警告：该商品含有{allergen_info['name']}")
                elif allergen_info["presence_type"] == AllergenPresenceType.MAY_CONTAIN.value:
                    warnings.append(f"注意：该商品可能含有{allergen_info['name']}")
                elif allergen_info["presence_type"] == AllergenPresenceType.TRACES.value:
                    warnings.append(f"提示：该商品可能含有痕量{allergen_info['name']}")
            
            return {
                "safe": len(detected_allergens) == 0,
                "detected_allergens": detected_allergens,
                "warnings": warnings,
                "checked_at": datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.error(f"过敏原检查失败 {barcode}: {e}")
            return {"safe": False, "detected_allergens": [], "warnings": ["过敏原检查失败"]}
    
    def get_allergen_by_name(self, allergen_name: str) -> Optional[Dict]:
        """根据名称查询过敏原信息"""
        try:
            cursor = self.connection.cursor()
            query = """
            SELECT allergen_id, name, category, is_common, description
            FROM allergen 
            WHERE name = ? OR name LIKE ?
            ORDER BY is_common DESC, name
            LIMIT 1
            """
            
            cursor.execute(query, (allergen_name, f"%{allergen_name}%"))
            row = cursor.fetchone()
            
            if row:
                return dict(row)
            return None
            
        except Exception as e:
            logger.error(f"查询过敏原失败 {allergen_name}: {e}")
            return None
    
    def log_recommendation(self, log_data: Dict) -> bool:
        """记录推荐请求和结果"""
        try:
            cursor = self.connection.cursor()
            query = """
            INSERT INTO recommendation_log (
                user_id, request_bar_code, request_type, recommended_products,
                algorithm_version, llm_prompt, llm_response, llm_analysis,
                processing_time_ms, total_candidates, filtered_candidates,
                created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """
            
            values = (
                log_data.get("user_id"),
                log_data.get("request_barcode"),
                log_data.get("request_type"),
                json.dumps(log_data.get("recommended_products", []), ensure_ascii=False),
                log_data.get("algorithm_version", "v1.0"),
                log_data.get("llm_prompt"),
                log_data.get("llm_response"),
                log_data.get("llm_analysis"),
                log_data.get("processing_time_ms", 0),
                log_data.get("total_candidates", 0),
                log_data.get("filtered_candidates", 0),
                datetime.now()
            )
            
            cursor.execute(query, values)
            self.connection.commit()
            
            logger.info(f"推荐日志记录成功: {cursor.lastrowid}")
            return True
            
        except Exception as e:
            logger.error(f"推荐日志记录失败: {e}")
            return False
    
    def get_recommendation_stats(self, user_id: int) -> Dict:
        """获取用户推荐统计信息"""
        try:
            cursor = self.connection.cursor()
            
            # 基础统计
            stats_query = """
            SELECT 
                COUNT(*) as total_recommendations,
                COUNT(DISTINCT request_bar_code) as unique_products_scanned,
                AVG(processing_time_ms) as avg_processing_time,
                MAX(created_at) as last_recommendation_time
            FROM recommendation_log 
            WHERE user_id = ?
            """
            
            cursor.execute(stats_query, (user_id,))
            stats = dict(cursor.fetchone())
            
            # 推荐类型分布
            type_query = """
            SELECT request_type, COUNT(*) as count
            FROM recommendation_log 
            WHERE user_id = ?
            GROUP BY request_type
            """
            
            cursor.execute(type_query, (user_id,))
            type_distribution = {row["request_type"]: row["count"] for row in cursor.fetchall()}
            
            return {
                "user_id": user_id,
                "stats": stats,
                "type_distribution": type_distribution,
                "generated_at": datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.error(f"获取推荐统计失败 {user_id}: {e}")
            return {"user_id": user_id, "stats": {}, "type_distribution": {}}

class MySQLAdapter(DatabaseAdapter):
    """MySQL数据库适配器实现 - 用于Java Liquibase集成"""
    
    def __init__(self, config: DatabaseConfig):
        super().__init__(config)
        try:
            import pymysql
            from sqlalchemy import create_engine, text
            from sqlalchemy.pool import QueuePool
            self.engine = create_engine(
                config.connection_string,
                poolclass=QueuePool,
                pool_size=config.pool_size,
                max_overflow=config.max_overflow,
                pool_timeout=config.timeout,
                echo=config.echo
            )
        except ImportError:
            raise ImportError("请安装MySQL依赖: pip install pymysql sqlalchemy")
    
    def connect(self) -> bool:
        try:
            self.connection = self.engine.connect()
            return True
        except Exception as e:
            logger.error(f"MySQL连接失败: {e}")
            return False
    
    def disconnect(self) -> None:
        if self.connection:
            self.connection.close()
            self.connection = None
            logger.info("MySQL database connection closed")
    
    def get_product_by_barcode(self, barcode: str) -> Optional[Dict]:
        """根据条形码查询商品信息"""
        try:
            from sqlalchemy import text
            query = text("""
            SELECT barcode as bar_code, name as product_name, brand, ingredients, allergens,
                   energy_100g, energy_kcal_100g, fat_100g, saturated_fat_100g,
                   carbohydrates_100g, sugars_100g, proteins_100g,
                   serving_size, category
            FROM product 
            WHERE barcode = :barcode
            """)
            
            result = self.connection.execute(query, {"barcode": barcode})
            row = result.fetchone()
            
            if row:
                return dict(row._mapping)
            return None
            
        except Exception as e:
            logger.error(f"MySQL查询商品失败 {barcode}: {e}")
            return None
    
    def get_products_by_category(self, category: str, limit: int = 100) -> List[Dict]:
        """查询指定分类的商品列表"""
        try:
            from sqlalchemy import text
            query = text("""
            SELECT barcode as bar_code, name as product_name, brand, category,
                   energy_kcal_100g, proteins_100g, fat_100g, sugars_100g,
                   carbohydrates_100g
            FROM product 
            WHERE category = :category
            ORDER BY name
            LIMIT :limit_val
            """)
            
            result = self.connection.execute(query, {"category": category, "limit_val": limit})
            rows = result.fetchall()
            
            products = []
            for row in rows:
                product = dict(row._mapping)
                # 将None值替换为0
                nutrition_fields = [
                    "energy_kcal_100g", "proteins_100g", "fat_100g", 
                    "sugars_100g", "carbohydrates_100g"
                ]
                for field in nutrition_fields:
                    if product.get(field) is None:
                        product[field] = 0.0
                products.append(product)
            
            return products
            
        except Exception as e:
            logger.error(f"MySQL查询分类商品失败 {category}: {e}")
            return []
    
    def search_products_by_nutrition(self, filters: Dict) -> List[Dict]:
        # MySQL实现逻辑与SQLite类似，使用SQLAlchemy text()
        pass
    
    def get_user_profile(self, user_id: int) -> Optional[Dict]:
        """获取用户完整画像"""
        try:
            from sqlalchemy import text
            query = text("""
            SELECT 
                user_id,
                username as user_name,
                email,
                age,
                gender,
                nutrition_goal,
                daily_calories_target,
                daily_protein_target,
                daily_carb_target,
                daily_fat_target,
                activity_level,
                height_cm,
                weight_kg
            FROM user 
            WHERE user_id = :user_id
            """)
            
            result = self.connection.execute(query, {"user_id": user_id})
            row = result.fetchone()
            
            if row:
                return dict(row._mapping)
            return None
            
        except Exception as e:
            logger.error(f"MySQL查询用户失败 {user_id}: {e}")
            return None
    
    def get_user_allergens(self, user_id: int) -> List[Dict]:
        """获取用户过敏原列表"""
        try:
            from sqlalchemy import text
            query = text("""
            SELECT 
                a.allergen_id, 
                a.name, 
                a.category, 
                a.description,
                ua.severity_level, 
                ua.confirmed, 
                ua.notes
            FROM user_allergen ua
            JOIN allergen a ON ua.allergen_id = a.allergen_id
            WHERE ua.user_id = :user_id AND ua.confirmed = 1
            ORDER BY ua.severity_level DESC, a.name
            """)
            
            result = self.connection.execute(query, {"user_id": user_id})
            rows = result.fetchall()
            return [dict(row._mapping) for row in rows]
            
        except Exception as e:
            logger.error(f"MySQL查询用户过敏原失败 {user_id}: {e}")
            return []
    
    def get_user_preferences(self, user_id: int) -> Optional[Dict]:
        """获取用户偏好设置"""
        try:
            from sqlalchemy import text
            query = text("""
            SELECT 
                preference_id, 
                user_id, 
                prefer_low_sugar, 
                prefer_low_fat,
                prefer_high_protein, 
                prefer_low_sodium, 
                prefer_organic,
                prefer_low_calorie, 
                preference_source, 
                inference_confidence,
                version, 
                updated_at
            FROM user_preference 
            WHERE user_id = :user_id
            ORDER BY version DESC
            LIMIT 1
            """)
            
            result = self.connection.execute(query, {"user_id": user_id})
            row = result.fetchone()
            
            if row:
                return dict(row._mapping)
            return None
            
        except Exception as e:
            logger.error(f"MySQL查询用户偏好失败 {user_id}: {e}")
            return None
    
    def get_purchase_history(self, user_id: int, days: int = 90) -> List[Dict]:
        """获取用户购买历史记录"""
        try:
            from sqlalchemy import text
            query = text("""
            SELECT 
                pi.barcode,
                p.name as product_name,
                p.category,
                pi.quantity,
                pi.total_price,
                pr.receipt_date
            FROM purchase_item pi
            JOIN purchase_record pr ON pi.purchase_id = pr.purchase_id
            LEFT JOIN product p ON pi.barcode = p.barcode
            WHERE pr.user_id = :user_id 
            AND pr.receipt_date >= DATE_SUB(NOW(), INTERVAL :days DAY)
            ORDER BY pr.receipt_date DESC
            """)
            
            result = self.connection.execute(query, {"user_id": user_id, "days": days})
            rows = result.fetchall()
            return [dict(row._mapping) for row in rows]
            
        except Exception as e:
            logger.error(f"MySQL查询购买历史失败 {user_id}: {e}")
            return []
    
    def get_user_purchase_matrix(self, user_id: int) -> Dict:
        """获取用户-商品购买矩阵（用于协同过滤）"""
        try:
            from sqlalchemy import text
            query = text("""
            SELECT 
                pi.barcode,
                p.name as product_name,
                SUM(pi.quantity) as total_quantity,
                COUNT(*) as purchase_count,
                AVG(pi.unit_price) as avg_price
            FROM purchase_item pi
            JOIN purchase_record pr ON pi.purchase_id = pr.purchase_id
            LEFT JOIN product p ON pi.barcode = p.barcode
            WHERE pr.user_id = :user_id
            GROUP BY pi.barcode, p.name
            ORDER BY total_quantity DESC
            """)
            
            result = self.connection.execute(query, {"user_id": user_id})
            rows = result.fetchall()
            
            matrix = {}
            for row in rows:
                row_dict = dict(row._mapping)
                matrix[row_dict['barcode']] = row_dict
            
            return matrix
            
        except Exception as e:
            logger.error(f"MySQL查询购买矩阵失败 {user_id}: {e}")
            return {}
    
    def check_product_allergens(self, barcode: str, user_allergens: List[int]) -> Dict:
        """检查商品是否包含用户过敏原"""
        try:
            from sqlalchemy import text
            if not user_allergens:
                return {"has_allergens": False, "allergen_details": []}
            
            allergen_ids_str = ','.join(map(str, user_allergens))
            query = text(f"""
            SELECT 
                pa.barcode,
                pa.allergen_id,
                a.name as allergen_name,
                pa.presence_type,
                pa.confidence_score
            FROM product_allergen pa
            JOIN allergen a ON pa.allergen_id = a.allergen_id
            WHERE pa.barcode = :barcode 
            AND pa.allergen_id IN ({allergen_ids_str})
            """)
            
            result = self.connection.execute(query, {"barcode": barcode})
            rows = result.fetchall()
            
            allergen_details = [dict(row._mapping) for row in rows]
            
            return {
                "has_allergens": len(allergen_details) > 0,
                "allergen_details": allergen_details
            }
            
        except Exception as e:
            logger.error(f"MySQL检查过敏原失败 {barcode}: {e}")
            return {"has_allergens": False, "allergen_details": []}
    
    def get_allergen_by_name(self, allergen_name: str) -> Optional[Dict]:
        """根据名称查询过敏原信息"""
        try:
            from sqlalchemy import text
            query = text("""
            SELECT allergen_id, name, category, is_common, description
            FROM allergen 
            WHERE name = :allergen_name
            """)
            
            result = self.connection.execute(query, {"allergen_name": allergen_name})
            row = result.fetchone()
            
            if row:
                return dict(row._mapping)
            return None
            
        except Exception as e:
            logger.error(f"MySQL查询过敏原失败 {allergen_name}: {e}")
            return None
    
    def log_recommendation(self, log_data: Dict) -> bool:
        """记录推荐请求和结果"""
        try:
            from sqlalchemy import text
            query = text("""
            INSERT INTO recommendation_log 
            (user_id, request_type, request_barcode, recommended_products, 
             llm_prompt, llm_response, llm_analysis, processing_time_ms, 
             total_candidates, filtered_candidates, algorithm_version, created_at)
            VALUES (:user_id, :request_type, :request_barcode, :recommended_products,
                    :llm_prompt, :llm_response, :llm_analysis, :processing_time_ms,
                    :total_candidates, :filtered_candidates, :algorithm_version, NOW())
            """)
            
            self.connection.execute(query, {
                "user_id": log_data.get("user_id"),
                "request_type": log_data.get("request_type", "BARCODE"),
                "request_barcode": log_data.get("request_barcode"),
                "recommended_products": json.dumps(log_data.get("recommended_products", {})),
                "llm_prompt": log_data.get("llm_prompt"),
                "llm_response": log_data.get("llm_response"),
                "llm_analysis": log_data.get("llm_analysis"),
                "processing_time_ms": log_data.get("processing_time_ms", 0),
                "total_candidates": log_data.get("total_candidates", 0),
                "filtered_candidates": log_data.get("filtered_candidates", 0),
                "algorithm_version": log_data.get("algorithm_version", "v1.0")
            })
            self.connection.commit()
            return True
            
        except Exception as e:
            logger.error(f"MySQL记录推荐日志失败: {e}")
            return False
    
    def get_recommendation_stats(self, user_id: int) -> Dict:
        """获取用户推荐统计信息"""
        try:
            from sqlalchemy import text
            query = text("""
            SELECT 
                COUNT(*) as total_recommendations,
                AVG(processing_time_ms) as avg_processing_time,
                MAX(created_at) as last_recommendation_time
            FROM recommendation_log 
            WHERE user_id = :user_id
            """)
            
            result = self.connection.execute(query, {"user_id": user_id})
            row = result.fetchone()
            
            if row:
                return dict(row._mapping)
            return {}
            
        except Exception as e:
            logger.error(f"MySQL查询推荐统计失败 {user_id}: {e}")
            return {}

class PostgreSQLAdapter(MySQLAdapter):
    """PostgreSQL数据库适配器实现 - 继承MySQL适配器"""
    
    def __init__(self, config: DatabaseConfig):
        try:
            import psycopg2
            from sqlalchemy import create_engine
            from sqlalchemy.pool import QueuePool
            self.config = config
            self.engine = create_engine(
                config.connection_string,
                poolclass=QueuePool,
                pool_size=config.pool_size,
                max_overflow=config.max_overflow,
                pool_timeout=config.timeout,
                echo=config.echo
            )
        except ImportError:
            raise ImportError("请安装PostgreSQL依赖: pip install psycopg2-binary sqlalchemy")

@dataclass
class DatabaseManager:
    """数据库管理器 - 适配器模式实现"""
    adapter: Optional[DatabaseAdapter] = None
    nutrition_strategies: Dict[str, Dict[str, float]] = field(default_factory=lambda: {
        "lose_weight": {
            "energy_kcal_100g": -0.4,
            "fat_100g": -0.3,
            "sugars_100g": -0.3,
            "proteins_100g": 0.2,
            "fiber_bonus": 0.3
        },
        "gain_muscle": {
            "proteins_100g": 0.5,
            "carbohydrates_100g": 0.2,
            "energy_kcal_100g": 0.3,
            "fat_100g": 0.1,
            "bcaa_bonus": 0.4
        },
        "maintain": {
            "balance_score": 0.4,
            "variety_score": 0.3,
            "natural_bonus": 0.3
        }
    })
    
    def __post_init__(self):
        """初始化数据库适配器"""
        if not self.adapter:
            config = get_database_config()
            if config.type == "sqlite":
                self.adapter = SQLiteAdapter(config)
            elif config.type == "mysql":
                self.adapter = MySQLAdapter(config)
            elif config.type == "postgresql":
                self.adapter = PostgreSQLAdapter(config)
            else:
                raise ValueError(f"不支持的数据库类型: {config.type}")
    
    def connect(self) -> bool:
        """连接数据库"""
        return self.adapter.connect()
    
    def disconnect(self) -> None:
        """断开数据库连接"""
        if self.adapter:
            self.adapter.disconnect()
    
    def __enter__(self):
        """上下文管理器入口"""
        self.connect()
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """上下文管理器出口"""
        self.disconnect()
    
    # 代理所有适配器方法
    def get_product_by_barcode(self, barcode: str) -> Optional[Dict]:
        return self.adapter.get_product_by_barcode(barcode)
    
    def get_products_by_category(self, category: str, limit: int = 100) -> List[Dict]:
        return self.adapter.get_products_by_category(category, limit)
    
    def search_products_by_nutrition(self, filters: Dict) -> List[Dict]:
        return self.adapter.search_products_by_nutrition(filters)
    
    def get_user_profile(self, user_id: int) -> Optional[Dict]:
        return self.adapter.get_user_profile(user_id)
    
    def get_user_allergens(self, user_id: int) -> List[Dict]:
        return self.adapter.get_user_allergens(user_id)
    
    def get_user_preferences(self, user_id: int) -> Optional[Dict]:
        return self.adapter.get_user_preferences(user_id)
    
    def get_purchase_history(self, user_id: int, days: int = 90) -> List[Dict]:
        return self.adapter.get_purchase_history(user_id, days)
    
    def get_user_purchase_matrix(self, user_id: int) -> Dict:
        return self.adapter.get_user_purchase_matrix(user_id)
    
    def check_product_allergens(self, barcode: str, user_allergens: List[int]) -> Dict:
        return self.adapter.check_product_allergens(barcode, user_allergens)
    
    def get_allergen_by_name(self, allergen_name: str) -> Optional[Dict]:
        return self.adapter.get_allergen_by_name(allergen_name)
    
    def log_recommendation(self, log_data: Dict) -> bool:
        return self.adapter.log_recommendation(log_data)
    
    def get_recommendation_stats(self, user_id: int) -> Dict:
        return self.adapter.get_recommendation_stats(user_id)