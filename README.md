# Orbit

Orbit is a Flutter companion for a personal Windows agent. This repository currently contains the **Phase 1 mobile UI demo**. It uses local mock data and does not connect to or control a PC.

## Repository

- `mobile/` — Flutter app, currently implemented as a dependency-light clickable prototype.
- `backend/` and `agent/` — planned for Phase 2; not implemented yet.
- `docs/` — architecture, API direction, roadmap, and safety model.

## Run the mobile demo

Install Flutter with Android or iOS tooling, then run:

```sh
cd mobile
flutter pub get
flutter run
```

The app uses only local mock data. On Agent, submit a task with the composer or a quick suggestion. Use the bottom navigation to browse history, evidence previews, and settings. The Settings screen includes demo controls for loading/error states and PC connection.

## Phase status

Phase 1 is implemented in `mobile/lib/main.dart`. Backend connectivity, real screenshots/recordings, notifications, secure pairing, and PC actions are not implemented. See [`docs/roadmap.md`](docs/roadmap.md) before starting the next phase.
