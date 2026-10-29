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

## Phase 3 — Phone-operated basic agent (in progress)

- Current working task set: research public webpages, create a note, list notes, and find text in notes through the phone app; note access stays in the approved Orbit folder.
- Harden task validation, safe-folder path checks, timeouts, reconnect behavior, retry rules, duplicate handling, and clear failures.
- Add private phone pairing and encrypted transport before calling the connection production-ready.
- Make task outcomes and generated evidence easy to inspect from Activity.

## Phase 4 — Broader capabilities (after reliability)

- Add a small number of useful personal workflows, each with visible steps and a specific allowlist.
- Add durable configurable permissions and private evidence storage.
- Add OS controls only after the permission model is reliable. Unrestricted control is outside the initial release.

## One-month presentation target

Target a dependable personal beta for public web research and the agreed note workflows, not unrestricted control of the PC. A reasonable sequence is: Week 1, stabilize and rehearse phone-to-PC web and note workflows; Week 2, secure pairing and connection recovery; Week 3, add one carefully chosen workflow with explicit approval; Week 4, regression checks, setup guide, demo rehearsal, and fallback recording. The timeline depends on available work hours and hardware/network issues; do not describe planned work as already complete.
