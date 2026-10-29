# Orbit Windows agent

Phase 2 agent. It connects outbound to the authenticated Orbit backend, accepts only `Create note: <text>`, writes Markdown only in its configured demo folder, and returns a generated note-preview image. It does not run shell commands, control the desktop, browse websites, delete files, or send messages.

## Run on Windows

```powershell
cd agent
py -m venv .venv
.venv\Scripts\Activate.ps1
pip install -e .
$env:ORBIT_API_URL = 'ws://127.0.0.1:8765'
$env:ORBIT_AGENT_TOKEN = 'the-agent-token-configured-on-the-backend'
python -m orbit_agent
```

The backend must be running first. For a phone on the same Wi-Fi, both the agent and phone need the PC's LAN address (for example `http://192.168.1.20:8765` in the app settings). Keep the firewall rule private to your network; never forward this port publicly.

The only write target is `agent/demo_folder/`. Set `ORBIT_DEMO_FOLDER` only to a dedicated folder that you intentionally approve.
