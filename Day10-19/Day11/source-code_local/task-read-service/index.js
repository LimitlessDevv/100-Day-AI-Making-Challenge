import express from "express";
import cors from "cors";
import pkg from "pg";
const { Pool } = pkg;

const app = express();
app.use(cors());
const PORT = process.env.PORT || 4001;

// Configure your PostgreSQL connection here
const pool = new Pool({
  user: process.env.PGUSER || "postgres",
  host: process.env.PGHOST || "localhost",
  database: process.env.PGDATABASE || "tasksdb",
  password: process.env.PGPASSWORD || "password",
  port: process.env.PGPORT || 5432,
});

app.get("/tasks", async (req, res) => {
  try {
    const { rows } = await pool.query("SELECT id, title, completed FROM tasks ORDER BY id DESC");
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: "Failed to fetch tasks" });
  }
});

app.listen(PORT, () => {
  console.log(`task-read-service running on port ${PORT}`);
});
