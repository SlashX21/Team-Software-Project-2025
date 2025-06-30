#!/usr/bin/env python3
"""
数据库迁移脚本
将SQLite数据迁移到Java Liquibase创建的数据库
"""

import os
import sys
import logging
from typing import Dict, List, Any
from datetime import datetime

# 添加项目根目录到Python路径
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from database.db_manager import DatabaseManager, SQLiteAdapter, MySQLAdapter, PostgreSQLAdapter
from config.settings import DatabaseConfig

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class DatabaseMigrator:
    """数据库迁移器"""
    
    def __init__(self, source_db_path: str, target_config: DatabaseConfig):
        self.source_config = DatabaseConfig(
            type="sqlite",
            connection_string=f"sqlite:///{source_db_path}"
        )
        self.target_config = target_config
        
        self.source_adapter = SQLiteAdapter(self.source_config)
        
        if target_config.type == "mysql":
            self.target_adapter = MySQLAdapter(target_config)
        elif target_config.type == "postgresql":
            self.target_adapter = PostgreSQLAdapter(target_config)
        else:
            raise ValueError(f"不支持的目标数据库类型: {target_config.type}")
    
    def migrate_all_data(self) -> bool:
        """迁移所有数据"""
        try:
            # 连接数据库
            if not self.source_adapter.connect():
                logger.error("无法连接源数据库")
                return False
            
            if not self.target_adapter.connect():
                logger.error("无法连接目标数据库")
                return False
            
            logger.info("开始数据迁移...")
            
            # 迁移各个表的数据
            migration_steps = [
                ("用户数据", self._migrate_users),
                ("商品数据", self._migrate_products),
                ("过敏原数据", self._migrate_allergens),
                ("用户过敏原关联", self._migrate_user_allergens),
                ("商品过敏原关联", self._migrate_product_allergens),
                ("购买记录", self._migrate_purchase_records),
                ("购买项目", self._migrate_purchase_items),
                ("用户偏好", self._migrate_user_preferences),
                ("推荐日志", self._migrate_recommendation_logs)
            ]
            
            for step_name, migration_func in migration_steps:
                logger.info(f"迁移 {step_name}...")
                try:
                    count = migration_func()
                    logger.info(f"✅ {step_name} 迁移完成: {count} 条记录")
                except Exception as e:
                    logger.error(f"❌ {step_name} 迁移失败: {e}")
                    return False
            
            logger.info("🎉 数据迁移完成！")
            return True
            
        except Exception as e:
            logger.error(f"迁移过程中发生错误: {e}")
            return False
        finally:
            self.source_adapter.disconnect()
            self.target_adapter.disconnect()
    
    def _migrate_users(self) -> int:
        """迁移用户数据"""
        # 从SQLite读取用户数据
        source_cursor = self.source_adapter.connection.cursor()
        source_cursor.execute("SELECT * FROM user")
        users = source_cursor.fetchall()
        
        if not users:
            return 0
        
        # 插入到目标数据库
        from sqlalchemy import text
        insert_query = text("""
        INSERT INTO user (
            user_id, user_name, email, password_hash, age, gender,
            height_cm, weight_kg, activity_level, nutrition_goal,
            daily_calories_target, daily_protein_target, daily_carb_target,
            daily_fat_target, created_time
        ) VALUES (
            :user_id, :user_name, :email, :password_hash, :age, :gender,
            :height_cm, :weight_kg, :activity_level, :nutrition_goal,
            :daily_calories_target, :daily_protein_target, :daily_carb_target,
            :daily_fat_target, :created_time
        )
        """)
        
        for user in users:
            user_dict = dict(user)
            self.target_adapter.connection.execute(insert_query, user_dict)
        
        self.target_adapter.connection.commit()
        return len(users)
    
    def _migrate_products(self) -> int:
        """迁移商品数据"""
        source_cursor = self.source_adapter.connection.cursor()
        source_cursor.execute("SELECT * FROM product")
        products = source_cursor.fetchall()
        
        if not products:
            return 0
        
        from sqlalchemy import text
        insert_query = text("""
        INSERT INTO product (
            bar_code, product_name, brand, ingredients, allergens,
            energy_100g, energy_kcal_100g, fat_100g, saturated_fat_100g,
            carbohydrates_100g, sugars_100g, proteins_100g,
            serving_size, category, created_at, updated_at
        ) VALUES (
            :bar_code, :product_name, :brand, :ingredients, :allergens,
            :energy_100g, :energy_kcal_100g, :fat_100g, :saturated_fat_100g,
            :carbohydrates_100g, :sugars_100g, :proteins_100g,
            :serving_size, :category, :created_at, :updated_at
        )
        """)
        
        for product in products:
            product_dict = dict(product)
            self.target_adapter.connection.execute(insert_query, product_dict)
        
        self.target_adapter.connection.commit()
        return len(products)
    
    def _migrate_allergens(self) -> int:
        """迁移过敏原数据"""
        source_cursor = self.source_adapter.connection.cursor()
        source_cursor.execute("SELECT * FROM allergen")
        allergens = source_cursor.fetchall()
        
        if not allergens:
            return 0
        
        from sqlalchemy import text
        insert_query = text("""
        INSERT INTO allergen (
            allergen_id, name, category, is_common, description, created_time
        ) VALUES (
            :allergen_id, :name, :category, :is_common, :description, :created_time
        )
        """)
        
        for allergen in allergens:
            allergen_dict = dict(allergen)
            self.target_adapter.connection.execute(insert_query, allergen_dict)
        
        self.target_adapter.connection.commit()
        return len(allergens)
    
    def _migrate_user_allergens(self) -> int:
        """迁移用户过敏原关联数据"""
        source_cursor = self.source_adapter.connection.cursor()
        source_cursor.execute("SELECT * FROM user_allergen")
        user_allergens = source_cursor.fetchall()
        
        if not user_allergens:
            return 0
        
        from sqlalchemy import text
        insert_query = text("""
        INSERT INTO user_allergen (
            user_allergen_id, user_id, allergen_id, severity_level, confirmed, notes
        ) VALUES (
            :user_allergen_id, :user_id, :allergen_id, :severity_level, :confirmed, :notes
        )
        """)
        
        for user_allergen in user_allergens:
            user_allergen_dict = dict(user_allergen)
            self.target_adapter.connection.execute(insert_query, user_allergen_dict)
        
        self.target_adapter.connection.commit()
        return len(user_allergens)
    
    def _migrate_product_allergens(self) -> int:
        """迁移商品过敏原关联数据"""
        source_cursor = self.source_adapter.connection.cursor()
        source_cursor.execute("SELECT * FROM product_allergen")
        product_allergens = source_cursor.fetchall()
        
        if not product_allergens:
            return 0
        
        from sqlalchemy import text
        insert_query = text("""
        INSERT INTO product_allergen (
            product_allergen_id, bar_code, allergen_id, presence_type, confidence_score
        ) VALUES (
            :product_allergen_id, :bar_code, :allergen_id, :presence_type, :confidence_score
        )
        """)
        
        for product_allergen in product_allergens:
            product_allergen_dict = dict(product_allergen)
            self.target_adapter.connection.execute(insert_query, product_allergen_dict)
        
        self.target_adapter.connection.commit()
        return len(product_allergens)
    
    def _migrate_purchase_records(self) -> int:
        """迁移购买记录数据"""
        source_cursor = self.source_adapter.connection.cursor()
        source_cursor.execute("SELECT * FROM purchase_record")
        records = source_cursor.fetchall()
        
        if not records:
            return 0
        
        from sqlalchemy import text
        insert_query = text("""
        INSERT INTO purchase_record (
            purchase_id, user_id, receipt_date, store_name, total_amount,
            ocr_confidence, raw_ocr_data, created_at
        ) VALUES (
            :purchase_id, :user_id, :receipt_date, :store_name, :total_amount,
            :ocr_confidence, :raw_ocr_data, :created_at
        )
        """)
        
        for record in records:
            record_dict = dict(record)
            self.target_adapter.connection.execute(insert_query, record_dict)
        
        self.target_adapter.connection.commit()
        return len(records)
    
    def _migrate_purchase_items(self) -> int:
        """迁移购买项目数据"""
        source_cursor = self.source_adapter.connection.cursor()
        source_cursor.execute("SELECT * FROM purchase_item")
        items = source_cursor.fetchall()
        
        if not items:
            return 0
        
        from sqlalchemy import text
        insert_query = text("""
        INSERT INTO purchase_item (
            item_id, purchase_id, bar_code, item_name_ocr, match_confidence,
            quantity, unit_price, total_price, estimated_servings,
            total_calories, total_proteins, total_carbs, total_fat
        ) VALUES (
            :item_id, :purchase_id, :bar_code, :item_name_ocr, :match_confidence,
            :quantity, :unit_price, :total_price, :estimated_servings,
            :total_calories, :total_proteins, :total_carbs, :total_fat
        )
        """)
        
        for item in items:
            item_dict = dict(item)
            self.target_adapter.connection.execute(insert_query, item_dict)
        
        self.target_adapter.connection.commit()
        return len(items)
    
    def _migrate_user_preferences(self) -> int:
        """迁移用户偏好数据"""
        source_cursor = self.source_adapter.connection.cursor()
        source_cursor.execute("SELECT * FROM user_preference")
        preferences = source_cursor.fetchall()
        
        if not preferences:
            return 0
        
        from sqlalchemy import text
        insert_query = text("""
        INSERT INTO user_preference (
            preference_id, user_id, prefer_low_sugar, prefer_low_fat,
            prefer_high_protein, prefer_low_sodium, prefer_organic,
            prefer_low_calorie, preference_source, inference_confidence,
            version, updated_at
        ) VALUES (
            :preference_id, :user_id, :prefer_low_sugar, :prefer_low_fat,
            :prefer_high_protein, :prefer_low_sodium, :prefer_organic,
            :prefer_low_calorie, :preference_source, :inference_confidence,
            :version, :updated_at
        )
        """)
        
        for preference in preferences:
            preference_dict = dict(preference)
            self.target_adapter.connection.execute(insert_query, preference_dict)
        
        self.target_adapter.connection.commit()
        return len(preferences)
    
    def _migrate_recommendation_logs(self) -> int:
        """迁移推荐日志数据"""
        source_cursor = self.source_adapter.connection.cursor()
        source_cursor.execute("SELECT * FROM recommendation_log")
        logs = source_cursor.fetchall()
        
        if not logs:
            return 0
        
        from sqlalchemy import text
        insert_query = text("""
        INSERT INTO recommendation_log (
            log_id, user_id, request_bar_code, request_type,
            recommended_products, algorithm_version, llm_prompt,
            llm_response, llm_analysis, processing_time_ms,
            total_candidates, filtered_candidates, created_at
        ) VALUES (
            :log_id, :user_id, :request_bar_code, :request_type,
            :recommended_products, :algorithm_version, :llm_prompt,
            :llm_response, :llm_analysis, :processing_time_ms,
            :total_candidates, :filtered_candidates, :created_at
        )
        """)
        
        for log in logs:
            log_dict = dict(log)
            self.target_adapter.connection.execute(insert_query, log_dict)
        
        self.target_adapter.connection.commit()
        return len(logs)

def main():
    """主函数"""
    import argparse
    
    parser = argparse.ArgumentParser(description="迁移SQLite数据到Java Liquibase数据库")
    parser.add_argument("--source", required=True, help="源SQLite数据库文件路径")
    parser.add_argument("--target-type", required=True, choices=["mysql", "postgresql"], help="目标数据库类型")
    parser.add_argument("--target-url", required=True, help="目标数据库连接URL")
    
    args = parser.parse_args()
    
    # 配置目标数据库
    target_config = DatabaseConfig(
        type=args.target_type,
        connection_string=args.target_url
    )
    
    # 执行迁移
    migrator = DatabaseMigrator(args.source, target_config)
    success = migrator.migrate_all_data()
    
    if success:
        print("✅ 数据迁移成功完成！")
        sys.exit(0)
    else:
        print("❌ 数据迁移失败！")
        sys.exit(1)

if __name__ == "__main__":
    main() 