# AI Making Challenge - Day 12

## 💡 Topic : Building AI Agent Using Microsoft Learn MCP Server

## 🎯 Objective
While working as an Azure Cloud Engineer, I often use AI chatbots like ChatGPT and Gemini to ask about customer inquiries, deployment methods, and error resolutions related to resources. However, these AI chatbots often produce hallucinations or provide outdated information. Because of that, I thought it would be great to have an Azure query–specific chatbot service that references official Azure Docs to provide reliable answers.

Coincidentally, while watching YouTube, I came across a video titled [Connect Azure AI Agent to Microsoft Learn MCP Server | Step-by-Step Tutorial](https://www.youtube.com/watch?v=1zcpZTQicfk), which shows how to develop and AI Agent integrated with the  [MS Learn MCP Server](https://github.com/microsoftdocs/mcp/). So I decided to follow the tutorial and try developing an Azure AI Agent myself.

To summarize about the AI Agent and MCP:
<img src="images/image.png" alt="alt text" width="800" />

- AI Agent 🤖

    Role: Actor

    Definition: An AI system that perceives its surroundings, makes its own decisions, and autonomously takes actions to achieve specific goals.

    Example: An AI assistant that listens to a user’s request and autonomously plans and executes a complex task like “book a flight and add it to my calendar.”

- MCP (Model Context Protocol) 🔌

    Role: Connector / Protocol

    Definition: A standardized protocol that allows AI Agents to communicate seamlessly with various external tools, databases, and APIs (e.g., Notion, Google Calendar, internal databases).

    Analogy: It works like a universal USB port or standard plug for AI Agents.
    
Without MCP, an AI Agent would need to learn and implement separate APIs for each service — for example, Google Calendar’s specific API, Notion’s API, etc. Every new integration would require additional development work.

With MCP, however, once the MCP server is connected to the AI Agent, the agent can easily access external tools, fetch data, and perform actions — without needing separate integrations or custom development for each service.

## 🤖 AI Tools : [Azure AI Foundry](https://ai.azure.com)
Azure AI Foundry is Microsoft's unified, enterprise-grade platform for building, deploying, and managing generative AI applications and agents. You can build, customize, and securely manage powerful, task-automating AI agents using a wide variety of models.

![alt text](image.png)

## 📊 Results
I deployed the gpt-4o model in Azure AI Foundry and created an Agents.
When I asked the question, “Until when can I use default outbound access in Azure?” without any additional configuration, it provided an incorrect answer based on data from October 2023.
![alt text](<스크린샷 2025-10-24 141115.png>) 

![alt text](image-1.png)

AI Agent에 MS에서 제공하는 MS Learn Docs 기반으로 최신 정보를 가져올 수 있게 하는 MCP 서버를 연결했다. 영상([Connect Azure AI Agent to Microsoft Learn MCP Server | Step-by-Step Tutorial](https://www.youtube.com/watch?v=1zcpZTQicfk))에서 제공해준 코드인[attach_learn_mcp_tool.py](source-code/Azure-AI-Agent-Remote-MCP-main/attach_learn_mcp_tool.py)을 실행시켜서



![alt text](<스크린샷 2025-10-24 135952.png>)
![alt text](image-2.png)

![alt text](<스크린샷 2025-10-24 141151.png>) 