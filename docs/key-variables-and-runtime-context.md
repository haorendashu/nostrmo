# Key Variables and Runtime Context

## Purpose

This document lists high-impact runtime variables and explains how they influence behavior across the app.

## Global Runtime Variables

## 1) `nostr`

- Type: `Nostr?`
- Source: `relayProvider.genNostrWithKey(...)`
- Meaning: authenticated protocol runtime (signer + relay pool + query/send APIs).
- Lifecycle:
  - Initialized only when private key is configured.
  - Closed on app lifecycle `detached`.
- Impact of failure:
  - Most authenticated relay actions and event publishing are unavailable.

## 2) `localRelayDB`

- Type: `RelayDBExtral?`
- Source: `RelayIsarDB.init(...)`
- Meaning: local relay persistence backend.
- Lifecycle:
  - Initialized at startup.
  - Used only when relay-local feature is enabled.
- Impact of failure:
  - local relay caching/query behavior degrades or becomes disabled.

## 3) `sharedPreferences`

- Type: `SharedPreferences`
- Source: `DataUtil.getInstance()`
- Meaning: lightweight key-value storage used across settings and flags.
- Impact of failure:
  - startup/config persistence behavior breaks.

## 4) `routes`

- Type: `Map<String, WidgetBuilder>`
- Source: built in `_MyApp.build(...)`
- Meaning: named routes used by `MaterialApp`.
- Impact of failure:
  - navigation failures for missing or mismatched route mappings.

## 5) `indexGlobalKey`

- Type: `GlobalKey`
- Usage: passed to `IndexRouter` and used for key-based interactions.
- Impact of misuse:
  - widget identity/state access inconsistencies.

## Runtime Flags

## `dataSyncMode`

- Indicates data synchronization mode in runtime.

## `firstLogin`

- Startup/login behavior flag.

## `newUser`

- Indicates new-user state (for onboarding/follow suggestions).

These flags are global and mutable; unintended writes can alter cross-screen behavior.

## Provider Globals with Strong Influence

- `settingProvider`: controls theme, locale, relay mode, proxy and other runtime decisions.
- `relayProvider`: creates and manages relay-backed Nostr runtime.
- `metadataProvider`: central profile metadata read/cache path.
- `syncService`: controls background sync behavior.

## Lifecycle Notes

- Startup initializes globals before `runApp`.
- `MyApp` registers app lifecycle observer in `initState`.
- On `detached`:
  - `SystemTimer.stopTask()`
  - `nostr?.close()`

## Safe Modification Rules

- Do not change global variable initialization order without dependency audit.
- Do not rename critical globals without full workspace usage search.
- Prefer explicit null handling around nullable runtime objects (`nostr`, `localRelayDB`).

## Maintenance Checklist

- If global runtime variable list changes in `main.dart`, update this document.
- If lifecycle cleanup behavior changes, update Lifecycle Notes.
- If meaning/usage of runtime flags changes, update Runtime Flags.
