# Architecture

## Phase 1

The Flutter app owns presentation and an in-memory mock fallback. It can connect to the Phase 2 API without changing the four screens.

## Intended end-to-end shape

```text
Flutter phone ── authenticated private connection ── backend ── persistent agent connection ── Windows agent
                                                      │                                    │
                                                      └── task/event metadata               └── allowlisted actions
```

The phone submits and observes tasks over a bearer-authenticated API. The backend validates requests, stores task history and events in SQLite, and relays tasks over an authenticated outbound agent WebSocket. The Windows agent accepts only `Create note: <text>` and writes Markdown inside one configured demo folder. It creates a scoped note-preview PNG; it does not capture the rest of the desktop. Evidence stays in private backend storage and is retrieved by authenticated id.

The Phase 2 bearer-token HTTP demo is intended only for a trusted private network and is not suitable for public exposure. Phase 3 must add secure pairing and transport security. Later phases can add retries and configurable permissions without granting arbitrary shell access.
