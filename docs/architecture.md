# Architecture

## Phase 1

The Flutter app owns presentation and an in-memory mock task list. `mobile/lib/main.dart` contains the current prototype screens and mock interactions so the app runs without a service or secrets. Evidence cards are illustrative previews, not captured media.

## Intended end-to-end shape

```text
Flutter phone ── authenticated private connection ── backend ── persistent agent connection ── Windows agent
                                                      │                                    │
                                                      └── task/event metadata               └── allowlisted actions
```

The phone submits and observes tasks. The backend authenticates paired devices, validates requests, stores task metadata, and relays progress and approvals. The Windows agent accepts only backend-issued, validated task steps and executes its local allowlist. Evidence is stored privately and exposed as metadata plus authenticated retrieval, never as public paths.

Phase 2 should keep API-backed repositories behind the current UI and use predictable demo tasks. Later phases can add durable history, retries, pairing, and configurable permissions without granting arbitrary shell access.
