# Module: 2

### 2.1.1: Workflow Orchestration

- Run workflows which contain a number of predefined steps
- Monitor and log errors, as well as taking a number of extra steps when they occur
- Automatically run workflows based on schedules and events

### 2.1.2: Kestra

- Kestra is an open-source, infinitely-scalable orchestration platform
    - Build with Flow code (YAML), No-code or with the AI Copilot - flexibility in how you build your workflows
    - 1000+ Plugins - integrate with all the tools you use
    - Support for any programming language - pick the right tool for the job
    - Schedule or Event Based Triggers - have your workflows respond to data

### 2.2.1: Installing Kestra

- Docker compose YAML file
    - Postgres for Kestra
    - Kestra 1.1

### 2.2.2: Kestra Concepts

- To start building workflows in Kestra, we need to understand a number of concepts.
    - [Flow](https://go.kestra.io/de-zoomcamp/flow) - a container for tasks and their orchestration logic.
    - [Tasks](https://go.kestra.io/de-zoomcamp/tasks) - the steps within a flow.
    - [Inputs](https://go.kestra.io/de-zoomcamp/inputs) - dynamic values passed to the flow at runtime.
    - [Outputs](https://go.kestra.io/de-zoomcamp/outputs) - pass data between tasks and flows.
    - [Triggers](https://go.kestra.io/de-zoomcamp/triggers) - mechanism that automatically starts the execution of a flow.
    - [Execution](https://go.kestra.io/de-zoomcamp/execution) - a single run of a flow with a specific state.
    - [Variables](https://go.kestra.io/de-zoomcamp/variables) - key–value pairs that let you reuse values across tasks.
    - [Plugin Defaults](https://go.kestra.io/de-zoomcamp/plugin-defaults) - default values applied to every task of a given type within one or more flows.
    - [Concurrency](https://go.kestra.io/de-zoomcamp/concurrency) - control how many executions of a flow can run at the same time.

### **2.2.3: Orchestrate Python Code**

- `io.kestra.plugin.scripts.python.Script`
    - To put Python code in YAML and run the flow
- `io.kestra.plugin.scripts.python.Commands`
    - To put Python code in a .py file and run the flow
- `Kestra.outputs(outputs)`
    - To output the results

### 2.3.1: **Getting Started Pipeline**

- Extracts data via HTTP REST API
- Transforms that data in Python
- Queries it using DuckDB

### **2.3.2: Load Taxi Data to Postgres**

- Select Year & Month
- Set Labels
    - `io.kestra.plugin.core.execution.Labels`
- Extract CSV Data
    - `io.kestra.plugin.scripts.shell.Commands`
- If taxi == “Yellow” `io.kestra.plugin.core.flow.If`
    - `io.kestra.plugin.jdbc.postgresql.Queries`
    - Create Yellow Final Table
    - Create Yellow Monthly Table
    - Load Data to Monthly Table
    - Merge Yellow Data
- If taxi == “Green” `io.kestra.plugin.core.flow.If`
    - `io.kestra.plugin.jdbc.postgresql.Queries`
    - Create Green Final Table
    - Create Green Monthly Table
    - Load Data to Monthly Table
    - Merge Green Data

### 2.3.3: **Scheduling and Backfills**

- Scheduling the flow
    - `io.kestra.plugin.core.trigger.Schedule`
    - Cron expression
- Backfilling
    - Backfilling is the process of running a flow for a period in the **past**
    - Kestra allows you to trigger backfills directly from the UI, specifying a start and end date
    - It will then automatically spawn individual executions for every scheduled interval within that range

### 2.4.1: ETL vs. ELT

- ETL
    - **Extract:** Firstly, we extract the dataset from GitHub
    - **Transform:** Next, we transform it with Python
    - **Load:** Finally, we load it into our Postgres database
- ELT
    - **Extract:** Firstly, we extract the dataset from GitHub
    - **Load:** Next, we load this dataset (in this case, a csv file) into a data lake (Google Cloud Storage)
    - **Transform:** Finally, we can create a table inside of our data warehouse (BigQuery) which uses the data from our data lake to perform our transformations.
- The reason for loading into the data warehouse before transforming means we can utilize the cloud's performance benefits for transforming large datasets.

### 2.4.2: Setup GCP

- Run the flow to setup GCP service account
    - `io.kestra.plugin.core.kv.Set`
    - GCP_PROJECT_ID
    - GCP_LOCATION
    - GCP_BUCKET_NAME
    - GCP_DATASET

### **2.4.3: Load Data into BigQuery with ELT**

- Set Labels
    - `io.kestra.plugin.core.execution.Labels`
- Extract CSV Data
    - `io.kestra.plugin.scripts.shell.Commands`
- Upload Data to GCS
    - `io.kestra.plugin.gcp.gcs.Upload`
- If “Yellow”
    - `io.kestra.plugin.gcp.bigquery.Query`
    - Main Yellow Tripdata Table
    - External Table
    - Monthly Table
    - Merge to Main Table
- If “Green”
    - `io.kestra.plugin.gcp.bigquery.Query`
    - Main Green Tripdata Table
    - External Table
    - Monthly Table
    - Merge to Main Table
- Purge Files
    - `io.kestra.plugin.core.storage.PurgeCurrentExecutionFiles`

### 2.4.4: **Schedule and Backfills**

- Backfill historical data directly from the Kestra UI.
- Since we now process data in a cloud environment with infinitely scalable storage and compute, we can backfill the entire dataset for both the yellow and green taxi data without the risk of running out of resources on our local machine.

### 2.5.1: **Using AI for Data Engineering**

- AI tools can help us:
    - **Generate workflows faster**: Describe what you want to accomplish in natural language instead of writing YAML from scratch
    - **Avoid errors**: Get syntax-correct, up-to-date workflow code that follows best practices
- However, AI is only as good as the context we provide.

### 2.5.2: **Context Engineering with ChatGPT**

- **Key Learning:** Context is Everything
    - Without proper context:
        - ❌ Generic AI assistants hallucinate outdated or incorrect code
        - ❌ You can't trust the output for production use
    - With proper context:
        - ✅ AI generates accurate, current, production-ready code
        - ✅ You can iterate faster by letting AI generate boilerplate workflow code

### **2.5.3: AI Copilot in Kestra**

- **Key Learning:** Context matters! AI Copilot has access to current Kestra documentation, generating Kestra flows better than a generic ChatGPT assistant.
    - Copilot generates executable, working YAML
    - Copilot uses correct plugin types and properties
    - Copilot follows current Kestra best practices

### **2.5.4 Retrieval Augmented Generation (RAG)**

- **RAG (Retrieval Augmented Generation)** is a technique that:
    1. **Retrieves** relevant information from your data sources
    2. **Augments** the AI prompt with this context
    3. **Generates** a response grounded in real data
- This solves the hallucination problem by ensuring the AI has access to current, accurate information at query time.
- How RAG works in Kestra:
    - Ask AI
    - Fetch Docs
    - Create Embeddings
    - Find Similar Content
    - Add Context to Prompt
    - LLM Answer
- **The Process:**
    1. **Ingest documents**: Load documentation, release notes, or other data sources
    2. **Create embeddings**: Convert text into vector representations using an LLM
    3. **Store embeddings**: Save vectors in Kestra's KV Store (or a vector database)
    4. **Query with context**: When you ask a question, retrieve relevant embeddings and include them in the prompt
    5. **Generate response**: The LLM has real context and provides accurate answers
- **RAG Best Practices**
    1. **Keep documents updated**: Regularly re-ingest to ensure current information
    2. **Chunk appropriately**: Break large documents into meaningful chunks
    3. **Test retrieval quality**: Verify that the right documents are retrieved
- **Key Learning:** RAG (Retrieval Augmented Generation) grounds AI responses in current documentation, eliminating hallucinations and providing accurate, context-aware answers.