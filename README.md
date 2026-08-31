# Movie Tracker

Movie Tracker is a Flutter app for discovering movies and TV series and tracking what you want to watch, what you have watched, and your viewing history across profiles.

## Current capabilities

- Browse and search movies and TV series using TMDB data.
- View movie, series, season, and episode details.
- Track favorites, watchlist/watched state, TV progress, seasons, and episodes.
- Maintain profiles, diary/history, and viewing statistics.
- Save changes locally first and queue cloud synchronization for reliable offline-first use.
- Sign in and synchronize supported data through Firebase while keeping tracking data private by default.
- Run as Flutter web/desktop/mobile codebase with responsive layouts.

## Architecture

The app keeps routine tracking operations local-first and uses queued synchronization so normal use does not depend on a continuous network connection. Firebase provides account/cloud functionality, while TMDB requests are routed through a dedicated client abstraction.

For public web production, TMDB credentials are never intended to be embedded in the Flutter JavaScript bundle. The production design uses a Cloudflare Worker proxy with the TMDB credential stored only as a Worker secret.

## Development

This project requires Flutter. Local TMDB development configuration is intentionally untracked. Start from:

```text
lib/config/api_config.example.dart
```

Do not commit TMDB credentials, Firebase secrets, Cloudflare tokens, or other private credentials.

Common checks:

```bash
flutter pub get
flutter analyze
flutter test
flutter build web
```

GitHub Actions also runs Flutter CI on pushes, pull requests, and scheduled health builds.

## Production

Production remains zero-spend by default and is gated so deployment cannot start until the required one-time external settings are configured.

See:

- [`docs/PRODUCTION_SETUP.md`](docs/PRODUCTION_SETUP.md) — first-launch and production setup.
- [`docs/FIREBASE_SETUP.md`](docs/FIREBASE_SETUP.md) — Firebase configuration.
- [`docs/AUTOPILOT_POLICY.md`](docs/AUTOPILOT_POLICY.md) — autonomous maintenance safety and approval rules.
- [`docs/AUTOPILOT_ROADMAP.md`](docs/AUTOPILOT_ROADMAP.md) — development roadmap and operating priorities.

After the approved first launch is configured, CI-green `main` builds can deploy through the gated production workflow and the production health workflow can monitor the public site and attempt safe recovery.

## Privacy and cost principles

- User tracking data and profiles are private by default.
- Public sharing must be explicitly enabled by the user.
- No billing or paid infrastructure is enabled automatically.
- Credentials must never be committed to the repository or exposed in public web builds.
- Destructive user/cloud-data operations require explicit owner approval.
