# Architecture Overview

## Purpose

Nostrmo is a multi-platform Flutter Nostr client with an app-first architecture and local package extensions.
Core UI and runtime orchestration live in `lib/`, while protocol and storage engines are delegated to `packages/`.

## High-Level Structure

### Main App

- `lib/main.dart`: application bootstrap, environment setup, singleton/provider initialization, route registration.
- `lib/component/`: reusable UI units and content rendering.
- `lib/router/`: screen-level routers (each route target widget).
- `lib/provider/`: stateful domain providers and runtime service objects.
- `lib/data/`: SQLite table bootstrapping and DAO-style query helpers.
- `lib/consts/`: constants for route paths, theme/style, behavior flags.
- `lib/util/`: shared utility functions (navigation helpers, locale, cache helpers).

### Local Packages

- `packages/nostr_sdk`: protocol and relay engine.
- `packages/relay_isar_db`: Isar-backed local relay DB implementation.
- `packages/nesigner_adapter`: signer adapter interface and glue.
- `packages/flutter_nesigner_sdk`: signer transport/crypto SDK exports.

## Startup Sequence (from `main()`)

1. Platform/runtime setup
   - Flutter binding, media initialization, desktop window setup.
   - DB factory setup for web/desktop (`sqflite_ffi` branch).
2. Local services init (parallelized)
   - SQLite (`DB.getCurrentDatabase()`)
   - SharedPreferences (`DataUtil.getInstance()`)
   - Local relay DB (`RelayIsarDB.init(...)`)
3. Core singleton/provider init
   - `SettingProvider`, `MetadataProvider`, `RelayProvider`, `DMProvider`, `GroupProvider`, etc.
4. Optional network/auth initialization
   - SOCKS proxy if configured.
   - `nostr = relayProvider.genNostrWithKey(...)` when private key exists.
5. App launch
   - `runApp(MyApp())`
   - `MultiProvider` injects initialized providers.
   - `MaterialApp` gets named routes map.

## Runtime Composition

- Global singleton state is declared in `lib/main.dart` as `late` variables.
- Most providers are long-lived and injected through `ListenableProvider.value`.
- Protocol state (`nostr`) and relay-local storage (`localRelayDB`) are process-level resources.
- Lifecycle cleanup happens in `_MyApp.didChangeAppLifecycleState` on `detached`.

## Architecture Characteristics

- Centralized bootstrap: initialization order is explicit and mostly linear after async prerequisites.
- Provider-centric state flow: UI reads state via Provider listeners.
- Tight coupling via `main.dart` globals: many provider files import `main.dart` directly.
- Multi-backend persistence: SQLite + Isar + SharedPreferences + in-memory caches.

## Known Tradeoffs

- High convenience from global singletons, but reduced test isolation and stronger cross-module coupling.
- Route constants and route registration are separate sources that need manual synchronization.
- Local package boundaries are clear, but runtime integration is still coordinated centrally in `main.dart`.

## Maintenance Checklist

- If startup order changes in `main()`, update this document’s Startup Sequence.
- If folder/module responsibilities shift, update High-Level Structure.
- If lifecycle cleanup changes (`nostr.close`, timer stop), update Runtime Composition.
