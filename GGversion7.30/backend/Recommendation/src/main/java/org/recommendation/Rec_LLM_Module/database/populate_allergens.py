import sqlite3
import logging
import re
import sys
import os

# 添加项目根目录到Python路径
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from config.constants import ALLERGEN_KEYWORDS

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def populate_derived_tables():
    """
    基于 product 表中的数据，填充 allergen 和 product_allergen 表。
    """
    db_path = "data/grocery_guardian.db"
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    try:
        # --- 1. 填充 allergen 字典表 ---
        logging.info("正在填充 allergen 字典表...")
        for allergen_name, keywords in ALLERGEN_KEYWORDS.items():
            # 使用 INSERT OR IGNORE 避免重复插入
            cursor.execute("INSERT OR IGNORE INTO allergen (name, category) VALUES (?, ?)", 
                           (allergen_name, allergen_name)) # 简化处理，使用自身作为分类
        conn.commit()
        logging.info("allergen 字典表填充完成。")

        # --- 2. 创建一个 allergen_name -> allergen_id 的映射，方便后续使用 ---
        cursor.execute("SELECT allergen_id, name FROM allergen")
        allergen_map = {row[1]: row[0] for row in cursor.fetchall()}
        
        # --- 3. 填充 product_allergen 关联表 ---
        logging.info("正在填充 product_allergen 关联表...")
        cursor.execute("SELECT bar_code, ingredients, allergens FROM product")
        products = cursor.fetchall()
        
        product_allergen_links = []
        for bar_code, ingredients, allergens_text in products:
            if not ingredients: ingredients = ""
            if not allergens_text: allergens_text = ""
            
            combined_text = (ingredients + " " + allergens_text).lower()
            
            # 使用集合避免重复添加同一个过敏原
            found_allergens_for_product = set()

            for allergen_name, keywords in ALLERGEN_KEYWORDS.items():
                for keyword in keywords:
                    # 使用单词边界 \b 来进行更精确的匹配
                    pattern = r'\b' + re.escape(keyword.lower()) + r'\b'
                    if re.search(pattern, combined_text):
                        allergen_id = allergen_map.get(allergen_name)
                        if allergen_id:
                            # 简化处理，默认都为 'contains'
                            presence_type = 'contains'
                            # 检查 'may contain' 或 'traces'
                            if 'may contain' in combined_text or 'traces' in combined_text:
                                presence_type = 'may_contain'
                            
                            found_allergens_for_product.add((bar_code, allergen_id, presence_type))
                        break # 找到一个关键词就跳到下一个过敏原大类

            product_allergen_links.extend(list(found_allergens_for_product))

        # 批量插入到 product_allergen
        if product_allergen_links:
            cursor.executemany(
                "INSERT INTO product_allergen (bar_code, allergen_id, presence_type) VALUES (?, ?, ?)",
                product_allergen_links
            )
            conn.commit()
            logging.info(f"成功向 product_allergen 表中插入 {len(product_allergen_links)} 条关联记录。")
        else:
            logging.warning("未找到任何商品-过敏原关联。")

    except Exception as e:
        logging.error(f"填充衍生表时发生错误: {e}")
        conn.rollback()
    finally:
        conn.close()

if __name__ == "__main__":
    populate_derived_tables()