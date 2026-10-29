# Orbit

Orbit is a Flutter companion for a personal Windows agent. This repository contains the **Phase 2 end-to-end personal demo**: Flutter mobile app, authenticated backend, and an allowlisted Windows note agent.

## Repository

- `mobile/` — Flutter app with local mock data and an API-backed connection mode.
- `backend/` — authenticated FastAPI service and SQLite task history.
- `agent/` — Windows agent restricted to note creation in the approved demo folder.
- `docs/` — architecture, API direction, roadmap, and safety model.

## Run the mobile demo

Install Flutter with Android or iOS tooling, then run:

```sh
cd mobile
flutter pub get
flutter run
```

Without backend credentials, the app uses local mock data. To run end to end, start the backend and agent using their READMEs, then enter the backend URL and mobile token in Settings. Submit `Create note: text` from Agent. Review the safety notes before binding the backend to a LAN address.

## Phase status

Phase 2 supports only note creation in a dedicated demo folder. Other requests fail with an unsupported-task message. Evidence is a generated note preview, not a capture of unrelated desktop content. Secure pairing and transport encryption remain Phase 3 work. See [`docs/roadmap.md`](docs/roadmap.md) and [`docs/safety-and-permissions.md`](docs/safety-and-permissions.md).
