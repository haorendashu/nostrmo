# Nostrmo - Flutter Nostr Client Development Guide

## Architecture Overview

Nostrmo is a multi-platform Flutter Nostr client with a modular architecture:

- **Main App**: Flutter UI in `lib/` using Provider pattern for state management
- **Custom Packages** (`packages/`):
  - `nostr_sdk`: Core Nostr protocol implementation (NIPs, event handling, relay management)
  - `relay_isar_db`: Isar database adapter for relay data persistence
  - `flutter_nesigner_sdk` & `nesigner_adapter`: Hardware signer integration
- **Multi-Platform Support**: iOS, Android, Web, Windows, MacOS, Linux with platform-specific builds

## Documentation-First Lookup (For AI)

Before searching the whole workspace, check `docs/README.md` and use the docs map below.

- Need startup flow or module boundaries?
  - Read [docs/architecture-overview.md](docs/architecture-overview.md)
- Need package responsibilities and integration boundaries?
  - Read [docs/packages-overview.md](docs/packages-overview.md)
- Need global variables, provider wiring, or init order?
  - Read [docs/global-state-and-providers.md](docs/global-state-and-providers.md)
- Need route constants, route registration, or navigation behavior?
  - Read [docs/routing-and-navigation.md](docs/routing-and-navigation.md)
- Need SQLite/Isar/SharedPreferences/storage behavior?
  - Read [docs/data-layer.md](docs/data-layer.md)
- Need critical runtime variables and lifecycle impact?
  - Read [docs/key-variables-and-runtime-context.md](docs/key-variables-and-runtime-context.md)
- Need coding conventions and doc update policy?
  - Read [docs/conventions-and-maintenance.md](docs/conventions-and-maintenance.md)

Chinese intent aliases (for better lookup):

- 想看启动流程 / 模块边界 / 总体架构
  - Read [docs/architecture-overview.md](docs/architecture-overview.md)
- 想看 packages 职责 / 包之间边界 / 集成关系
  - Read [docs/packages-overview.md](docs/packages-overview.md)
- 想看全局变量 / Provider 初始化顺序 / 依赖关系
  - Read [docs/global-state-and-providers.md](docs/global-state-and-providers.md)
- 想看路由常量 / 路由注册 / 页面跳转
  - Read [docs/routing-and-navigation.md](docs/routing-and-navigation.md)
- 想看 SQLite / Isar / SharedPreferences / 存储设计
  - Read [docs/data-layer.md](docs/data-layer.md)
- 想看关键运行时变量 / 生命周期影响
  - Read [docs/key-variables-and-runtime-context.md](docs/key-variables-and-runtime-context.md)
- 想看开发约定 / 文档维护规范
  - Read [docs/conventions-and-maintenance.md](docs/conventions-and-maintenance.md)

When docs and code differ, trust code as source of truth and update docs in the same change.

## State Management Pattern

### Global Provider Architecture
All providers are declared as `late` global variables in [main.dart](main.dart) and initialized during app startup, then injected via `MultiProvider`:

```dart
late SettingProvider settingProvider;
late MetadataProvider metadataProvider;
late RelayProvider relayProvider;
// ... initialized in main(), then:
return MultiProvider(providers: [
  ListenableProvider<SettingProvider>.value(value: settingProvider),
  // ...
]);
```

**Key Providers**:
- `RelayProvider`: Manages relay connections, types (NORMAL/CACHE/TEMP/INDEX), and WebSocket lifecycle
- `MetadataProvider`: Caches user profiles (NIP-01/NIP-05)
- `EventReactionsProvider`: Handles likes, replies, reactions
- `DMProvider`: Direct messages (NIP-04/NIP-44)
- `GroupProvider`: NIP-29 relay-based groups

### Custom Base Classes
- `CustState<T>`: Custom StatefulWidget base with `onReady()` lifecycle hook called post-first-build
- `LaterFunction` mixin: Debounces rapid operations (e.g., batch UI updates when receiving relay events)

```dart
// Example from lib/component/cust_state.dart:
abstract class CustState<T extends StatefulWidget> extends State<T> {
  @override
  Widget build(BuildContext context) {
    Widget w = doBuild(context);
    if (!isInited) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onReady(context));
    }
    return w;
  }
  Widget doBuild(BuildContext context);
  Future<void> onReady(BuildContext context);
}
```

## Nostr Protocol Implementation

