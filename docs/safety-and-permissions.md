# Safety and permissions

Phase 1 uses local mock data. The current demo adds an authenticated connection, public web search handoff, and three allowlisted note actions.

For an integrated release:

- Validate `Research: <question>`, `Create note: <text>`, `List notes`, and `Find note: <text>` on both backend and agent. The agent reads or writes only Orbit-generated Markdown notes in `agent/demo_folder` (or a folder intentionally selected with `ORBIT_DEMO_FOLDER`). Resolve paths and reject traversal or links escaping the approved folder. Do not offer arbitrary shell or script execution.
- Restrict file reads/writes to user-selected approved folders; resolve paths and reject traversal, links that escape the folder, and unsupported file types.
- Require a clear, task-specific approval before deletion, external message sending, or system-setting changes. Show the exact target and effect; declining must not execute the action.
- The demo uses separate mobile and agent bearer tokens on a trusted private LAN. HTTP does not encrypt these tokens; do not port-forward or expose the demo publicly. Tokens stay in environment variables and in mobile memory for the current session. Add secure pairing and transport encryption before production use.
- Keep note previews private, access-controlled, and separate from source control. The generated preview contains only the created note, not unrelated desktop content.
- Treat search results and webpage content as untrusted data. Return only HTTPS links, show the source host, and open a page only after the user taps its result in the phone app. Web pages do not trigger agent actions.
- Log task steps and approval outcomes without recording secrets or unrelated screen contents.
