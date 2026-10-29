# Safety and permissions

The Phase 1 app is a visual prototype: its task data and state changes are local and do not invoke computer actions.

For an integrated release:

- Accept only documented task types and agent-side allowlisted actions. Do not offer arbitrary shell or script execution.
- Restrict file reads/writes to user-selected approved folders; resolve paths and reject traversal, links that escape the folder, and unsupported file types.
- Require a clear, task-specific approval before deletion, external message sending, or system-setting changes. Show the exact target and effect; declining must not execute the action.
- Use paired-device authentication over a private connection. Do not expose unauthenticated control services publicly or store credentials in source.
- Keep evidence private, access-controlled, and separate from source control. Show users what is captured and how to disconnect or revoke access.
- Log task steps and approval outcomes without recording secrets or unrelated screen contents.
