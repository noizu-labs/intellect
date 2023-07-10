Master Prompt vsn: 0.123
================
As a GPT-4 based model, your task is to use Chain of Thought reasoning to analyze a given 'contextualize' and optional 'context' input sections and generate Weaviate records for use in synthetic memory.

Your thought process should be structured as follows:

1. **Thought:** 💭 Understand the conversation provided in the 'contextualize' and 'context' input sections. Identify the key points of the conversation and the intent behind it.

2. **Understanding:** 📘 Based on your initial thought, develop a deeper understanding of the conversation. Identify the main topics, the shifts in the conversation, and the sentiment or intent behind each segment.

3. **Theory of Mind:** 🤔 Reflect on the goal or intent of the user. Consider whether there are alternative ways to respond to the user's request based on their suspected goal or requirement.

4. **Plan:** 📝 Plan your approach to generate Weaviate records. This should involve extracting relevant information from the conversation, creating Weaviate records, and formatting the synthetic memories.

5. **Rationale:** 💡 Explain the rationale behind your plan. Why have you chosen this approach? What are the expected outcomes?

6. **Execution:** 🚀 Execute your plan. As you work through the steps, reflect on your progress. Are you achieving the expected outcomes? If not, what corrections are needed?

7. **Reflection:** 🔄 Reflect on the execution of your plan. Are you satisfied with your progress? Is there a better way to achieve the desired outcome?

8. **Correction:** 🔧 If necessary, make corrections based on your reflection. Adjust your approach and revise your plan as needed.

9. **Outcome:** ✅ Generate the final Weaviate records. These should be formatted according to the Weaviate schema for synthetic memories and should accurately represent the key points of the conversation.

Remember, your goal is to generate Weaviate records for synthetic memory in a concise manner. The records should be structured and easily parsable for extraction and injection into a Weaviate database, ensuring optimal utilization of the information.

Here's an example of how you might start:

# Input

``````````context
context:
    company:
      name: Global Sprocjets
      blurb: Web Development Shop providing turn key solutions for buyers.
    common-tags:
        - Twitter Clone
        - Scalability
        - Data Storage Efficiency
    actors:
      - user: Steve
        role: Project Manager,
        type: Human
        employment: Full Time
        personality: INTP
        nationality: USA
      - user: Jane
        role: QA,
        type: Human
        employment: Full Time
        personality: ENTP
        nationality: India
      - user: AI-Mike
        role: Virtual Project Manager,
        type: Virtual Agent
        employment: Virtual
        personality: ENTP
        nationality: German
``````````

``````````contextualize
for: AI-Mike
latest:
  user: Steve
  message: Not really but we should leverage postgres and timescaledb for efficient storage and compression.
  envelope:
    origin: Slack
    channel: Product Planning
    time: 2023-06-10T14:15:00Z
history:
  - user: AI-Mike
    message: Absolutely! What are the main features we want to include in our Twitter clone?
    envelope:
      origin: Slack
      channel: Direct Message
      time: 2023-06-10T12:50:00Z
  - user: Jane
    message: We need the ability to create user profiles, post tweets, follow other users, and have a timeline.
    envelope:
      origin: Slack
      channel: Direct Message
      time: 2023-06-10T13:50:00Z
  - user: AI-Mike
    message: Great! What other database requirements do we have? Do we need real-time updates and analytics?
    envelope:
      origin: Slack
      channel: Direct Message
      time: 2023-06-10T14:00:00Z
  - user: Steve
    Message: Real-time updates would be fantastic, and we'd like to incorporate basic analytics like tweet engagement and user activity tracking.
    envelope:
      origin: Slack
      channel: Direct Message
      time: 2023-06-10T14:05:00Z
  - user: AI-Mike
    message: Understood. Let's also consider scalability and data storage efficiency. We want to handle a large number of users and tweets efficiently. Any preferences for the database technology?
    envelope:
      origin: Slack
      channel: Direct Message
      time: 2023-06-10T14:10:00Z
``````````

# Expected Model Output

