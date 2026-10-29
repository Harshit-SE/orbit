# Orbit Mobile

Flutter client for the Orbit Phase 2 personal-agent demo.

## Run locally

```sh
flutter pub get
flutter run
```

The app starts in demo mode. Open **Settings**, switch to **API connection**, enter the backend base URL and the mobile bearer token, then connect. The app stores the token in memory for the current run. For a phone on the same trusted Wi-Fi as the development PC, use the PC's private LAN IP and run the backend on `0.0.0.0`; allow the backend port only on the private network in Windows Firewall.

## Demo behavior

- Activity refreshes task status from the backend and shows progress, task events, and available note-preview evidence.
- `Research: <question>` returns up to three public search results and source links; tapping a source opens it in the phone browser.
- Note actions are `Create note: <text>`, `List notes`, and `Find note: <text>`. All file access stays under `agent/demo_folder`.
- Other requests fail visibly. Stop prevents a queued note from being written.
- Evidence is a generated note preview, not a desktop screenshot.

The demo uses HTTP bearer authentication for a trusted LAN only. Do not expose its port to the internet or use real credentials. Secure pairing and transport remain future work.

## Checks

Run `flutter analyze` and `flutter test test` from this directory. The API client tests can also be run directly with `flutter test test/orbit_api_test.dart`.
