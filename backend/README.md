# Orbit backend

Demo API. It accepts authenticated task requests, stores task history and event timelines in SQLite, relays allowlisted note actions to the Windows agent, and serves private note-preview evidence.

## Run on the PC

Create and activate a virtual environment, install this package, then set `ORBIT_MOBILE_TOKEN` and `ORBIT_AGENT_TOKEN` to separate random values of at least 24 characters. Copy `.env.example` only as a reference; do not use its sample tokens.

```powershell
cd backend
py -m venv .venv
.venv\Scripts\Activate.ps1
pip install -e .
$env:ORBIT_MOBILE_TOKEN = 'replace-with-a-random-mobile-token'
$env:ORBIT_AGENT_TOKEN = 'replace-with-a-different-random-agent-token'
$env:ORBIT_HOST = '0.0.0.0'
uvicorn app.main:app --host $env:ORBIT_HOST --port 8765
```

Bind to `0.0.0.0` only on a trusted private network. Do not port-forward this demo or expose it to the public internet. HTTP bearer tokens are suitable only for this trusted-network demo; Phase 3 must add paired-device transport security.

## Supported task

Supported requests are `Research: <question>`, `Create note: <note text>`, `List notes`, and `Find note: <text>`. Web search returns up to three result titles, provider snippets, and HTTPS links. The phone user opens a source explicitly. Note reads and writes stay inside the agent's approved `demo_folder`; all other requests return a visible failed task. See `../docs/safety-and-permissions.md`.
