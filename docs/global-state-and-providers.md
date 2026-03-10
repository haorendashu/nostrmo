# Global State and Providers

## Why This Matters

Nostrmo uses app-wide globals declared in `lib/main.dart` and injects providers via `MultiProvider`.
This is efficient for runtime sharing, but initialization order and dependency direction are critical.

## Global State Pattern

- Core globals are declared as `late` top-level variables in `lib/main.dart`.
- Most are initialized inside `main()` before `runApp(...)`.
- Many providers and utilities import `main.dart` directly to access global instances.

## Critical Global Variables (Selected)

### Runtime Infrastructure

- `sharedPreferences`
- `localRelayDB`
- `nostr`
- `routes`
- `indexGlobalKey`

### Provider Singletons / Long-Lived Objects

- `settingProvider`
- `metadataProvider`
- `relayProvider`
- `dmProvider`
- `groupProvider`
- `groupDetailsProvider`
- `feedProvider`
- `syncService`

### Others with Cross-Cutting Effect

- `defaultTrieTextMatcher`
- `musicInfoCache`
- `localNotificationBuilder`
- `dataSyncMode`, `firstLogin`, `newUser`

## Initialization Order (Simplified)

1. Persistence resources initialize first: SQLite, SharedPreferences, Isar local relay DB.
2. Core providers initialize next: setting/metadata first, then domain providers.
   - `settingProvider` performs secret-storage bootstrap here:
     - load account/NWC secrets from secure storage when available,
     - or migrate legacy setting secrets to secure storage automatically.
3. Runtime utilities initialize: cache manager, text matcher, webview provider, etc.
4. Optional login bootstrap: create `nostr` from configured key.
5. `MultiProvider` injects provider instances to the widget tree.

## Provider Injection

- Injection uses `ListenableProvider.value(value: existingSingleton)`.
- This means providers are created outside widget build and treated as process-level state.

## Dependency Direction

- UI components depend on providers.
- Providers frequently depend on:
  - other providers
  - global runtime objects (`nostr`, `sharedPreferences`, `localRelayDB`)
  - settings from `settingProvider`
- Several provider files import `main.dart`, creating direct global coupling.

## Risk Areas During Refactor

- Reordering initialization can cause runtime null/late-init errors.
- Changing one provider constructor can impact startup sequence.
- Replacing globals with dependency injection requires broad edits across providers.
- Moving `settingProvider` initialization later can break secret migration before first key read.

## Safe Change Strategy

1. Trace all references of the target provider/global.
2. Confirm initialization point in `main()` stays valid.
  - For secret changes, keep migration before first `settingProvider.privateKey` consumption.
3. Verify `MultiProvider` still includes the provider.
4. Verify lifecycle behavior where `nostr` is opened/closed.

## Maintenance Checklist

- If global variables in `lib/main.dart` are added/removed/renamed, update this document.
- If provider initialization order changes, update Initialization Order.
- If provider injection list changes, update Provider Injection section.
- If coupling to `main.dart` is reduced/increased, update Dependency Direction.
