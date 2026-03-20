#!/bin/sh
# ---------------------------------------------------------------------------
# init-couchbase-capella.sh
#
# Configures Couchbase buckets, scopes, collections, GSI indexes, and the
# FTS vector index required by the hr-agent application on Couchbase Capella.
#
# Usage:
#   ./scripts/init-couchbase-capella.sh
#
# Environment variables (all required):
#   CB_PROJECT_ID     Couchbase Capella project ID
#   CB_CLUSTER_ID     Couchbase Capella cluster ID
#   CB_API_KEY        Couchbase Capella API key with admin permissions
#   CB_BUCKET         Bucket name (default: default)
#   CB_SCOPE          Scope name (default: agentc_data)
#   CB_COLLECTION     Collection name (default: candidates)
#   CB_AGENDA_COLLECTION Collection name for agenda (default: timeslots)
#   CB_INDEX          FTS index name (default: candidates_index)
#   AGENT_CATALOG_BUCKET Bucket for agent catalog (default: agentc)
#   AGENT_CATALOG_LOGS_SCOPE Scope for logs (default: agent_activity)
#   AGENT_CATALOG_LOGS_COLLECTION Collection for logs (default: logs)
#   AGENT_CATALOG_GRADES_COLLECTION Collection for grades (default: grades)
# ---------------------------------------------------------------------------
set -e

CB_ORGANIZATION_ID=${CB_ORGANIZATION_ID:?CB_ORGANIZATION_ID is required}
CB_PROJECT_ID=${CB_PROJECT_ID:?CB_PROJECT_ID is required}
CB_CLUSTER_ID=${CB_CLUSTER_ID:?CB_CLUSTER_ID is required}
CB_API_KEY=${CB_API_KEY:?CB_API_KEY is required}
CB_BUCKET=${CB_BUCKET:-default}
CB_SCOPE=${CB_SCOPE:-agentc_data}
CB_COLLECTION=${CB_COLLECTION:-candidates}
CB_AGENDA_COLLECTION=${CB_AGENDA_COLLECTION:-timeslots}
CB_INDEX=${CB_INDEX:-candidates_index}
AGENT_CATALOG_BUCKET=${AGENT_CATALOG_BUCKET:-agentc}
AGENT_CATALOG_LOGS_SCOPE=${AGENT_CATALOG_LOGS_SCOPE:-agent_activity}
AGENT_CATALOG_LOGS_COLLECTION=${AGENT_CATALOG_LOGS_COLLECTION:-logs}
AGENT_CATALOG_GRADES_COLLECTION=${AGENT_CATALOG_GRADES_COLLECTION:-grades}

# Capella API endpoints
API_BASE="https://cloudapi.cloud.couchbase.com"
PROJECTS_BASE=${API_BASE}/v4/organizations/${CB_ORGANIZATION_ID}/projects/${CB_PROJECT_ID}
CLUSTERS_BASE=${PROJECTS_BASE}/clusters/${CB_CLUSTER_ID}

# Check if bucket exists
check_bucket_exists() {
  bucket="$1"
  bucket_id=$(encode_bucket_id "$bucket")
  echo "Checking if bucket ${bucket} exists..."
  HTTP_STATUS=$(capella_curl -s -o /dev/null -w "%{http_code}" \
    -X GET "${CLUSTERS_BASE}/buckets/${bucket_id}")
  if [ "$HTTP_STATUS" = "200" ]; then
    echo "  Bucket ${bucket} already exists"
    return 0
  elif [ "$HTTP_STATUS" = "404" ]; then
    echo "  Bucket ${bucket} does not exist"
    return 1
  else
    echo "  Error checking bucket status: HTTP ${HTTP_STATUS}"
    return 2
  fi
}

# Helper functions

# Encode bucket name to URL-compatible base64
encode_bucket_id() {
  echo -n "$1" | base64 
}

capella_curl() {
  curl -v -H "Authorization: Bearer ${CB_API_KEY}" "$@"
}

wait_for_capella() {
  label="$1"
  echo "Waiting for ${label}..."
  i=0
  while [ $i -lt 90 ]; do
    if capella_curl -w "%{http_code}" "$@" | grep -q "200"; then
      echo "  ${label} ready"
      return 0
    fi
    sleep 2
    i=$((i + 1))
  done
  echo "  ${label} did not become ready in time" >&2
  exit 1
}

