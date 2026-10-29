# Roadmap

## Phase 1 — Clickable mobile UI (complete)

- Four dark-mode, mobile-first screens with local mock conversations, task states, timeline, evidence previews, and permission settings.
- Demo interactions for task submission, filters, approval/decline, Stop, reconnect/disconnect confirmation, and loading/error/empty views.
- Check: run Flutter static analysis and build when Flutter tooling is available.

## Phase 2 — End-to-end demo (complete)

- Authenticated backend with SQLite history, task timeline/progress, Stop, and private evidence retrieval.
- Outbound authenticated Windows-agent connection with one allowlisted Create note action in `agent/demo_folder`.
- Mobile URL/token settings, agent presence, one-second task refresh, unsupported-task errors, generated note-preview evidence, and Stop.
- Check: Flutter analysis and widget tests passed; Python store and agent tests passed; authenticated local backend-agent smoke run passed, including unsupported requests, progress, evidence retrieval, and Stop.
- Limitation: note evidence is a generated file preview, not a desktop screenshot. This bearer-token HTTP demo is trusted-LAN-only; Phase 3 must secure pairing and transport.

## Phase 3 — Reliable personal agent (next)

- Document and enforce action/folder allowlists, request validation, timeouts, retries for recoverable errors, and actionable failures.
- Add private device pairing/reconnection and explicit approval for consequential operations.
- Let the user inspect captured evidence and task event history.

## Phase 4 — Broader capabilities

- Add task types incrementally with visible plans and only supported steps.
- Add durable configurable permissions and private evidence storage.
- Consider further OS controls only after the earlier permission model is reliable. Unrestricted control is outside the initial release.
