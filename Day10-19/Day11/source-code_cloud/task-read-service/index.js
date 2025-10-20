import express from "express";
import cors from "cors";
import pkg from "pg";
const { Pool } = pkg;

const app = express();
app.use(cors({ origin: "http://40.82.129.240" }));
const PORT = process.env.PORT || 4001;

// Configure your PostgreSQL connection here
const pool = new Pool({
  user: "postgres",
  host: "inyoung-app-test.postgres.database.azure.com",
  database: "tasksdb",
  password: "student123!",
  port: 5432,
  ssl: {
    rejectUnauthorized: false
  }
});

app.get("/tasks", async (req, res) => {
  try {
    const { rows } = await pool.query("SELECT id, title, completed FROM tasks ORDER BY id DESC");
    res.json(rows);
  } catch (err) {
    console.error("!!! DATABASE QUERY FAILED:", err);
    res.status(500).json({ error: "Failed to fetch tasks" });
  }
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`task-read-service running on port ${PORT}`);
});