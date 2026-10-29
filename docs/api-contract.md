# API contract (planned)

No API is implemented in Phase 1. This document records the Phase 2 interface direction; payloads may evolve during implementation.

## HTTP

- `GET /health` — service health and paired-agent presence; no secrets in response.
- `POST /v1/tasks` — submit `{ "request": "..." }`; return task id, `queued` status, creation time.
- `GET /v1/tasks` — authenticated task history, newest first.
- `GET /v1/tasks/{task_id}` — current status, named step, progress, timestamps, and evidence metadata.
- `POST /v1/tasks/{task_id}/stop` — request cooperative cancellation.
- `POST /v1/tasks/{task_id}/approvals/{approval_id}` — explicitly approve or decline a consequential step.
- `GET /v1/evidence/{evidence_id}` — authenticated evidence retrieval after authorization checks.

## Live events

An authenticated WebSocket at `/v1/events` emits versioned JSON events: `task.queued`, `task.started`, `task.progress`, `task.awaiting_approval`, `task.completed`, `task.failed`, `task.stopped`, and `agent.presence`. Events include `event_id`, `task_id` where applicable, `occurred_at`, and a typed payload. Clients reconnect and fetch task state to recover missed events.

Statuses: `queued`, `running`, `waiting_approval`, `completed`, `failed`, `stopped`. Evidence metadata describes kind, capture time, duration, and authenticated retrieval id; it must not reveal local absolute paths.

All endpoints require paired-device authentication. Never expose an unauthenticated public control endpoint. Validate task requests and enforce agent-side action and folder allowlists independently of client validation.
