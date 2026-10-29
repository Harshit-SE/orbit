# Safety and permissions

Phase 1 uses local mock data. Phase 2 adds an authenticated demo connection and one allowlisted file-creation action.

For an integrated release:

- Accept only `Create note: <text>` in Phase 2, validating it on both backend and agent. The agent writes Markdown only in `agent/demo_folder` (or a folder intentionally selected with `ORBIT_DEMO_FOLDER`). Do not offer arbitrary shell or script execution.
- Restrict file reads/writes to user-selected approved folders; resolve paths and reject traversal, links that escape the folder, and unsupported file types.
- Require a clear, task-specific approval before deletion, external message sending, or system-setting changes. Show the exact target and effect; declining must not execute the action.
- The Phase 2 demo uses separate mobile and agent bearer tokens on a trusted private LAN. HTTP does not encrypt these tokens; do not port-forward or expose the demo publicly. Tokens stay in environment variables and in mobile memory for the current session. Phase 3 must add secure pairing and transport encryption.
- Keep note previews private, access-controlled, and separate from source control. The generated preview contains only the created note, not unrelated desktop content.
- Log task steps and approval outcomes without recording secrets or unrelated screen contents.
