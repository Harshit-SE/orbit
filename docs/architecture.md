# Architecture

## Phase 1

The Flutter app owns presentation and an in-memory mock fallback. It can connect to the Phase 2 API without changing the four screens.

## Intended end-to-end shape

```text
Flutter phone ── authenticated private connection ── backend ── persistent agent connection ── Windows agent
                                                      │                                    │
                                                      └── task/event metadata               └── allowlisted actions
```

The phone submits and observes tasks over a bearer-authenticated API. The backend validates requests, stores task history and events in SQLite, and relays tasks over an authenticated outbound agent WebSocket. The Windows agent can search public web results and accepts `Create note: <text>`, `List notes`, and `Find note: <text>`; file reads and writes stay inside one configured demo folder. Research returns provider snippets and HTTPS links that the user opens from the phone. Note creation returns a scoped preview PNG; it does not capture the rest of the desktop. Evidence stays in private backend storage and is retrieved by authenticated id.

The bearer-token HTTP demo is intended only for a trusted private network and is not suitable for public exposure. Secure phone pairing and transport security are still required before production use. Later phases can add retries and configurable permissions without granting arbitrary shell access.
