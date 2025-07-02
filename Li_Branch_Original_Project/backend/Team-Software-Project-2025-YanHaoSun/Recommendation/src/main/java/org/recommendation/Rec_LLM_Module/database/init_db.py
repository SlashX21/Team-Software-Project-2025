#!/usr/bin/env python3

import sqlite3
import os
from pathlib import Path

def init_database(db_path: str = "data/grocery_guardian.db"):
    """
    Initialize the Grocery Guardian database using the unified schema.
    
    Args:
        db_path: Path to the SQLite database file
    """
    # Ensure the database directory exists
    db_file = Path(db_path)
    db_file.parent.mkdir(parents=True, exist_ok=True)
    
    # Read the schema SQL file
    schema_path = Path(__file__).parent / "schema.sql"
    if not schema_path.exists():
        raise FileNotFoundError(f"Schema file not found at {schema_path}")
    
    with open(schema_path, 'r', encoding='utf-8') as f:
        schema_sql = f.read()
    
    # Connect to database and execute schema
    conn = sqlite3.connect(db_path)
    try:
        cursor = conn.cursor()
        cursor.executescript(schema_sql)
        conn.commit()
        print(f"Database initialized successfully at {db_path}")
    except Exception as e:
        print(f"Error initializing database: {e}")
        raise
    finally:
        conn.close()

if __name__ == "__main__":
    init_database() 