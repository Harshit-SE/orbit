# Orbit

Orbit is a Flutter companion for a personal Windows agent. The current build connects a Flutter phone app to an authenticated backend and a Windows agent with public web research plus three allowlisted note tasks.

## Repository

- `mobile/` — Flutter app with local mock data and an API-backed connection mode.
- `backend/` — authenticated FastAPI service and SQLite task history.
- `agent/` — Windows agent with web search and note actions restricted to the approved demo folder.
- `docs/` — architecture, API direction, roadmap, and safety model.

## Run the mobile demo

Install Flutter with Android or iOS tooling, then run:

```sh
cd mobile
flutter pub get
flutter run
```

Without backend credentials, the app uses local mock data. To run end to end, install agent dependencies, start the backend and agent using their READMEs, then enter the backend URL and mobile token in Settings. Try `Research: <question>` from Agent to get source links, or create/list/find notes. Web search needs the PC to have internet access. Review the safety notes before binding the backend to a LAN address.

## Phase status

From the phone, Orbit can search the public web and return three relevant search summaries with source links, as well as create, list, and find notes in its dedicated demo folder. Tapping a result opens that source on the phone. Search summaries come from search providers; Orbit does not yet write a synthesized answer. Other requests fail visibly. Evidence for note creation is a generated note preview, not a desktop screenshot. The demo is not a general-purpose PC controller; secure phone pairing and encrypted transport are next milestones. See [`docs/roadmap.md`](docs/roadmap.md) and [`docs/safety-and-permissions.md`](docs/safety-and-permissions.md).
