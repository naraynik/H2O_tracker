import subprocess
import base64
import sqlite3
import csv
import os

def export_db_to_csv():
    # 1. Pull the database securely over base64 to avoid Windows CRLF corruption
    adb_path = r"C:\Users\Narayani\AppData\Local\Android\Sdk\platform-tools\adb.exe"
    command = f'{adb_path} shell "run-as com.example.water_tracker base64 databases/water_tracker.db"'
    
    print("Pulling database securely from device...")
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    
    if result.returncode != 0:
        print("Error pulling database:", result.stderr)
        return
        
    base64_data = result.stdout.strip()
    
    # 2. Decode the base64 into a perfect binary replica
    binary_data = base64.b64decode(base64_data.replace('\n', '').replace('\r', ''))
    
    local_db = 'water_tracker_clean.db'
    with open(local_db, 'wb') as f:
        f.write(binary_data)
        
    print("Database cleaned and saved. Extracting to CSV...")

    # 3. Connect to SQLite
    conn = sqlite3.connect(local_db)
    cursor = conn.cursor()

    # 4. Query all users
    cursor.execute("SELECT * FROM users")
    users = cursor.fetchall()
    user_cols = [desc[0] for desc in cursor.description]

    with open('users_database.csv', 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(user_cols)
        writer.writerows(users)

    # 5. Query all water logs
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='water_logs'")
    if cursor.fetchone():
        cursor.execute("SELECT * FROM water_logs")
        logs = cursor.fetchall()
        log_cols = [desc[0] for desc in cursor.description]

        with open('water_logs.csv', 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            writer.writerow(log_cols)
            writer.writerows(logs)

    conn.close()
    
    # Clean up
    if os.path.exists(local_db):
        os.remove(local_db)
        
    print("Successfully exported 'users_database.csv' and 'water_logs.csv'!")

if __name__ == "__main__":
    export_db_to_csv()
