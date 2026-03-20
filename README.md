# Agentic HR Recruiter (Demo)

An AI-powered HR assistant demo that matches candidates to jobs using vector search + LLM reasoning, uploads/parses resumes, and automates meeting emails via AgentMail + ngrok webhooks. Includes a React UI for interaction.

**Tech stack**: FastAPI + LangChain + Couchbase + Agent Catalog (backend), React + Vite (frontend).

---

## 🚀 Quickstart (Docker)

### Prerequisites

- Docker installed
- Couchbase cluster (local or Capella)
- Capella AI Services, OpenAI, or Gemini API keys (for AI)
- AgentMail free account (for emails)
- ngrok free account (for webhooks)

### 1) Setup ngrok (Free Tier)

1. Sign up at [ngrok.com](https://ngrok.com) (free tier: 3 tunnels, 1GB/month).
2. Get your authtoken from the dashboard.
3. Set `NGROK_AUTHTOKEN=your-authtoken` in `.env` (ngrok runs inside Docker for webhooks).

### 2) Setup AgentMail (Free Tier)

1. Sign up at [agentmail.to](https://agentmail.to) (free tier: 1 inbox, 100 emails/month).
2. Get your API key from the dashboard.
3. Create an inbox (e.g., `hrbot@agentmail.to`).
4. Set a webhook in AgentMail to your ngrok URL (e.g., `https://abc123.ngrok-free.app/webhook/agentmail`).

### 3) Configure Environment Variables

Unite the example files into a single `.env` in the root:

```sh
cp .env.example .env
# Add frontend vars from frontend/.env.example
echo "VITE_API_BASE_URL=htttps://abc123.ngrok-free.app" >> .env
```

Edit `.env` with these settings (based on your setup):

- **Couchbase**:
  - `CB_CONN_STRING=couchbases://your-cluster.cloud.couchbase.com` (your Capella connection string)
  - `CB_USERNAME=your-username` (e.g., `hr-bot`)
  - `CB_PASSWORD=your-password` (e.g., `_LG8habcd#SZ`)
  - `CB_BUCKET=hrdemo` (bucket name)
  - `CB_SCOPE=agentc_data` (scope)
  - `CB_COLLECTION=candidates` (collection)
  - `CB_INDEX=candidates_index` (search index name)

- **Couchbase Capella**:
  - `CB_ORGANIZATION_ID=xxx` (Your Capella organization ID)
  - `CB_PROJECT_ID=XXX` (Your Capella project ID)
  - `CB_CLUSTER_ID=XXX` (Your Capella cluster ID)
  - `CB_API_KEY=XXX` (Your Capella API Secret)

These will be used to create the needed buckets, scopes, collections, indexes etc... (see `scripts/init-couchbase-capella.sh` for details)

- **Capella AI** (preferred):
  - `CAPELLA_API_ENDPOINT=https://your-endpoint.ai.cloud.couchbase.com` (from Capella AI dashboard)
  - `CAPELLA_API_LLM_KEY=your-llm-api-key` (from Capella)
  - `CAPELLA_API_LLM_MODEL=deepseek-ai/deepseek-r1-distill-llama-8b` (model name)
  - `CAPELLA_API_EMBEDDINGS_KEY=your-embeddings-api-key` (from Capella)
  - `CAPELLA_API_EMBEDDING_MODEL=nvidia/llama-3.2-nv-embedqa-1b-v2` (embedding model)

- **OpenAI** (fallback):
  - `OPENAI_API_KEY=sk-proj-...` (your OpenAI key)
  - `OPENAI_MODEL=gpt-4o` (model)

- **AgentMail**:
  - `AGENTMAIL_API_KEY=am_us_...` (from AgentMail dashboard)
  - `INBOX_USERNAME=hrbot` (inbox name, e.g., `hrbot`)

- **ngrok**:
  - `NGROK_AUTHTOKEN=1f5g6Xx...` (from ngrok dashboard)
  - `WEBHOOK_DOMAIN=abc123.ngrok-free.app` (your ngrok URL without https://)

- **Other**:
  - `SKIP_INDEX_CREATION=true` (set to true if creating vector index manually in Couchbase UI)
  - `CBCERT="-----BEGIN CERTIFICATE-----\n..."` (your Couchbase root cert, from Capella dashboard)

### 4) Build the Docker Image

Build the image (replace `https://...` with your ngrok URL for the frontend):

```sh
docker build . -t local-hr-agent --build-arg VITE_API_BASE_URL=https://abc123.ngrok-free.app
```

### 5) Run the Container

Run with your `.env` file:

```sh
docker run --name myHrAgent --env-file .env -p 8000:8000 local-hr-agent
```

### 6) Open the UI

Visit `http://localhost:8000` in your browser.

---

## 🐞 Troubleshooting

- **AI not working**: Check Capella/OpenAI keys. Set `SKIP_INDEX_CREATION=true` and create `candidates_index` manually in Couchbase using `backend/agentcatalog_index.json`.
- **Couchbase errors**: Verify connection string and cert. Ensure bucket/scope/collection exist.
- **Emails not sending**: Confirm AgentMail key and inbox. Check ngrok webhook is set correctly.

---

## 📄 Key Files

- `backend/.env.render.example`: Backend env template
- `frontend/.env.example`: Frontend env template
- `backend/agentcatalog_index.json`: Vector index definition

## Running Couchbase and the App Locally with Docker Compose

Clean: `docker compose down -v `
Build: `docker compose build --build-arg VITE_API_BASE_URL="https://abc123.ngrok-free.app"`
Run: `docker compose up` 