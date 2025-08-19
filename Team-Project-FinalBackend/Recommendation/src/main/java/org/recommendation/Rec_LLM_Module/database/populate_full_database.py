# Agent写入此文件的内容: database/populate_full_database.py

import os
import logging
import sys

# 确保项目根目录在sys.path中，以便导入其他模块
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if project_root not in sys.path:
    sys.path.insert(0, project_root)

# 导入我们需要的各个模块化脚本中的函数
from database.init_db import init_database
from database.data_importer import import_products_from_csv
from database.populate_allergens import populate_derived_tables
from create_test_data import TestDataBuilder

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def populate_database():
    """
    执行完整的数据填充流程：
    1. 清理并创建数据库结构
    2. 导入商品数据
    3. 生成过敏原关联数据
    4. 创建测试用户和购买历史
    """
    db_path = os.path.join(project_root, "data", "grocery_guardian.db")

    # 步骤 0: 为了确保每次都是全新开始，先删除旧的数据库文件
    if os.path.exists(db_path):
        os.remove(db_path)
        logging.info(f"旧数据库 '{db_path}' 已删除。")

    # 步骤 1: 创建数据库和所有表结构
    logging.info("--- 步骤 1: 正在创建数据库表结构... ---")
    init_database()
    logging.info("--- 数据库表结构创建成功！ ---\n")

    # 步骤 2: 从CSV导入完整商品数据
    logging.info("--- 步骤 2: 正在导入商品数据... ---")
    import_products_from_csv()
    logging.info("--- 商品数据导入成功！ ---\n")

    # 步骤 3: 填充过敏原关联表
    logging.info("--- 步骤 3: 正在生成过敏原关联数据... ---")
    populate_derived_tables()
    logging.info("--- 过敏原数据生成成功！ ---\n")

    # 步骤 4: 创建测试用户和行为数据
    logging.info("--- 步骤 4: 正在创建测试用户和历史数据... ---")
    try:
        # 假设TestDataBuilder的db_path默认指向正确位置
        test_data_builder = TestDataBuilder()
        test_data_builder.generate_user_and_behavior_data()
        logging.info("--- 测试用户和历史数据创建成功！ ---\n")
    except Exception as e:
        logging.error(f"创建测试数据时出错: {e}", exc_info=True)
        logging.warning("请检查 create_test_data.py 是否已适配新的数据库字段名。")


if __name__ == "__main__":
    populate_database() 