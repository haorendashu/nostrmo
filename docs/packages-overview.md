# Packages Overview

## Purpose

This document explains the role of each local package under `packages/` and how the main app integrates with them.

## 1) nostr_sdk

### Responsibility

- Core Nostr protocol entities and behavior.
- Relay pool and subscription/query orchestration.
- Event signing and publication abstractions.
- NIP-specific modules and utilities.

### Key Entrypoints

- `packages/nostr_sdk/lib/nostr.dart`
- `packages/nostr_sdk/lib/event.dart`
- `packages/nostr_sdk/lib/filter.dart`
- `packages/nostr_sdk/lib/relay/*`

### App Integration

- Main app constructs `Nostr` indirectly through `RelayProvider.genNostrWithKey(...)`.
- Providers call `nostr.query(...)`, `nostr.subscribe(...)`, `nostr.sendEvent(...)`, etc.
- Relay type strategy (normal/cache/temp/index/local) is controlled by app providers and passed to SDK APIs.

## 2) relay_isar_db

### Responsibility

- Implements `RelayDBExtral` on top of Isar.
- Persists relay events for local relay queries and cache-like replay behavior.
- Handles batched writes and filter-based query translation.

### Key Entrypoints

- `packages/relay_isar_db/lib/relay_isar_db.dart`
- `packages/relay_isar_db/lib/isar_event.dart`

### App Integration

- Initialized in `main()` via `RelayIsarDB.init(Base.APP_NAME)`.
- Injected to relay-local flow through global `localRelayDB`.
- Used when local relay is enabled from settings.

## 3) nesigner_adapter

### Responsibility

- Adapter layer for Nesigner integration.
- Exposes signer-facing API contracts and utilities.

### Key Entrypoints

- `packages/nesigner_adapter/lib/nesigner_adapter.dart`
- `packages/nesigner_adapter/lib/nesigner.dart`
- `packages/nesigner_adapter/lib/nesigner_util.dart`

### App Integration

- `RelayProvider.genNostrWithKey(...)` supports Nesigner key format.
- Adapter is used to bootstrap signer-based auth flows.

## 4) flutter_nesigner_sdk

### Responsibility

- Low-level SDK exports for serial/USB transport and signer utilities.
- Platform interface bridge for Flutter plugin integration.

### Key Entrypoints

- `packages/flutter_nesigner_sdk/lib/flutter_nesigner_sdk.dart`
- `packages/flutter_nesigner_sdk/lib/src/*`

### App Integration

- Consumed transitively through signer-related workflows.
- Primarily infrastructure-level support, not directly routed from most UI paths.

## Package Boundary Rules

- Keep protocol logic in `nostr_sdk`; avoid duplicating protocol behavior in app providers.
- Keep storage-engine-specific logic in `relay_isar_db`; app side should call abstractions.
- Keep signer transport details in signer packages; app side should operate on signer abstractions.

## Maintenance Checklist

- If package public API usage changes in app code, update the corresponding integration section.
- If package responsibility shifts, update Package Boundary Rules.
- If key entry files move/rename, update Entrypoints immediately.
