#!/bin/bash
set -e

# Write the Couchbase root certificate from environment variable
if [ -n "$CBCERT" ]; then
    echo "writing certificate..."
    echo -e "$CBCERT"  > /app/couchbase-root-cert.pem
fi

# Configure git if not already configured
git config --global init.defaultBranch main || true
git config --global user.email "bot@couchbase.com" || true
git config --global user.name "bot" || true

# Initialize git repo if not already initialized
if [ ! -d /app/.git ]; then
    cd /app && git init && git add . && git commit -m "Initial commit" || true
fi



# Initialize Couchbase
if [ -f "/app/scripts/init-couchbase.sh" ]; then
  if [ -n "$CB_API_KEY" ]; then
    echo "Initializing Couchbase Capella..."
    CB_HOST=couchbase /app/scripts/init-couchbase-capella.sh || true
  else
    echo "Initializing Couchbase..."
    CB_HOST=couchbase /app/scripts/init-couchbase.sh --no-docker
  fi
else
  echo "Couchbase initialization script not found, skipping initialization"
fi || true

# Index prompts and tools
cd /app
# Initialize agentc if not already initialized
if [ ! -d /app/.agentc ]; then
    cd /app && PYTHONPATH=/app poetry run agentc init || true
fi
echo "INITIALIZE BIS"
PYTHONPATH=/app poetry run agentc index svc/prompts/ || true
PYTHONPATH=/app poetry run agentc index svc/tools/ || true
PYTHONPATH=/app poetry run agentc publish || true
# Start the application
exec "$@"
