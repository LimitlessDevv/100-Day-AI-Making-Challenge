# Task Manager — source-code

This folder contains a small task manager app split into two Node.js microservices (read/write) and a static frontend.

Contents
- `frontend/` — static files: `index.html`, `style.css`, `script.js`
- `task-read-service/` — Node.js service exposing `GET /tasks` (default port 4001)
- `task-write-service/` — Node.js service exposing `POST /tasks`, `PUT /tasks/:id`, `DELETE /tasks/:id` (default port 4002)
- `tasks-table.sql` — SQL to create the `tasks` table in PostgreSQL

Quick prerequisites
- Node.js 18+ installed
- PostgreSQL installed and running locally (or accessible remotely)

1) Create the database and table

- Start psql or a GUI and create a database (example uses `tasksdb`):

```powershell
# create database
createdb tasksdb
# or in psql: CREATE DATABASE tasksdb;
```

- Run the table SQL (from this folder):

```powershell
psql -d tasksdb -f tasks-table.sql
```

2) Configure environment variables (optional)

By default both services use:
- PGUSER=postgres
- PGPASSWORD=password
- PGHOST=localhost
- PGDATABASE=tasksdb
- PGPORT=5432

To override, set environment variables before starting a service. Example (PowerShell):

```powershell
$env:PGUSER = "postgres"; $env:PGPASSWORD = "yourpassword"; $env:PGDATABASE = "tasksdb"; $env:PGHOST = "localhost"; $env:PGPORT = "5432"
```

3) Install dependencies and start services (two terminals)

Terminal A — start read service:

```powershell
cd source-code/task-read-service
npm install
npm start
```

Terminal B — start write service:

```powershell
cd source-code/task-write-service
npm install
npm start
```

4) Serve the frontend locally

You can open `source-code/frontend/index.html` directly in a browser for simple testing (CORS enabled on services). For better experience use a simple static server, e.g.:

```powershell
# from source-code/frontend
# if you have http-server installed globally
npx http-server -c-1 . -p 3000
# then open http://localhost:3000
```

5) Test the app

- Open the frontend in the browser. It will call `http://localhost:4001/tasks` to list tasks and `http://localhost:4002/tasks` for writes.
- Use the UI to add, toggle, and delete tasks.

6) Quick API tests (curl / PowerShell Invoke-RestMethod)

List tasks:

```powershell
Invoke-RestMethod -Method Get -Uri http://localhost:4001/tasks
```

Create a task:

```powershell
Invoke-RestMethod -Method Post -Uri http://localhost:4002/tasks -Body (@{title='Buy milk'} | ConvertTo-Json) -ContentType 'application/json'
```

Update completion:

```powershell
Invoke-RestMethod -Method Put -Uri http://localhost:4002/tasks/1 -Body (@{completed=$true} | ConvertTo-Json) -ContentType 'application/json'
```

Delete a task:

```powershell
Invoke-RestMethod -Method Delete -Uri http://localhost:4002/tasks/1
```

Notes & deployment
- For cloud deployment, use path-based routing: route GET /tasks -> read service; route POST/PUT/DELETE /tasks -> write service.
- Set `API_BASE` in `frontend/script.js` (or replace with the gateway domain) so both read and write calls go to the gateway.

Troubleshooting
- If services can't connect to Postgres, verify connection variables and that Postgres accepts local TCP connections.
- If ports are in use, change the `PORT` env var when starting the service: `$env:PORT=5001; npm start`

If you want, I can also add a small npm script to start both services locally with `concurrently` or provide Docker Compose for easier local testing.