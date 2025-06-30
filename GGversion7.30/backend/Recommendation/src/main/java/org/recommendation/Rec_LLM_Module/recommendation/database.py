"""
推荐系统数据库接口 - 修复版
与主数据库系统分离，专门服务于推荐算法
"""

import sqlite3
import logging
from typing import Dict, List, Optional
from datetime import datetime

logger = logging.getLogger(__name__)

class SQLiteAdapter:
    """SQLite适配器"""
    def __init__(self, db_path: str):
        self.db_path = db_path
    
    def connect(self):
        """连接数据库"""
        connection = sqlite3.connect(self.db_path)
        connection.row_factory = sqlite3.Row
        return connection

class Database:
    def __init__(self, db_path: str):
        self.db_path = db_path
        self.adapter = SQLiteAdapter(db_path)
        self.connection = None
        self.connect()
    
    def connect(self):
        """建立数据库连接"""
        try:
            self.connection = self.adapter.connect()
            logger.info("数据库连接成功")
        except Exception as e:
            logger.error(f"数据库连接失败: {e}")
            raise
    
    def disconnect(self):
        """关闭数据库连接"""
        if self.connection:
            try:
                self.connection.close()
                self.connection = None
                logger.info("数据库连接已关闭")
            except Exception as e:
                logger.error(f"关闭数据库连接失败: {e}")
    
    def get_product_by_barcode(self, barcode: str) -> Optional[Dict]:
        """根据条形码获取商品信息"""
        try:
            if not self.connection:
                self.connect()
                
            cursor = self.connection.cursor()
            cursor.execute("""
                SELECT bar_code, product_name, brand, ingredients, allergens,
                       energy_100g, energy_kcal_100g, fat_100g, saturated_fat_100g,
                       carbohydrates_100g, sugars_100g, proteins_100g,
                       serving_size, category, created_at, updated_at
                FROM product 
                WHERE bar_code = ?
            """, (barcode,))
            
            row = cursor.fetchone()
            if not row:
                return None
                
            return dict(row)
        except Exception as e:
            logger.error(f"查询商品失败 {barcode}: {e}")
            return None

    def get_products_by_category(self, category: str, limit: int = 100) -> List[Dict]:
        """根据分类获取商品列表"""
        try:
            if not self.connection:
                self.connect()
                
            cursor = self.connection.cursor()
            cursor.execute("""
                SELECT bar_code, product_name, brand, category,
                       energy_kcal_100g, proteins_100g, fat_100g, 
                       sugars_100g, carbohydrates_100g
                FROM product 
                WHERE category = ?
                ORDER BY product_name
                LIMIT ?
            """, (category, limit))
            
            rows = cursor.fetchall()
            products = []
            
            for row in rows:
                product = dict(row)
                # 确保营养数据不为None
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

    def get_user_profile(self, user_id: int) -> Optional[Dict]:
        """获取用户资料"""
        try:
            if not self.connection:
                self.connect()
                
            cursor = self.connection.cursor()
            cursor.execute("""
                SELECT user_id, user_name, email, age, gender, height_cm, weight_kg,
                       activity_level, nutrition_goal, daily_calories_target, 
                       daily_protein_target, daily_carb_target, daily_fat_target,
                       created_at
                FROM user 
                WHERE user_id = ?
            """, (user_id,))
            
            row = cursor.fetchone()
            if not row:
                return None
                
            return dict(row)
        except Exception as e:
            logger.error(f"查询用户资料失败 {user_id}: {e}")
            return None

    def get_user_allergens(self, user_id: int) -> List[Dict]:
        """获取用户过敏原"""
        try:
            if not self.connection:
                self.connect()
                
            cursor = self.connection.cursor()
            cursor.execute("""
                SELECT a.allergen_id, a.name, a.category, a.description,
                       ua.severity_level, ua.confirmed, ua.notes
                FROM user_allergen ua
                JOIN allergen a ON ua.allergen_id = a.allergen_id
                WHERE ua.user_id = ? AND ua.confirmed = 1
                ORDER BY ua.severity_level DESC, a.name
            """, (user_id,))
            
            rows = cursor.fetchall()
            return [dict(row) for row in rows]
            
        except Exception as e:
            logger.error(f"查询用户过敏原失败 {user_id}: {e}")
            return []

    def get_user_preferences(self, user_id: int) -> Optional[Dict]:
        """获取用户偏好设置"""
        try:
            if not self.connection:
                self.connect()
                
            cursor = self.connection.cursor()
            cursor.execute("""
                SELECT preference_id, user_id, prefer_low_sugar, prefer_low_fat,
                       prefer_high_protein, prefer_low_sodium, prefer_organic,
                       prefer_low_calorie, preference_source, inference_confidence,
                       version, updated_at
                FROM user_preference 
                WHERE user_id = ?
                ORDER BY version DESC
                LIMIT 1
            """, (user_id,))
            
            row = cursor.fetchone()
            if not row:
                return None
                
            return dict(row)
        except Exception as e:
            logger.error(f"查询用户偏好失败 {user_id}: {e}")
            return None

    def log_recommendation(self, log_data: Dict) -> bool:
        """记录推荐日志"""
        try:
            if not self.connection:
                self.connect()
                
            cursor = self.connection.cursor()
            cursor.execute("""
                INSERT INTO recommendation_log 
                (user_id, request_type, request_barcode, recommended_products, 
                 llm_prompt, llm_response, llm_analysis, processing_time_ms, 
                 total_candidates, filtered_candidates, algorithm_version, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                log_data.get("user_id"),
                log_data.get("request_type"),
                log_data.get("request_barcode"),
                str(log_data.get("recommended_products", [])),
                log_data.get("llm_prompt", ""),
                log_data.get("llm_response", ""),
                log_data.get("llm_analysis", ""),
                log_data.get("processing_time_ms", 0),
                log_data.get("total_candidates", 0),
                log_data.get("filtered_candidates", 0),
                log_data.get("algorithm_version", "v1.0"),
                datetime.now()
            ))
            
            self.connection.commit()
            log_id = cursor.lastrowid
            logger.info(f"推荐日志记录成功: {log_id}")
            return True
            
        except Exception as e:
            logger.error(f"记录推荐日志失败: {e}")
            return False 