AI Making Challenge - Day 3

Topic: Exploring Genspark – A Generalized AI Super Agent

🎯 Objective
Test how multiple AI capabilities can be integrated into a single platform and evaluate its usefulness for automating proposal-related work.

🛠️ AI Tools
Genspark
A “super agent” service that allows users to access multiple AI features in one place:

AI Chat

Coding

Document Creation

Image/Video Generation

Meeting Notetaking

Calling

Unlike specialized AI tools that focus on a single domain, Genspark provides a generalized AI platform where different functions can be used seamlessly in one interface.

📊 Results

I tested a few of the available services, focusing mainly on proposal automation since I recently spent significant time doing manual research and formatting.

1. Making a PowerPoint Presentation

Prompt used:

Create a PowerPoint presentation in the style of a Korean IT company proposal.  
The proposal should focus on **Microsoft Azure Cloud** as the core platform.  
The tone and manner should be professional, trustworthy, and structured to clearly deliver Azure-based optimization strategies to the client.  
Each slide should avoid unnecessary decorations and instead highlight key messages with structured diagrams, Azure architecture icons, and business-oriented visuals.  

Organize the slides based on the following requirements, explicitly leveraging Azure services and capabilities:  
1. Establishing and executing infrastructure cost optimization strategies (e.g., Azure Cost Management, Reserved Instances, Spot VMs)  
2. Performing and optimizing Infra [up/down/out/in] scaling with history management (e.g., Azure Virtual Machine Scale Sets, AKS Autoscaling, Application Gateway Autoscaling)  
3. Optimizing infrastructure configuration and improving performance based on monitoring data, with process standardization (e.g., Azure Monitor, Log Analytics, Application Insights)  
4. Proposing and executing optimization strategies including Database and Middleware performance tuning (e.g., Azure Database for PostgreSQL, Azure SQL Database, Azure App Service, Azure Cache for Redis)  


What’s interesting is that Genspark shows not just the final output, but also the thinking process behind it — what it’s searching, which steps it’s taking, and how it builds the result.

Sample outputs:




The results were not fully aligned with the typical Korean IT company proposal style, but still useful as references.

2. AI Chat (Multi-Model)

In AI Chat Mode, multiple AI models (GPT-5, Claude, etc.) can be used.
I tested it with the following prompt:

Write a client-facing proposal in the style of a Korean IT company, focusing on Microsoft Azure Cloud optimization strategies.  
The proposal should be professional, trustworthy, and well-structured, clearly addressing the following client requirements:

1. Establishing and executing infrastructure cost optimization strategies  
2. Performing and optimizing Infra [up/down/out/in] scaling with history management  
3. Optimizing infrastructure configuration and improving performance based on monitoring data, with process standardization  
4. Proposing and executing optimization strategies including Database and Middleware performance tuning  

The proposal should include:  
- Executive Summary: Key objectives and client value  
- Approach & Methodology: How Azure services will be used to address each requirement  
- Detailed Strategies: Azure tools, processes, and best practices for each area  
- Expected Benefits: Cost savings, performance improvements, scalability, and reliability  
- Implementation Plan: High-level roadmap or phased approach  
- Differentiation: Why our company’s approach is effective and trustworthy  


Sample outputs from different models:

GPT-5 Thinking High




Claude Sonnet 4




3. Creating a Website

I reused the Challenge Tracker App prompt from Day 1 (originally tested on Base44) and asked Genspark to generate it.

Prompt (excerpt):

App Name: The 100 Days of AI Making Challenge Tracker  

Objective:  
Track the "100 Days of AI Making Challenge" progress on a single page.  
Each day should allow marking completion and adding a description.  
Provide a grid view (1–100 days) with a progress bar and milestone badges.  


Results:




The site worked well and looked clean — very similar in quality to what I had tested on Base44.

📝 Reflection

Having multiple AI features (chat, docs, code, images, etc.) in one platform is very convenient compared to juggling many separate services.

For specialized tasks, individual AI tools might still perform better, but Genspark’s generalized approach didn’t feel lacking.

Especially for proposal writing automation, it saved me a lot of manual formatting and research work.

I see potential in using it occasionally as an all-in-one workspace for AI-driven tasks.