### Relay Management
Relays are categorized by type ([relay_provider.dart](lib/provider/relay_provider.dart)):
- `RelayType.NORMAL`: User-configured relays (NIP-65)
- `RelayType.CACHE`: High-performance caches (e.g., primal.net)
- `RelayType.TEMP`: Ephemeral relays for specific queries
- `RelayType.INDEX`: Search/indexer relays (NIP-50)

### Event Handling
Events are managed with `EventMemBox` (in-memory sorted collections) and `LaterFunction` for batched updates:

```dart
EventMemBox eventBox = EventMemBox(sortAfterAdd: false);
later(event, (events) {
  if (eventBox.addList(events)) setState(() {});
}, null);
```

### NIP Support
Extensive NIP coverage - see [README.md](README.md). Critical implementations:
- NIP-01: Core protocol in `packages/nostr_sdk/lib/event.dart`
- NIP-46: Nostr Connect (remote signers)
- NIP-55: Android Signer Application
- NIP-65: Relay list metadata (relay discovery)

## Component & Router Structure

### Component Naming
Components follow `*Component` suffix convention, split by concern:
- `lib/component/event/`: Event rendering (posts, notes, reactions)
- `lib/component/content/`: Content parsers (links, mentions, media)
- `lib/component/editor/`: Post composition

### Router Pattern
Routes are constants in [router_path.dart](lib/consts/router_path.dart) with corresponding `*Router` widgets in `lib/router/`. Navigation:

```dart
RouterPath.USER_CONTACT_LIST; // => lib/router/user/user_contact_list_router.dart
```

## Data Layer

### Dual Database Strategy
1. **SQLite** (`lib/data/db.dart`): Metadata, DM sessions, local events
2. **Isar** (`packages/relay_isar_db/`): High-performance relay data

### Profile Metadata
Cached in `metadata` table with validation status (`valid` column for NIP-05 verification).

## Development Workflows

### Prerequisites
```bash
# Initialize git submodules (critical!)
git submodule init
git submodule update
```

### Platform-Specific Builds
**Android**: `flutter build appbundle --release` or `flutter build apk --release --split-per-abi`

**Web**: `flutter build web --release --web-renderer canvaskit`

**Linux Dependencies**:
```bash
sudo apt-get install libsqlite3-0 libsqlite3-dev libmpv-dev libnotify-dev libayatana-appindicator3-dev
```

**Linux Packaging** (requires `flutter_distributor`):
```bash
dart pub global activate flutter_distributor
fastforge release --name=dev --jobs=release-dev-linux-deb
```

### Testing & Debugging
- Use `log()` from `dart:developer` for console output (grep pattern: `log\("`)
- Relay connection status via `RelayProvider.relayStatusMapMap`
- Event validation errors logged in `EventSignChecker` (packages/nostr_sdk)

## Key Conventions

### Imports
- Avoid relative imports beyond sibling directories; use absolute paths from `nostrmo/`
- Custom packages via path: `nostr_sdk: { path: packages/nostr_sdk }`

### Constants
- App-wide constants in `lib/consts/base.dart` (APP_NAME, BASE_PADDING, etc.)
- Theme/color definitions in `lib/consts/colors.dart` and `theme_style.dart`

### Platform Detection
Use `PlatformUtil` from `nostr_sdk` not `dart:io.Platform`:
```dart
if (PlatformUtil.isPC()) { /* desktop-specific logic */ }
```

### Error Handling
- Toast notifications via `bot_toast` package (already configured globally)
- Critical errors surface in `NoticeProvider` (user-visible notices)

## External Dependencies

### Special Cases
- `flutter_link_previewer`: Custom fork at sibling directory (not pub.dev)
- `local_auth`: Git dependency (Flutter packages repo) for latest biometric features
- Media playback via `media_kit` (cross-platform video/audio)

## Common Patterns to Follow

1. **Provider Updates**: Always call `notifyListeners()` after state changes
2. **Event Subscription**: Unsubscribe in `dispose()` via `nostr.unsubscribe(subscriptionId)`
3. **Relay Queries**: Specify relay types to avoid redundant queries
4. **UI Updates**: Batch with `LaterFunction.later()` when processing multiple relay events
5. **Navigation**: Use `RouterPath` constants, never hardcoded strings

## Debugging Tips

- Check relay connections: `RelayProvider.normalRelayStatusMap[relayUrl]?.connected`
- Event validation: Enable verbose logging in `EventSignChecker.check()`
- Metadata cache misses: Query `MetadataProvider.getMetadata(pubkey)`
