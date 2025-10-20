import express from "express";
import cors from "cors";
import pkg from "pg";
const { Pool } = pkg;

const app = express();

app.use(cors({ origin: "http://40.82.129.240" }));

app.use(express.json());
const PORT = process.env.PORT || 4002;

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

// Create a new task
app.post("/tasks", async (req, res) => {
  console.log("==> POST /tasks request received!");

  console.log("--> Request body:", req.body);

  const { title } = req.body;
  if (!title || typeof title !== "string") {
    console.error("!!! Validation failed: Title is missing or not a string.");
    return res.status(400).json({ error: "Title is required" });
  }

  try {
    console.log(`--> Attempting to insert title: "${title}"`);
    const { rows } = await pool.query(
      "INSERT INTO tasks (title, completed) VALUES ($1, false) RETURNING id, title, completed",
      [title]
    );

    console.log("<== Successfully inserted:", rows[0]);
    res.status(201).json(rows[0]);
  } catch (err) {
    console.error("!!! DATABASE QUERY FAILED:", err);
    res.status(500).json({ error: "Failed to create task" });
  }
});

// Update task completion status
app.put("/tasks/:id", async (req, res) => {
  const id = parseInt(req.params.id, 10); 
  if (isNaN(id)) {
    return res.status(400).json({ error: "Invalid ID" });
  }

  const { completed } = req.body;
  if (typeof completed !== "boolean") {
    return res.status(400).json({ error: "Completed must be a boolean" });
  }

  try {
    const { rowCount } = await pool.query(
      "UPDATE tasks SET completed = $1 WHERE id = $2",
      [completed, id]
    );
    if (rowCount === 0) return res.status(404).json({ error: "Task not found" });
    res.sendStatus(204);
  } catch (err) {
    console.error("!!! FAILED TO UPDATE TASK:", err);
    res.status(500).json({ error: "Failed to update task" });
  }
});

// Delete a task
app.delete("/tasks/:id", async (req, res) => {
  const id = parseInt(req.params.id, 10); 
  if (isNaN(id)) {
    return res.status(400).json({ error: "Invalid ID" });
  }

  try {
    const { rowCount } = await pool.query("DELETE FROM tasks WHERE id = $1", [id]);
    if (rowCount === 0) return res.status(404).json({ error: "Task not found" });
    res.sendStatus(204);
  } catch (err) {
    console.error("!!! FAILED TO DELETE TASK:", err);
    res.status(500).json({ error: "Failed to delete task" });
  }
});


app.listen(PORT, '0.0.0.0', () => {
  console.log(`task-write-service running on port ${PORT}`);
});