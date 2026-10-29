# API contract

Phase 2 implements the endpoints below. `/v1` HTTP requests require the mobile bearer token. The agent WebSocket requires a separate agent bearer token. `/health` exposes only service and agent presence.

## HTTP

- `GET /health` — service health and paired-agent presence; no secrets in response.
- `POST /v1/tasks` — submit `{ "request": "..." }`; return task id, `queued` status, creation time.
- `GET /v1/tasks` — authenticated task history, newest first.
- `GET /v1/tasks/{task_id}` — current status, named step, progress, timestamps, and evidence metadata.
- `POST /v1/tasks/{task_id}/stop` — request cooperative cancellation.
- `GET /v1/evidence/{evidence_id}` — authenticated evidence retrieval after authorization checks.

## Live events

The agent connects outbound to `/v1/agent` with its dedicated bearer token and sends progress/completion messages. `/v1/events` emits `task.updated` objects to authenticated clients. The mobile demo currently polls task state each second and retrieves evidence by id.

Statuses: `queued`, `running`, `waiting_approval`, `completed`, `failed`, `stopped`. The only Phase 2 supported request is `Create note: <text>`; unsupported requests are stored with a visible `failed` status. Evidence metadata describes kind, MIME type, capture time, and authenticated retrieval id; it never reveals local absolute paths.

All endpoints require paired-device authentication. Never expose an unauthenticated public control endpoint. Validate task requests and enforce agent-side action and folder allowlists independently of client validation.
