docker build . -t local-hr-agent
docker build . -t local-hr-agent --build-arg VITE_API_BASE_URL=https://...

create a single .env (see .env.render.example and .env.example in backend and frontend respectively)
in .env, you can use Capella AI model services, but if it fails or you don't want to use it, it will default to open AI (also specified in .env)

get root certificate from capella
CBCERT = ...

ngrok free account

agentmail free account

install agentc (installed in docker)

create buckets and scopes
    agentc bucket, 
    hrdemo, agentc_data scope, candidates,timeslotes,applications collections

(don't have to do this, it's done automatically) install index in couchbase: backend/agentcatalog_index.json

SKIP_INDEX_CREATION=true # if you want to install the hybrid vector index manually

docker run --name myHrAgent --env-file .env -p 8000:8000 local-hr-agent
