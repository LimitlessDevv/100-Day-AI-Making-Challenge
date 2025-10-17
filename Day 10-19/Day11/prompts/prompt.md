```Please create a complete, full-stack task manager web application with the following specifications.

Project Overview: The goal is to build a task manager application with a separate frontend and a distributed backend. I will be handling the cloud deployment myself, so the code should be structured to support a microservices architecture.

Frontend Requirements (Separate index.html, style.css, and script.js files):

Functionality: The user interface must allow users to:

Add a new task.

Delete an existing task.

Mark a task as completed (toggle status).

Styling: Use modern CSS to create a clean, intuitive, and responsive user interface that works well on both desktop and mobile devices.

Markup: Use semantic HTML and ensure the application is accessible (e.g., proper use of labels, ARIA attributes, and keyboard navigability).

Backend Requirements (Node.js & PostgreSQL):

Technology Stack: The backend must be built with Node.js and use a PostgreSQL database for data persistence.

Architecture: The backend logic must be split into two separate and independent Node.js microservices:

task-read-service: This service is responsible only for fetching data. It should expose a single API endpoint:

GET /tasks: Returns a list of all tasks from the PostgreSQL database.

task-write-service: This service is responsible for all data modification operations. It should expose the following API endpoints:

POST /tasks: Creates a new task in the database.

PUT /tasks/:id: Updates the completion status of a specific task.

DELETE /tasks/:id: Deletes a specific task from the database.

Database: Provide the SQL CREATE TABLE statement for the tasks table in PostgreSQL.

Deployment Context (For your information): Please note that I will be deploying this application on my own cloud infrastructure (specifically Azure). The final architecture will use an Application Gateway to perform path-based routing to the backend services, which will be managed behind a Load Balancer. For example, GET requests to /tasks will be routed to the task-read-service, while POST, PUT, and DELETE requests will be routed to the task-write-service. The code you provide should be structured to facilitate this type of deployment.
```