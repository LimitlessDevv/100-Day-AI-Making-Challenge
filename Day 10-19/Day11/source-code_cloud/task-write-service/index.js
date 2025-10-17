import express from "express";
import cors from "cors";
import pkg from "pg";
const { Pool } = pkg;

const app = express();
app.use(cors());
app.use(express.json());
const PORT = process.env.PORT || 4002;

// Configure your PostgreSQL connection here
const pool = new Pool({
  user: process.env.PGUSER || "postgres",
  host: process.env.PGHOST || "inyoung-app-test.postgres.database.azure.com",
  database: process.env.PGDATABASE || "tasksdb",
  password: process.env.PGPASSWORD || "student123!",
  port: process.env.PGPORT || 5432,
});

// Create a new task
app.post("/tasks", async (req, res) => {
  const { title } = req.body;
  if (!title || typeof title !== "string") {
    return res.status(400).json({ error: "Title is required" });
  }
  try {
    const { rows } = await pool.query(
      "INSERT INTO tasks (title, completed) VALUES ($1, false) RETURNING id, title, completed",
      [title]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: "Failed to create task" });
  }
});

// Update task completion status
app.put("/tasks/:id", async (req, res) => {
  const { id } = req.params;
  const { completed } = req.body;
  if (typeof completed !== "boolean") {
    return res.status(400).json({ error: "Completed must be boolean" });
  }
  try {
    const { rowCount } = await pool.query(
      "UPDATE tasks SET completed = $1 WHERE id = $2",
      [completed, id]
    );
    if (rowCount === 0) return res.status(404).json({ error: "Task not found" });
    res.sendStatus(204);
  } catch (err) {
    res.status(500).json({ error: "Failed to update task" });
  }
});

// Delete a task
app.delete("/tasks/:id", async (req, res) => {
  const { id } = req.params;
  try {
    const { rowCount } = await pool.query("DELETE FROM tasks WHERE id = $1", [id]);
    if (rowCount === 0) return res.status(404).json({ error: "Task not found" });
    res.sendStatus(204);
  } catch (err) {
    res.status(500).json({ error: "Failed to delete task" });
  }
});

app.listen(PORT, () => {
  console.log(`task-write-service running on port ${PORT}`);
});
