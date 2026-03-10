# Data Layer

## Storage Overview

Nostrmo uses multiple persistence layers with distinct responsibilities:

- SQLite: structured app data and queryable local records.
- Isar: high-performance local relay event storage.
- SharedPreferences: lightweight settings and keyed values.
- Flutter Secure Storage: secret account/NWC payload storage.
- In-memory caches: short-lived acceleration and deduplication.

## 1) SQLite (App DB)

### Bootstrap

- Initialization entry: `lib/data/db.dart`
- DB name: `nostrmo.db`
- Opened via `DB.getCurrentDatabase()` during startup.

### Created Tables

- `metadata`
- `event`
- `dm_session_info`

### Notes

- Linux fallback attempts to install sqlite libs when open fails.
- Query helpers are spread across `lib/data/*` (for example event and DM session helpers).

## 2) Isar (Local Relay DB)

### Bootstrap

- Initialization entry: `packages/relay_isar_db/lib/relay_isar_db.dart`
- App startup call: `RelayIsarDB.init(Base.APP_NAME)` in `main()`

### Role

- Implements `RelayDBExtral` used by relay-local mechanisms.
- Supports event add/query/delete operations using Isar schema.
- Includes batched pending write behavior (`LaterFunction`) and in-memory dedup map.

## 3) SharedPreferences

### Bootstrap

- `DataUtil.getInstance()` in `lib/provider/data_util.dart`

### Role

- General lightweight persistence for settings and small lists/flags.
- Keys are centralized in `DataKey` constants.
- Secret key material is no longer persisted here after migration.

## 4) Flutter Secure Storage

### Bootstrap

- Utility entry: `lib/provider/secure_storage_util.dart`
- Secret maps are loaded/migrated in `SettingProvider._initSecretStorage()`.

### Role

- Stores account key map (raw account key strings) outside normal settings data.
- Stores NWC URL map (contains wallet-connect `secret` payloads).
- Uses write-then-read verification before considering a secure write successful.

### Backward Compatibility Migration

- On startup, if secure data is absent, app reads legacy values from `SettingData.encryptPrivateKeyMap` / `privateKeyMap` and `SettingData.nwcUrlMap`.
- Legacy values are written to secure storage first and verified.
- Only after successful verification, legacy secret fields in settings are cleared.
- If secure storage write fails, app keeps legacy data path to avoid key loss.

## 5) In-Memory Caches

Examples include:

- Metadata/cache maps inside providers (for quick runtime lookups).
- Event dedup memory map in relay Isar implementation.
- Media and text matcher runtime caches initialized during startup.

## Data Flow Summary

1. Startup initializes SQLite + SharedPreferences + Isar relay DB.
2. `SettingProvider` loads secrets from secure storage or auto-migrates legacy setting secrets.
3. Providers read settings/state and compose runtime behavior.
4. Relay and event operations may use both remote relays and local persistence.
5. In-memory caches reduce repeated decoding and DB operations.

## Change Guidelines

- Schema change requires synchronized code updates in DB bootstrap and query helpers.
- SharedPreferences key changes require migration/backward handling.
- Secret data changes must preserve secure-storage compatibility and migration idempotency.
- Isar model changes require schema/codegen alignment and migration strategy.
- Avoid mixing storage responsibilities across layers without a clear reason.

## Maintenance Checklist

- If SQLite schema/table/index changes, update this document immediately.
- If Isar local relay storage behavior changes, update Isar section.
- If `DataKey` entries change, update SharedPreferences section.
- If secure secret key names or migration marker changes, update Flutter Secure Storage section.
- If new major in-memory cache is introduced, add it to cache boundaries.
