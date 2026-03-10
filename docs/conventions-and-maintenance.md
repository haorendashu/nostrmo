# Conventions and Maintenance

## Purpose

This document captures practical conventions used in the repository and defines doc maintenance expectations.

## Engineering Conventions

## 1) Global Provider Pattern

- Providers are declared as top-level globals in `lib/main.dart`.
- Instances are initialized during startup and injected via `MultiProvider`.
- Any provider state mutation should call `notifyListeners()`.

## 2) Navigation Discipline

- Use route constants from `RouterPath`.
- Avoid hardcoded route strings in feature code.
- Keep `RouterPath` constants and `MaterialApp.routes` mapping synchronized.

## 3) Platform Detection

- Prefer `PlatformUtil` from `nostr_sdk` for platform branching in shared app logic.

## 4) Relay/Event Workflows

- Query specific relay types where possible to avoid redundant traffic.
- Unsubscribe when subscription lifecycle ends.
- Use batching/debounce patterns (`LaterFunction`) where event streams are high volume.

## 5) Data and Cache Discipline

- Keep SQLite, Isar, SharedPreferences responsibilities separated.
- Treat in-memory caches as acceleration layers, not source of truth.

## 6) Error and Notice Patterns

- Surface user-facing issues with existing notice/toast mechanisms.
- Keep logs actionable and scoped to relevant runtime contexts.

## Documentation Maintenance Policy

When code changes, docs should be updated in the same PR.

## Change-to-Doc Mapping

- Startup / globals / provider wiring change:
  - update `architecture-overview.md`
  - update `global-state-and-providers.md`
  - update `key-variables-and-runtime-context.md`
- Route constants / route map change:
  - update `routing-and-navigation.md`
- Storage or persistence change:
  - update `data-layer.md`
- Package boundary or integration change:
  - update `packages-overview.md`
- Conventions/process change:
  - update this file

## PR Checklist (Docs)

Before merge, verify:

- [ ] Changed areas are reflected in the corresponding docs above.
- [ ] Route names in docs match current constants.
- [ ] Global variable names in docs match current code.
- [ ] Storage descriptions match current schema/keys/backends.
