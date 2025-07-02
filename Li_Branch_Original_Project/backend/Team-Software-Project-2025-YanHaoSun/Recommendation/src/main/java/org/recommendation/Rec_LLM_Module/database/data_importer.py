import pandas as pd
import sqlite3
import logging

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def import_products_from_csv():
    """从 CSV 文件读取商品数据并导入到 product 表。"""
    csv_path = "data/ireland_products_standardized.csv"
    db_path = "data/grocery_guardian.db"
    
    try:
        logging.info(f"开始从 {csv_path} 读取数据...")
        df = pd.read_csv(csv_path)
        logging.info(f"成功读取 {len(df)} 条商品数据。")

        # 数据预处理
        # 1. 确保列名与数据库字段匹配 (大小写不敏感，但最好统一)
        #    您的 CSV 列名已经很好了，这里不需要重命名。

        # 2. 处理缺失值：Pandas 读取的空值是 NaN，数据库需要 NULL (None)
        df = df.where(pd.notnull(df), None)

        # 3. 确保数据类型正确 (可选，pandas通常能正确推断)
        numeric_cols = ['energy_100g', 'energy_kcal_100g', 'fat_100g', 
                        'saturated_fat_100g', 'carbohydrates_100g', 
                        'sugars_100g', 'proteins_100g']
        for col in numeric_cols:
            df[col] = pd.to_numeric(df[col], errors='coerce') # 转换失败的设为NaN

        # 4. 数据范围清理 (符合数据库约束)
        # 检查并清理超出合理范围的营养数据
        logging.info("清理营养数据中的异常值...")
        
        # energy_kcal_100g: 0-2000 kcal
        invalid_kcal = (df['energy_kcal_100g'] < 0) | (df['energy_kcal_100g'] > 2000)
        if invalid_kcal.any():
            logging.warning(f"发现 {invalid_kcal.sum()} 条无效的 energy_kcal_100g 数据，已设为空值")
            df.loc[invalid_kcal, 'energy_kcal_100g'] = None
            
        # proteins_100g: 0-200g
        invalid_protein = (df['proteins_100g'] < 0) | (df['proteins_100g'] > 200)
        if invalid_protein.any():
            logging.warning(f"发现 {invalid_protein.sum()} 条无效的 proteins_100g 数据，已设为空值")
            logging.warning(f"无效值: {df.loc[invalid_protein, 'proteins_100g'].tolist()}")
            df.loc[invalid_protein, 'proteins_100g'] = None
            
        # fat_100g: 0-200g
        invalid_fat = (df['fat_100g'] < 0) | (df['fat_100g'] > 200)
        if invalid_fat.any():
            logging.warning(f"发现 {invalid_fat.sum()} 条无效的 fat_100g 数据，已设为空值")
            df.loc[invalid_fat, 'fat_100g'] = None

        # 再次处理可能因类型转换产生的NaN
        df = df.where(pd.notnull(df), None)

        # 连接数据库
        conn = sqlite3.connect(db_path)
        
        # 重命名列以匹配新schema (barcode -> bar_code, name -> product_name)
        df = df.rename(columns={
            'barcode': 'bar_code',
            'name': 'product_name'
        })
        
        # 使用 pandas 的 to_sql 功能批量导入数据
        logging.info("开始向 product 表导入数据...")
        df.to_sql(
            name='product', 
            con=conn, 
            if_exists='append',  # 'append' 表示追加数据，而不是替换
            index=False          # 不将 pandas 的索引作为一列导入
        )
        
        logging.info(f"成功向 product 表导入 {len(df)} 条记录。")

    except FileNotFoundError:
        logging.error(f"错误: CSV文件 '{csv_path}' 未找到。")
    except Exception as e:
        logging.error(f"数据导入过程中发生错误: {e}")
    finally:
        if 'conn' in locals() and conn:
            conn.close()

if __name__ == "__main__":
    import_products_from_csv()