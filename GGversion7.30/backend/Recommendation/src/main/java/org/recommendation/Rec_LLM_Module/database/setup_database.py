import sqlite3
import os

def setup_database_schema():
    """根据 Setup.txt 创建数据库的表、索引和视图。"""
    db_path = "data/grocery_guardian.db"
    schema_path = "data/Setup.txt"  # 您的 SQL 文件

    # 确保 data 目录存在
    os.makedirs("data", exist_ok=True)
    
    # 如果数据库文件已存在，删除它以确保一个全新的开始
    if os.path.exists(db_path):
        os.remove(db_path)
        print(f"旧数据库 '{db_path}' 已删除，将创建新数据库。")

    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()

        with open(schema_path, 'r', encoding='utf-8') as f:
            # 读取整个 SQL 文件内容
            sql_script = f.read()
            
            # 使用 executescript 来执行包含多个语句的脚本
            # 注意：这会自动处理以分号分隔的命令
            cursor.executescript(sql_script)
            print("数据库结构已根据 Setup.txt 成功创建！")

        conn.commit()
    except sqlite3.Error as e:
        print(f"数据库创建失败: {e}")
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    setup_database_schema()