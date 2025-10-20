const API_BASE = ""; // Set to gateway base path in deployment
// For local testing, when API_BASE is empty, point reads to the read-service (4001)
// and writes to the write-service (4002). When deploying behind a gateway,
// set API_BASE to the gateway base URL (e.g. https://app.example.com) so both
// read and write requests go through the gateway path-based routing.
const READ_URL = API_BASE ? API_BASE + "/tasks" : "http://localhost:4001/tasks";
const WRITE_URL = API_BASE ? API_BASE + "/tasks" : "http://localhost:4002/tasks";

const taskList = document.getElementById("task-list");
const taskForm = document.getElementById("task-form");
const taskInput = document.getElementById("task-input");

function renderTask(task) {
  const li = document.createElement("li");
  li.className = "task-item";
  li.setAttribute("data-id", task.id);

  const label = document.createElement("span");
  label.className = "task-label" + (task.completed ? " completed" : "");
  label.tabIndex = 0;
  label.setAttribute("role", "button");
  label.setAttribute("aria-pressed", task.completed);
  label.textContent = task.title;
  label.addEventListener("click", () => toggleTask(task.id, !task.completed));
  label.addEventListener("keydown", e => {
    if (e.key === "Enter" || e.key === " ") {
      toggleTask(task.id, !task.completed);
    }
  });

  const actions = document.createElement("div");
  actions.className = "task-actions";

  const delBtn = document.createElement("button");
  delBtn.className = "delete-btn";
  delBtn.setAttribute("aria-label", `Delete task: ${task.title}`);
  delBtn.innerHTML = "&times;";
  delBtn.addEventListener("click", () => deleteTask(task.id));

  actions.appendChild(delBtn);
  li.appendChild(label);
  li.appendChild(actions);
  return li;
}

function fetchTasks() {
  fetch(READ_URL)
    .then(res => res.json())
    .then(tasks => {
      taskList.innerHTML = "";
      tasks.forEach(task => taskList.appendChild(renderTask(task)));
    })
    .catch(() => {
      taskList.innerHTML = '<li style="color:red">Failed to load tasks.</li>';
    });
}

taskForm.addEventListener("submit", e => {
  e.preventDefault();
  const title = taskInput.value.trim();
  if (!title) return;
  fetch(WRITE_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ title })
  })
    .then(res => {
      if (!res.ok) throw new Error();
      taskInput.value = "";
      fetchTasks();
    })
    .catch(() => alert("Failed to add task."));
});

function toggleTask(id, completed) {
  fetch(`${WRITE_URL}/${id}`, {
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ completed })
  })
    .then(res => {
      if (!res.ok) throw new Error();
      fetchTasks();
    })
    .catch(() => alert("Failed to update task."));
}

function deleteTask(id) {
  fetch(`${WRITE_URL}/${id}`, { method: "DELETE" })
    .then(res => {
      if (!res.ok) throw new Error();
      fetchTasks();
    })
    .catch(() => alert("Failed to delete task."));
}

document.addEventListener("DOMContentLoaded", fetchTasks);
