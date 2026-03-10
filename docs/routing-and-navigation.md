# Routing and Navigation

## Route Definition Layers

Routing is split into two layers:

1. Route constants in `lib/consts/router_path.dart`
2. Route registration map in `lib/main.dart` (`routes = { ... }`)

Both layers must remain synchronized.

## Route Constants

`RouterPath` defines string constants for named routes.

Examples:

- Core: `INDEX`, `LOGIN`, `SETTING`
- User: `USER`, `USER_CONTACT_LIST`, `USER_RELAYS`
- Content: `THREAD_DETAIL`, `THREAD_TRACE`, `EVENT_DETAIL`, `TAG_DETAIL`
- Group: `GROUP_LIST`, `GROUP_CHAT`, `GROUP_NOTE_LIST`, `GROUP_MEMBERS`
- Wallet: `WALLET`, `WALLET_SEND`, `WALLET_TRANSACTIONS`

`RouterPath.getThreadDetailPath()` chooses route dynamically based on `settingProvider.threadMode`.

## Route Registration

In `lib/main.dart`, `routes` is constructed in `_MyApp.build(...)` and passed into `MaterialApp.routes`.

Practical implication:

- A constant in `RouterPath` does not become navigable until it is added to `routes` map.
- Removing or renaming a route target widget requires synchronized updates in both places.

## Navigation Utilities

`lib/util/router_util.dart` wraps navigation with table-mode awareness.

### Key APIs

- `RouterUtil.router(context, pageName, arguments)`
- `RouterUtil.push(context, route)`
- `RouterUtil.routerArgs(context)`
- `RouterUtil.back(context, returnObj)`

### Behavior Notes

- In normal mode, it delegates to `Navigator`.
- In table mode, it uses `pcRouterFakeProvider` and `PcRouterFake` stack behavior.
- This allows desktop/table layouts to simulate nested routing without full navigator stack usage.

## Route Change Checklist

When adding a new route:

1. Add a constant in `RouterPath`.
2. Add widget mapping in `routes` map in `main.dart`.
3. Ensure navigation calls use `RouterPath` constant (not hardcoded strings).
4. If arguments are needed, validate retrieval via `RouterUtil.routerArgs(...)`.

When removing/renaming a route:

1. Update constant and route map.
2. Find all usages and update navigation calls.
3. Verify both normal mode and table mode navigation behavior.

## Maintenance Checklist

- Keep `router_path.dart` and `MaterialApp.routes` synchronized.
- If table-mode routing logic changes, update Navigation Utilities section.
- If route argument conventions change, update Route Change Checklist.