create_capella_bucket() {
  name="$1"
  ram="${2:-512}"
  capella_curl -X POST "${CLUSTERS_BASE}/buckets" \
    -H "Content-Type: application/json" \
    -d "{
      \"name\": \"${name}\",
      \"memoryAllocationInMb\": ${ram},
    }" 
  sleep 3
}

create_capella_scope() {
  bucket="$1"
  scope="$2"
  echo "  Bucket: ${bucket}"
  bucket_id=$(encode_bucket_id "$bucket")
  echo "  Scope: ${bucket}.${scope}"
  capella_curl -X POST "${CLUSTERS_BASE}/buckets/${bucket_id}/scopes" \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"${scope}\"}"
  sleep 2
}

create_capella_collection() {
  bucket="$1"
  scope="$2"
  coll="$3"
  echo "  Bucket: ${bucket}"
  bucket_id=$(encode_bucket_id "$bucket")
  echo "  Collection: ${bucket}.${scope}.${coll}"
  capella_curl -X POST "${CLUSTERS_BASE}/buckets/${bucket_id}/scopes/${scope}/collections" \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"${coll}\"}"
  sleep 2
}

run_capella_n1ql() {
  stmt="$1"
  escaped=$(printf '%s' "$stmt" | sed 's/\\/\\\\/g; s/"/\\"/g')
  result=$(capella_curl -X POST "${CLUSTERS_BASE}/queryService/indexes" \
    -H "Content-Type: application/json" \
    -d "{\"definition\": \"${escaped}\"}")
  if echo "$result" | grep -q '"status": *"success"'; then
    echo "     OK"
  else
    errors=$(echo "$result" | grep -o '"errors": *\[[^]]*\]' | head -c 300 || true)
    if [ -n "$errors" ]; then
      echo "     WARN: ${errors}"
    else
      printf '     WARN: %.300s\n' "$result"
    fi
  fi
}

# ---------------------------------------------------------------------------
# 1. Check if initialization is needed
# ---------------------------------------------------------------------------
echo ""
if check_bucket_exists "${CB_BUCKET}"; then
  echo "Initialization not needed - bucket already exists"
  echo "Exiting..."
  exit 0
fi

# ---------------------------------------------------------------------------
# 1. Create buckets
# ---------------------------------------------------------------------------
echo ""
echo "Creating buckets..."
create_capella_bucket "${CB_BUCKET}"             512
create_capella_bucket "${AGENT_CATALOG_BUCKET}"  256
sleep 10

# ---------------------------------------------------------------------------
# 2. Create scopes and collections
# ---------------------------------------------------------------------------
echo ""
echo "Creating scopes and collections..."

create_capella_scope      "${CB_BUCKET}"            "${CB_SCOPE}"
sleep 10
create_capella_collection "${CB_BUCKET}"            "${CB_SCOPE}"              "${CB_COLLECTION}"
create_capella_collection "${CB_BUCKET}"            "${CB_SCOPE}"              "${CB_AGENDA_COLLECTION}"

create_capella_scope      "${AGENT_CATALOG_BUCKET}" "${AGENT_CATALOG_LOGS_SCOPE}"
sleep 10
create_capella_collection "${AGENT_CATALOG_BUCKET}" "${AGENT_CATALOG_LOGS_SCOPE}" "${AGENT_CATALOG_LOGS_COLLECTION}"
create_capella_collection "${AGENT_CATALOG_BUCKET}" "${AGENT_CATALOG_LOGS_SCOPE}" "${AGENT_CATALOG_GRADES_COLLECTION}"

sleep 10

# ---------------------------------------------------------------------------
# 3. Create GSI (N1QL) indexes
# ---------------------------------------------------------------------------
echo ""
echo "Creating GSI indexes..."

run_capella_n1ql "CREATE PRIMARY INDEX IF NOT EXISTS ON \`${CB_BUCKET}\`.\`${CB_SCOPE}\`.\`${CB_COLLECTION}\`"
run_capella_n1ql "CREATE PRIMARY INDEX IF NOT EXISTS ON \`${CB_BUCKET}\`.\`${CB_SCOPE}\`.\`${CB_AGENDA_COLLECTION}\`"
run_capella_n1ql "CREATE PRIMARY INDEX IF NOT EXISTS ON \`${AGENT_CATALOG_BUCKET}\`.\`${AGENT_CATALOG_LOGS_SCOPE}\`.\`${AGENT_CATALOG_LOGS_COLLECTION}\`"
run_capella_n1ql "CREATE PRIMARY INDEX IF NOT EXISTS ON \`${AGENT_CATALOG_BUCKET}\`.\`${AGENT_CATALOG_LOGS_SCOPE}\`.\`${AGENT_CATALOG_GRADES_COLLECTION}\`"

