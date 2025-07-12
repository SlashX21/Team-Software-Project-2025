#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Grocery Guardian 测试数据导入工具
适配当前数据库结构：springboot_demo
字段映射：barcode→bar_code, name→product_name等
"""

import pandas as pd
import mysql.connector
from mysql.connector import Error
import logging
import sys
import os
from datetime import datetime
from typing import Optional, Dict, Any
import getpass  # 添加用于安全密码输入

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('import_log.txt'),
        logging.StreamHandler(sys.stdout)
    ]
)

logger = logging.getLogger(__name__)

class DatabaseImporter:
    """数据库导入类"""
    
    def __init__(self):
        self.connection: Optional[mysql.connector.MySQLConnection] = None
        self.cursor: Optional[mysql.connector.cursor.MySQLCursor] = None
        
    def connect_database(self, config: Dict[str, Any]) -> bool:
        """连接数据库"""
        try:
            self.connection = mysql.connector.connect(**config)
            self.cursor = self.connection.cursor()
            logger.info("✅ 数据库连接成功")
            return True
        except Error as e:
            logger.error(f"❌ 数据库连接失败: {e}")
            return False
    
    def close_connection(self):
        """关闭数据库连接"""
        if self.cursor:
            self.cursor.close()
        if self.connection:
            self.connection.close()
        logger.info("🔌 数据库连接已关闭")
    
    def execute_query(self, query: str, data: tuple = None) -> bool:
        """执行SQL查询"""
        try:
            if data:
                self.cursor.execute(query, data)
            else:
                self.cursor.execute(query)
            self.connection.commit()
            return True
        except Error as e:
            logger.error(f"❌ SQL执行失败: {e}")
            logger.error(f"SQL: {query}")
            if data:
                logger.error(f"Data: {data}")
            return False
    
    def get_current_counts(self) -> Dict[str, int]:
        """获取当前数据统计"""
        counts = {}
        tables = ['allergen', 'product', 'user']
        
        for table in tables:
            try:
                self.cursor.execute(f"SELECT COUNT(*) FROM {table}")
                counts[table] = self.cursor.fetchone()[0]
            except Error as e:
                logger.error(f"获取{table}表统计失败: {e}")
                counts[table] = 0
        
        return counts

class CSVProcessor:
    """CSV数据处理类"""
    
    def __init__(self):
        self.project_root = os.path.dirname(os.path.abspath(__file__))
        
    def clean_numeric_value(self, value: Any) -> Optional[float]:
        """清理数值数据"""
        if pd.isna(value) or value == '' or value is None:
            return None
        try:
            # 转换为浮点数
            num_val = float(str(value).strip())
            # 检查是否为负数或异常值
            if num_val < 0 or num_val > 9999999:
                return None
            return num_val
        except (ValueError, TypeError):
            return None
    
    def clean_text_value(self, value: Any) -> Optional[str]:
        """清理文本数据"""
        if pd.isna(value) or value == '' or value is None:
            return None
        return str(value).strip()
    
    def process_allergen_csv(self) -> pd.DataFrame:
        """处理过敏原CSV数据"""
        csv_path = os.path.join(self.project_root, 'allergen_dictionary.csv')
        
        if not os.path.exists(csv_path):
            logger.error(f"❌ 过敏原CSV文件不存在: {csv_path}")
            return pd.DataFrame()
        
        try:
            df = pd.read_csv(csv_path)
            logger.info(f"📋 读取过敏原数据: {len(df)} 条记录")
            
            # 数据清理
            df['allergen_id'] = df['allergen_id'].astype(int)
            df['name'] = df['name'].apply(self.clean_text_value)
            df['category'] = df['category'].apply(self.clean_text_value)
            df['description'] = df['description'].apply(self.clean_text_value)
            
            # 转换布尔值
            df['is_common'] = df['is_common'].apply(
                lambda x: 1 if str(x).lower() in ['true', '1', 'yes', 't'] else 0
            )
            
            # 过滤无效记录
            df = df.dropna(subset=['allergen_id', 'name'])
            
            logger.info(f"✅ 过敏原数据处理完成: {len(df)} 条有效记录")
            return df
            
        except Exception as e:
            logger.error(f"❌ 处理过敏原CSV失败: {e}")
            return pd.DataFrame()
    
    def process_product_csv(self) -> pd.DataFrame:
        """处理产品CSV数据"""
        csv_path = os.path.join(self.project_root, 'ireland_products_final.csv')
        
        if not os.path.exists(csv_path):
            logger.error(f"❌ 产品CSV文件不存在: {csv_path}")
            return pd.DataFrame()
        
        try:
            df = pd.read_csv(csv_path)
            logger.info(f"📋 读取产品数据: {len(df)} 条记录")
            
            # 数据清理和字段映射 - 使用数据库实际字段名
            processed_df = pd.DataFrame()
            
            # 字段映射: CSV → 数据库 (保持数据库字段名)
            processed_df['barcode'] = df['barcode'].apply(self.clean_text_value)
            processed_df['name'] = df['name'].apply(self.clean_text_value)
            processed_df['brand'] = df['brand'].apply(self.clean_text_value)
            processed_df['ingredients'] = df['ingredients'].apply(self.clean_text_value)
            processed_df['allergens'] = df['allergens'].apply(self.clean_text_value)
            
            # 营养数据清理
            processed_df['energy_100g'] = df['energy_100g'].apply(self.clean_numeric_value)
            processed_df['energy_kcal_100g'] = df['energy_kcal_100g'].apply(self.clean_numeric_value)
            processed_df['fat_100g'] = df['fat_100g'].apply(self.clean_numeric_value)
            processed_df['saturated_fat_100g'] = df['saturated_fat_100g'].apply(self.clean_numeric_value)
            processed_df['carbohydrates_100g'] = df['carbohydrates_100g'].apply(self.clean_numeric_value)
            processed_df['sugars_100g'] = df['sugars_100g'].apply(self.clean_numeric_value)
            processed_df['proteins_100g'] = df['proteins_100g'].apply(self.clean_numeric_value)
            
            processed_df['serving_size'] = df['serving_size'].apply(self.clean_text_value)
            processed_df['category'] = df['category'].apply(
                lambda x: self.clean_text_value(x) or 'Other'
            )
            
            # 过滤无效记录
            processed_df = processed_df.dropna(subset=['barcode', 'name'])
            
            logger.info(f"✅ 产品数据处理完成: {len(processed_df)} 条有效记录")
            return processed_df
            
        except Exception as e:
            logger.error(f"❌ 处理产品CSV失败: {e}")
            return pd.DataFrame()

class DataImporter:
    """数据导入主类"""
    
    def __init__(self):
        self.db = DatabaseImporter()
        self.processor = CSVProcessor()
        
        # 数据库配置 - 硬编码
        self.db_config = {
            'host': 'localhost',
            'port': 3306,
            'database': 'springboot_demo',
            'user': 'root',
            'password': '20020213Lx',
            'charset': 'utf8mb4',
            'autocommit': False
        }
    
    def get_database_config(self) -> Dict[str, Any]:
        """返回硬编码的数据库配置"""
        print("\n🔧 使用默认数据库配置:")
        print(f"   主机: {self.db_config['host']}")
        print(f"   端口: {self.db_config['port']}")
        print(f"   数据库: {self.db_config['database']}")
        print(f"   用户: {self.db_config['user']}")
        return self.db_config
    
    def import_allergens(self, df: pd.DataFrame) -> bool:
        """导入过敏原数据"""
        success_count = 0
        error_count = 0
        
        for index, row in df.iterrows():
            try:
                # 数据清理和转换
                allergen_data = {
                    'allergen_id': int(row.get('allergen_id', index + 1)),
                    'name': str(row.get('name', '')),
                    'category': str(row.get('category', '')) if pd.notna(row.get('category')) else None,
                    'is_common': 1 if str(row.get('is_common', '0')).lower() in ['1', 'true', 'yes'] else 0,
                    'description': str(row.get('description', '')) if pd.notna(row.get('description')) else None
                }
                
                # 执行插入
                result = self.db.execute_query(
                    """
                    INSERT IGNORE INTO allergen 
                    (allergen_id, name, category, is_common, description)
                    VALUES (%s, %s, %s, %s, %s)
                    """,
                    (
                        allergen_data['allergen_id'],
                        allergen_data['name'],
                        allergen_data['category'],
                        allergen_data['is_common'],
                        allergen_data['description']
                    )
                )
                
                if result:
                    success_count += 1
                    if success_count % 20 == 0:
                        print(f"✅ 已导入 {success_count} 个过敏原...")
                else:
                    error_count += 1
                    logging.error(f"导入过敏原失败: {allergen_data['name']}")
                    
            except Exception as e:
                error_count += 1
                logging.error(f"导入过敏原失败: {row.get('name', 'Unknown')}")
                logging.error(f"错误: {str(e)}")
                continue
        
        print(f"✅ 过敏原导入完成: {success_count}/{len(df)} 条记录")
        logging.info(f"✅ 过敏原导入完成: {success_count}/{len(df)} 条记录")
        return success_count > 0
    
    def import_products(self, df: pd.DataFrame) -> bool:
        """导入产品数据"""
        success_count = 0
        error_count = 0
        
        for index, row in df.iterrows():
            try:
                # 数据清理和转换
                product_data = {
                    'barcode': str(row.get('barcode', '')),
                    'name': str(row.get('name', '')),
                    'brand': str(row.get('brand', '')) if pd.notna(row.get('brand')) else None,
                    'ingredients': str(row.get('ingredients', '')) if pd.notna(row.get('ingredients')) else None,
                    'allergens': str(row.get('allergens', '')) if pd.notna(row.get('allergens')) else None,
                    'energy_100g': float(row.get('energy_100g', 0)) if pd.notna(row.get('energy_100g')) else None,
                    'energy_kcal_100g': float(row.get('energy_kcal_100g', 0)) if pd.notna(row.get('energy_kcal_100g')) else None,
                    'fat_100g': float(row.get('fat_100g', 0)) if pd.notna(row.get('fat_100g')) else None,
                    'saturated_fat_100g': float(row.get('saturated_fat_100g', 0)) if pd.notna(row.get('saturated_fat_100g')) else None,
                    'carbohydrates_100g': float(row.get('carbohydrates_100g', 0)) if pd.notna(row.get('carbohydrates_100g')) else None,
                    'sugars_100g': float(row.get('sugars_100g', 0)) if pd.notna(row.get('sugars_100g')) else None,
                    'proteins_100g': float(row.get('proteins_100g', 0)) if pd.notna(row.get('proteins_100g')) else None,
                    'serving_size': str(row.get('serving_size', '')) if pd.notna(row.get('serving_size')) else None,
                    'category': str(row.get('category', 'Other'))
                }
                
                # 执行插入
                result = self.db.execute_query(
                    """
                    INSERT IGNORE INTO product 
                    (barcode, name, brand, ingredients, allergens, 
                     energy_100g, energy_kcal_100g, fat_100g, saturated_fat_100g,
                     carbohydrates_100g, sugars_100g, proteins_100g, 
                     serving_size, category)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    """,
                    (
                        product_data['barcode'],
                        product_data['name'],
                        product_data['brand'],
                        product_data['ingredients'],
                        product_data['allergens'],
                        product_data['energy_100g'],
                        product_data['energy_kcal_100g'],
                        product_data['fat_100g'],
                        product_data['saturated_fat_100g'],
                        product_data['carbohydrates_100g'],
                        product_data['sugars_100g'],
                        product_data['proteins_100g'],
                        product_data['serving_size'],
                        product_data['category']
                    )
                )
                
                if result:
                    success_count += 1
                    if success_count % 100 == 0:
                        print(f"✅ 已导入 {success_count} 个产品...")
                else:
                    error_count += 1
                    logging.error(f"导入产品失败: {product_data['name']}")
                    
            except Exception as e:
                error_count += 1
                logging.error(f"导入产品失败: {row.get('name', 'Unknown')}")
                logging.error(f"错误: {str(e)}")
                continue
        
        print(f"✅ 产品导入完成: {success_count}/{len(df)} 条记录")
        logging.info(f"✅ 产品导入完成: {success_count}/{len(df)} 条记录")
        return success_count > 0
    
    def create_test_users(self) -> bool:
        """创建测试用户"""
        logger.info("🔄 创建测试用户...")
        
        test_users = [
            (1, 'test_user_1', 'test1@example.com', 'hashed_password_123', 28, 'female', 
             165, 58.5, 'moderately_active', 'lose_weight', 1800.0, 120.0, 200.0, 60.0),
            (2, 'test_user_2', 'test2@example.com', 'hashed_password_456', 35, 'male', 
             178, 75.2, 'very_active', 'gain_muscle', 2500.0, 180.0, 300.0, 85.0),
            (3, 'test_user_3', 'test3@example.com', 'hashed_password_789', 42, 'female', 
             160, 65.0, 'sedentary', 'maintain', 2000.0, 130.0, 250.0, 70.0)
        ]
        
        insert_query = """
        INSERT IGNORE INTO user 
        (user_id, username, email, password_hash, age, gender, height_cm, weight_kg,
         activity_level, nutrition_goal, daily_calories_target, daily_protein_target,
         daily_carb_target, daily_fat_target)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """
        
        success_count = 0
        for user_data in test_users:
            if self.db.execute_query(insert_query, user_data):
                success_count += 1
        
        logger.info(f"✅ 测试用户创建完成: {success_count}/{len(test_users)} 个用户")
        return success_count > 0
    
    def test_connection(self, config: Dict[str, Any]) -> bool:
        """测试数据库连接"""
        print("\n🔍 测试数据库连接...")
        
        try:
            test_conn = mysql.connector.connect(**config)
            cursor = test_conn.cursor()
            
            # 检查数据库是否存在
            cursor.execute(f"SHOW DATABASES LIKE '{config['database']}'")
            db_exists = cursor.fetchone() is not None
            
            if not db_exists:
                print(f"⚠️  数据库 '{config['database']}' 不存在")
                create_db = input("是否创建数据库? (y/N): ").strip().lower()
                if create_db in ['y', 'yes']:
                    cursor.execute(f"CREATE DATABASE {config['database']} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci")
                    print(f"✅ 数据库 '{config['database']}' 创建成功")
                else:
                    print("❌ 取消导入，请先创建数据库")
                    return False
            else:
                print(f"✅ 数据库 '{config['database']}' 连接成功")
            
            # 切换到目标数据库
            cursor.execute(f"USE {config['database']}")
            
            # 检查必要的表是否存在
            tables_to_check = ['allergen', 'product', 'user']
            missing_tables = []
            
            for table in tables_to_check:
                cursor.execute(f"SHOW TABLES LIKE '{table}'")
                if cursor.fetchone() is None:
                    missing_tables.append(table)
            
            if missing_tables:
                print(f"⚠️  缺少以下表: {missing_tables}")
                print("请确保数据库schema已正确创建")
                return False
            else:
                print("✅ 所有必要的表都存在")
            
            cursor.close()
            test_conn.close()
            return True
            
        except Error as e:
            print(f"❌ 数据库连接失败: {e}")
            return False
    
    def run_import(self) -> bool:
        """执行完整的数据导入流程"""
        logger.info("🚀 开始数据导入流程...")
        
        # 获取数据库配置
        self.db_config = self.get_database_config()
        
        # 测试连接
        if not self.test_connection(self.db_config):
            return False
        
        # 连接数据库
        if not self.db.connect_database(self.db_config):
            return False
        
        try:
            # 获取导入前的数据统计
            before_counts = self.db.get_current_counts()
            logger.info(f"📊 导入前数据统计: {before_counts}")
            
            # 处理和导入过敏原数据
            allergen_df = self.processor.process_allergen_csv()
            if not allergen_df.empty:
                self.import_allergens(allergen_df)
            
            # 处理和导入产品数据
            product_df = self.processor.process_product_csv()
            if not product_df.empty:
                self.import_products(product_df)
            
            # 创建测试用户
            self.create_test_users()
            
            # 获取导入后的数据统计
            after_counts = self.db.get_current_counts()
            logger.info(f"📊 导入后数据统计: {after_counts}")
            
            # 计算导入数量
            imported_counts = {
                table: after_counts[table] - before_counts[table] 
                for table in before_counts.keys()
            }
            logger.info(f"📈 本次导入数量: {imported_counts}")
            
            # 数据验证
            self.validate_imported_data()
            
            logger.info("🎉 数据导入流程完成！")
            return True
            
        except Exception as e:
            logger.error(f"❌ 导入过程发生错误: {e}")
            return False
        finally:
            self.db.close_connection()
    
    def validate_imported_data(self):
        """验证导入的数据"""
        logger.info("🔍 验证导入数据...")
        
        # 检查营养数据完整性
        self.db.cursor.execute("""
            SELECT COUNT(*) FROM product 
            WHERE energy_kcal_100g IS NOT NULL 
              AND proteins_100g IS NOT NULL 
              AND fat_100g IS NOT NULL 
              AND carbohydrates_100g IS NOT NULL
        """)
        complete_nutrition = self.db.cursor.fetchone()[0]
        
        # 检查过敏原信息
        self.db.cursor.execute("""
            SELECT COUNT(*) FROM product 
            WHERE allergens IS NOT NULL AND allergens != ''
        """)
        has_allergens = self.db.cursor.fetchone()[0]
        
        # 检查产品类别分布
        self.db.cursor.execute("""
            SELECT category, COUNT(*) 
            FROM product 
            GROUP BY category 
            ORDER BY COUNT(*) DESC 
            LIMIT 5
        """)
        categories = self.db.cursor.fetchall()
        
        logger.info(f"📊 有完整营养信息的产品: {complete_nutrition} 个")
        logger.info(f"📊 有过敏原信息的产品: {has_allergens} 个")
        logger.info(f"📊 产品类别分布: {categories}")


def main():
    """主函数"""
    print("=" * 60)
    print("Grocery Guardian 测试数据导入工具")
    print("适配数据库: springboot_demo")
    print("=" * 60)
    
    # 检查必要文件
    required_files = ['allergen_dictionary.csv', 'ireland_products_final.csv']
    missing_files = []
    
    for file in required_files:
        if not os.path.exists(file):
            missing_files.append(file)
    
    if missing_files:
        logger.error(f"❌ 缺少必要的CSV文件: {missing_files}")
        logger.error("请确保以下文件在当前目录:")
        for file in required_files:
            logger.error(f"  - {file}")
        return False
    
    # 创建导入器并执行导入
    importer = DataImporter()
    
    # 执行导入（现在包含交互式配置）
    success = importer.run_import()
    
    if success:
        print("\n🎉 数据导入成功完成！")
        print("   - 过敏原数据已导入")
        print("   - 产品数据已导入") 
        print("   - 测试用户已创建")
        print("   - 数据库已适配字段映射")
        return True
    else:
        print("\n❌ 数据导入失败！")
        print("   请检查日志文件 import_log.txt 获取详细信息")
        return False


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1) 