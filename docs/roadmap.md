# Roadmap

## Phase 1 — Clickable mobile UI (current)

- Four dark-mode, mobile-first screens with local mock conversations, task states, timeline, evidence previews, and permission settings.
- Demo interactions for task submission, filters, approval/decline, Stop, reconnect/disconnect confirmation, and loading/error/empty views.
- Check: run Flutter static analysis and build when Flutter tooling is available.

## Phase 2 — End-to-end demo

- Add the small authenticated backend and Windows agent.
- Implement one predictable task in an explicitly scoped demo folder, live task events, persistent history, cooperative Stop, and real evidence capture.
- Replace mock repositories behind the UI with API-backed data access.

## Phase 3 — Reliable personal agent

- Document and enforce action/folder allowlists, request validation, timeouts, retries for recoverable errors, and actionable failures.
- Add private device pairing/reconnection and explicit approval for consequential operations.
- Let the user inspect captured evidence and task event history.

## Phase 4 — Broader capabilities

- Add task types incrementally with visible plans and only supported steps.
- Add durable configurable permissions and private evidence storage.
- Consider further OS controls only after the earlier permission model is reliable. Unrestricted control is outside the initial release.