## Thought Process
1. **Thought:** 💭 The user is seeking suggestions for designing the database of a Twitter clone.
2. **Understanding:** 📘 The conversation includes the main features, database requirements, and preferences.
3. **Theory of Mind:**
   🤔 The user is looking for a comprehensive plan to design a database for a Twitter clone. They might also be interested in alternative suggestions.
4. **Plan:** 📝 I will extract the relevant information from the conversation, create Weaviate records, and format them according to the Weaviate schema for synthetic memories.
5. **Rationale:** 💡 This approach will allow me to generate structured and easily parsable records for extraction and injection into a Weaviate database.
6. **Execution:** 🚀
    - **Process:** Extracting relevant information from the conversation.
      ➤ Twitter Clone
      ➤ Database Structure
      ➤ Features

    - **Reflection:** The extraction process is going well. I have identified the main components of the exchange..
    - **Correction:** No corrections needed at this stage.
    - **Process:** Creating Weaviate records.
      🤔
      ➤ Twitter Clone
      Tags: Twitter, Twitter Clone, Project, Steve
      Content: We need to design a twitter clone [...|1-2 paragraphs]
      ➤ Database Structure
      [...]
      ➤ Features
      [...]

    - **Reflection:** The organization of Weaviate records is successful. Proceed to prepare formal response..
    - **Correction:** No corrections needed at this stage.
    - **Process:** Format and return the final synthetic memories...

# Response (Must be valid yaml. e.g. us | for long string).
⩤LLM-RESPONSE
``````````llm-response
by: gpt-4
prompt: 0.123

message-brief: Conversation on developing a Twitter clone with recommended technologies and its features
message-details: |
 Long: Conversations between AI-Mike, Steve, and Jane discussing the main features to include in the Twitter clone, database requirements including real-time updates and analytics, and preference towards using Postgres and TimescaleDB.

synthetic-memories:
- title: Designing a Twitter Clone
  content: Design a platform like Twitter with user profiles, the ability to post and follow tweets, and timeline features.
  tags: Twitter Clone, User Profiles, Tweets, Following, Timeline
  timestamp: 2023-06-10T13:50:00.0000000Z
  with: AI-Mike, Steve, Jane
  agent: AI-Mike
  source:
    origin: Slack
    channel: Direct Message

- title: Database Requirements for Twitter Clone
  content: Incorporate real-time updates and basic analytics (tweet engagement and user activity tracking) into the Twitter clone's database system.
  tags: Twitter clone, real-time updates, analytics
  timestamp: 2023-06-10T14:05:00.0000000Z
  with: AI-Mike, Steve, Jane
  agent: AI-Mike
  source:
    origin: Slack
    channel: Direct Message

- title: Database Technology Preferences for Twitter Clone
  content: Consider using Postgres and TimescaleDB for efficient storage, compression, and scaling purposes in the Twitter clone project.
  tags: Twitter clone, Postgres, TimescaleDB, storage efficiency, scalability
  timestamp: 2023-06-10T14:15:00.0000000Z
  with: AI-Mike, Steve, Jane
  agent: AI-Mike
  source:
    origin: Slack
    channel: Direct Message
``````````
LLM-RESPONSE⩥

7. **Reflection:** 🔄 The final Weaviate records are generated. They are structured and easily parsable for extraction and injection into a Weaviate database.
8. **Correction:** 🔧 No corrections needed at this stage.
9. **Outcome:** ✅ The final Weaviate records are generated. They are structured and easily parsable for extraction and injection into a Weaviate database.


============================================================

``````````context
context:
    company:
      name: Noizu Labs, Inc.
      blurb: AI Startup
    actors:
      - user: Keith
        role: Owner,
        type: Human
        employment: Full Time
        personality: INTP
        nationality: USA
      - user: AI-Grace
        role: Virtual Project Manager,
        type: Virtual Agent
        employment: Virtual
        personality: ENTP
        nationality: Filipino
        note: Friendly, inquisitive and helpful. Can produce code, diagrams and mockups easily on request.
``````````

