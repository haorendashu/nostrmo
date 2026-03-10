# Nostrmo Engineering Docs

This folder is the source of truth for project-level engineering documentation.
It is designed for both:

- Onboarding developers (fast orientation)
- Core maintainers (runtime and dependency details)

## Document Map

- `architecture-overview.md`: runtime architecture, startup sequence, and folder responsibilities.
- `packages-overview.md`: purpose and boundaries of local packages in `packages/`.
- `global-state-and-providers.md`: global variables in `lib/main.dart`, provider initialization and dependency links.
- `routing-and-navigation.md`: route constants, route registration, and navigation behavior.
- `data-layer.md`: SQLite, Isar, SharedPreferences, and in-memory cache boundaries.
- `key-variables-and-runtime-context.md`: high-impact runtime variables, lifecycle, and failure impact.
- `conventions-and-maintenance.md`: coding and update conventions for contributors and maintainers.

## How To Use

1. Start with `architecture-overview.md`.
2. Read `global-state-and-providers.md` before changing provider code.
3. Read `data-layer.md` before changing persistence behavior.
4. Read `routing-and-navigation.md` before adding or modifying routes.

## Maintenance Rules

- If startup flow in `lib/main.dart` changes, update:
  - `architecture-overview.md`
  - `global-state-and-providers.md`
  - `key-variables-and-runtime-context.md`
- If route constants or `MaterialApp.routes` changes, update:
  - `routing-and-navigation.md`
- If any table/schema/storage path/persistence key changes, update:
  - `data-layer.md`
- If package boundaries or integration points change, update:
  - `packages-overview.md`
- If engineering conventions change, update:
  - `conventions-and-maintenance.md`
