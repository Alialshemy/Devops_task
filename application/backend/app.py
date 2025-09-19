from flask import Flask, request, jsonify
from flask_cors import CORS
import psycopg2
import os
import uuid

app = Flask(__name__)
# In prod: change "*" to your frontend domain
CORS(app, resources={r"/*": {"origins": "*"}}, methods=["GET", "POST", "DELETE"])

# DB config from environment
DB_CONFIG = {
    "host": os.getenv("PGHOST", "localhost"),
    "dbname": os.getenv("PGDATABASE", "postgres"),
    "user": os.getenv("PGUSER", "postgres"),
    "password": os.getenv("PGPASSWORD", "test"),
    "port": int(os.getenv("PGPORT", "5432")),
}

def get_connection():
    return psycopg2.connect(**DB_CONFIG)

# Initialize schema once
with get_connection() as conn:
    with conn.cursor() as cur:
        cur.execute("""
        CREATE TABLE IF NOT EXISTS tasks (
            id TEXT PRIMARY KEY,
            title TEXT,
            created_at TIMESTAMP DEFAULT now()
        )
        """)
        conn.commit()

@app.route('/addTask', methods=['POST'])
def add_task():
    data = request.json or {}
    title = data.get('title', 'untitled')
    task_id = str(uuid.uuid4())
    try:
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("INSERT INTO tasks (id, title) VALUES (%s, %s)", (task_id, title))
                conn.commit()
        return jsonify({"id": task_id, "title": title}), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/deleteTask/<task_id>', methods=['DELETE'])
def delete_task(task_id):
    try:
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("DELETE FROM tasks WHERE id = %s", (task_id,))
                conn.commit()
        return jsonify({"message": f"Task {task_id} deleted"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/listTasks', methods=['GET'])
def list_tasks():
    try:
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT id, title, created_at FROM tasks ORDER BY created_at DESC")
                rows = cur.fetchall()
                tasks = [{"id": r[0], "title": r[1], "created_at": str(r[2])} for r in rows]
        return jsonify(tasks), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
