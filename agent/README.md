# Orbit Windows agent

It connects outbound to the authenticated Orbit backend and accepts four bounded actions: `Research: <question>`, `Create note: <text>`, `List notes`, and `Find note: <text>`. Research returns up to three public web-result summaries with HTTPS links; the phone user chooses whether to open them. Note reads and writes stay in the configured demo folder, and creating a note returns a generated note preview. The agent does not run shell commands, control the desktop, delete files, or send messages.

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