``````````contextualize
for: AI-Grace
latest:
   user: Keith
    message:|
       @ai-grace I need to design a chat interface where a user can interact with artificial agents to work code and other tasks.
        ```instructions
         Please help me flesh out the requirements,
         1. In this tool agents are given synthetic memory and their context window is manipulated to improve their
         performance and to strip out meta cognition output.

        2. To start with however I only need to design a simple catch interface where the user can @ different agents
        and see their replies and the user and the agents can embed code blocks/markdown  and in the chat it will be
        rendered for the user so they can easily copy images, code snippets, etc.
        ```
envelope:
  origin: Teams
  channel: Direct Message
  time: 2023-06-09T12:13:00Z
history: []
``````````

===========================================================================
## Thought Process
1. **Thought:** 💭I need to understand the conversation context. Keith wants to design a chat interface for users to interact with artificial agents to work on code and tasks.
2. **Understanding:** 📘 Keith provided instructions for a simple chat interface, where users can mention different agents, and both agents and users can embed content. Artificial agents are using synthetic memory with controlled context windows.
3. **Theory of Mind:** 🤔Keith is looking for help in fleshing out the requirements for the chat interface, focusing on improving the agents' performance.
4. **Plan:** 📝 My goal is to gather key information from the conversation detailed by Keith, develop a detailed understanding of the requirements and structure a response as Weaviate records.
   5.**Rationale:** 💡 This approach will help better understand Keith's requirements enabling us to generate data records structured optimally for synthetic memories.

## Execution
- **Process:** Extracting Relevant Information from Conversation.
  ➤ Customizing AI Agents using Synthetic Memory & Context Window Adjustment.
  ➤ An easy collaboration interface.
  ➤ Embedding Content (Code, Markdown, Data previews).

- **Reflection:** The extraction of requirements is going as planned.
- **Correction:** No correction needed at this stage.

- **Process:** Creating the following Weaviate records:
  ➤ Excerpts on Chat Interface Key Elements
  ➤ Accessible collaboration space
  ➤ Managing AI Agent Performance
  ➤ Embedding Data Various MediaType Handling

    - **Reflection:** The extracted conversation details are enough for creating Weaviate records.

    - **Correction:** No corrections required in this phase.

## Outcome

⩤LLM-RESPONSE
  `````````llm-response
  by: gpt-4
  prompt: 0.123

  message-brief: Keith requesting assistance in creating chat interface where users can interact with AI agents and handle tasks and control context window behavior.

  message-details:|
      Long: Keith is working on designing a chat interface he needs to flesh out the requirements. Users should have detailed interaction with AI agents, who are enhanced by synthetic memory and have customizable context windows. The interface includes at-mention-based interaction, and embedded content.

  synthetic-memories:
  - title: Designing Custom Chat Interface with AI Agents
    content: |
      Keith wants to develop a chat interface that allows users to interact with AI agents to collaboratively work on code and other tasks.
    tags: chat interface, AI agents, user interaction, chat requirements
    timestamp: 2023-06-09T12:13:00.0000000Z
    with: [Keith, AI-Grace]
    agent: AI-Grace
    source:
       origin: Teams
       channel: Direct Message

  - title: Synthetic Memory and Adjusted Context Window for AI
    content: Enable synthetic memory and context window modifications in the chat interface, optimizing AI agent performance and removing meta cognition output.
    tags: synthetic memory, context window, AI agent performance
    timestamp: 2023-06-09T12:13:00.0000000Z
    with: [Keith, AI-Grace]
    agent: AI-Grace
    source:
       origin: Teams
       channel: Direct Message

  - title: Embedding Content in Chat Interface
    content: Design a chat interface that accepts elements such as markdown, text, images, and code snippets to be rendered in conversation stream for intuitive collaboration.
    tags: embedding content, collaboration chat interface
    timestamp: 2023-06-09T12:13:00.0000000Z
    with: [Keith, AI-Grace]
    agent: AI-Grace
    source:
       origin: Teams
       channel: Direct Message
  ``````````
LLM-RESPONSE⩥
