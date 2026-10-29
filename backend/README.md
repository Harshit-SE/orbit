# Orbit backend

Phase 2 demo API. It accepts authenticated task requests, stores task history and event timelines in SQLite, relays one supported action to the paired Windows agent, and serves private note-preview evidence.

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

The only supported request is `Create note: <note text>`. It creates a Markdown file in the agent's `demo_folder`; all other requests return a visible failed task. See `../docs/safety-and-permissions.md`.
