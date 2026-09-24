# MCP secrets template — resolve with: just mcp-secrets
# References are safe for git; the resolved file is gitignored and never leaves this machine.
export HINDSIGHT_MCP_TOKEN='op://Hobby/Hindsight/API key'
export CONTEXT7_API_KEY='op://Personal/Context7/API key'
export EXA_API_KEY='op://Hobby/Exa/API key'
export BROWSER_USE_API_KEY='op://Hobby/Browser Use/API key'
export CONFLUENCE_API_TOKEN='op://Dats.Team/Confluence/API key'
export JIRA_API_TOKEN='op://Dats.Team/Jira/API key'
export GRAFANA_API_KEY='op://Dats.Team/Grafana/API token'
export ELASTICSEARCH_PASSWORD='op://Dats.Team/Kibana/password'
export TESTRAIL_API_KEY='op://Dats.Team/TestRail/API key'
# MinIO keys keep their own names so AWS tools never pick them up by default;
# mcp/servers.toml maps them to AWS_* for the minio server only.
export MINIO_ACCESS_KEY_ID='op://Dats.Team/MiniIO/accessKey'
export MINIO_SECRET_ACCESS_KEY='op://Dats.Team/MiniIO/secretKey'
export DATS_TEAM_AI_API_KEY='op://Dats.Team/Dats AI/API key'