run_capella_n1ql "CREATE INDEX IF NOT EXISTS idx_candidates_email   ON \`${CB_BUCKET}\`.\`${CB_SCOPE}\`.\`${CB_COLLECTION}\`(email)"
run_capella_n1ql "CREATE INDEX IF NOT EXISTS idx_candidates_name    ON \`${CB_BUCKET}\`.\`${CB_SCOPE}\`.\`${CB_COLLECTION}\`(name)"
run_capella_n1ql "CREATE INDEX IF NOT EXISTS idx_timeslots_type     ON \`${CB_BUCKET}\`.\`${CB_SCOPE}\`.\`${CB_AGENDA_COLLECTION}\`(type)"
run_capella_n1ql "CREATE INDEX IF NOT EXISTS idx_logs_session       ON \`${AGENT_CATALOG_BUCKET}\`.\`${AGENT_CATALOG_LOGS_SCOPE}\`.\`${AGENT_CATALOG_LOGS_COLLECTION}\`(session_id)"
run_capella_n1ql "CREATE INDEX IF NOT EXISTS idx_grades_application ON \`${AGENT_CATALOG_BUCKET}\`.\`${AGENT_CATALOG_LOGS_SCOPE}\`.\`${AGENT_CATALOG_GRADES_COLLECTION}\`(application_id)"

run_capella_n1ql "CREATE INDEX IF NOT EXISTS idx_timeslots_appid ON \`${CB_BUCKET}\`.\`${CB_SCOPE}\`.\`${CB_AGENDA_COLLECTION}\`(META().id) WHERE META().id LIKE 'application::%' OR META().id LIKE 'pending_email::%'"

# ---------------------------------------------------------------------------
# 4. Create FTS vector index (candidates_index)
# ---------------------------------------------------------------------------
echo ""
echo "Creating FTS vector index (candidates_index)..."

if [ -f "/app/agentcatalog_index.json" ]; then
  INDEX_JSON="/app/agentcatalog_index.json"
else
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  INDEX_JSON="${SCRIPT_DIR}/../backend/agentcatalog_index.json"
fi

if [ ! -f "$INDEX_JSON" ]; then
  echo "   agentcatalog_index.json not found — skipping FTS index"
else
  # Patch the index JSON for Capella:
  #   sourceName  → bucket name
  #   sourceType  → "couchbase"
  sed "s/\"sourceName\" *: *\"[^\"]*\"/\"sourceName\": \"${CB_BUCKET}\"/g;
       s/\"sourceType\" *: *\"[^\"]*\"/\"sourceType\": \"couchbase\"/g" \
    "$INDEX_JSON" > /tmp/fts_index_patched.json

  # Use Capella's FTS API
  bucket_id=$(encode_bucket_id "$CB_BUCKET")
  HTTP_STATUS=$(capella_curl -s -o /tmp/fts_response.json -w "%{http_code}" \
    -X PUT "${CLUSTERS_BASE}/fts/indexes/${CB_INDEX}" \
    -H "Content-Type: application/json" \
    -d @/tmp/fts_index_patched.json)

  if [ "$HTTP_STATUS" = "200" ]; then
    echo "   FTS index created"
  else
    echo "   FTS index response ${HTTP_STATUS}:"
    cat /tmp/fts_response.json 2>/dev/null || true
    echo ""
    echo "   Create it manually in Capella Console: Indexes > Search > Create Index"
  fi
fi

# ---------------------------------------------------------------------------
# 5. Summary
# ---------------------------------------------------------------------------
echo ""
echo "Couchbase Capella initialisation complete"
echo ""
echo "   Project: ${CB_PROJECT_ID}"
echo "   Cluster: ${CB_CLUSTER_ID}"
echo "   ${CB_BUCKET} > ${CB_SCOPE} > ${CB_COLLECTION}, ${CB_AGENDA_COLLECTION}"
echo "   ${AGENT_CATALOG_BUCKET} > ${AGENT_CATALOG_LOGS_SCOPE} > ${AGENT_CATALOG_LOGS_COLLECTION}, ${AGENT_CATALOG_GRADES_COLLECTION}"
