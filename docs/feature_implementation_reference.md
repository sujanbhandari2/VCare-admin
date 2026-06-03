# Feature Implementation Reference

This document defines the implementation contract for feature development in this codebase.

Use this as the source of truth for future AI-generated features so naming, architecture, and state management stay consistent even if current files change later.

## Core Architecture

Every feature should follow the same 3-layer structure:

```text
lib/features/<feature>/
  data/
    mappers/
    models/
    repositories/
  domain/
    entities/
    repositories/
  presentation/
    pages/
    providers/
    state/
    widgets/
```

Dependency direction:

- `presentation -> domain`
- `data -> domain`
- `domain -> nothing`

## Canonical Feature Flow

Every feature should follow this runtime flow:

1. A presentation widget calls a notifier method.
2. The notifier updates feature state to loading.
3. The notifier calls a repository contract.
4. The repository implementation reads from API, storage, remote config, or another infrastructure source.
5. Raw data is parsed into a model.
6. The model is mapped into a domain entity.
7. The repository returns `EitherResponseOrException<Entity>`.
8. The notifier converts that result into presentation state.
9. The screen or widget reacts to state and performs UI side effects if needed.

This keeps business logic out of widgets and infrastructure out of presentation.

## Naming Conventions To Standardize

These are the conventions future features should follow.

### Feature folder names

- Use snake_case for feature folders.
- Examples: `inapp_update`, `user_profile`, `notification_settings`.

### Entity names

- Use singular PascalCase nouns.
- Examples: `UserProfile`, `RemoteConfigAppUpdateInfo`.

### Model names

- Use the entity name plus `Model`.
- Examples: `UserProfileModel`, `RemoteConfigAppUpdateInfoModel`.

### Mapper names

- Use the entity/model name plus `Mapper`.
- Prefer extension-based mapping for `toEntity()` and `toModel()`.

### Repository contracts

- Name as `<FeatureConcept>Repository`.
- Example: `UserProfileRepository`.

### Repository implementations

- Name as `<FeatureConcept>RepositoryImpl`.
- Example: `UserProfileRepositoryImpl`.

### Provider files

- Use `<feature>_repository_provider.dart` for DI.
- Use `<feature>_state_provider.dart` for Riverpod notifiers.
- The provider variable should match the file name.

Recommended examples:

- `user_profile_repository_provider.dart` -> `userProfileRepositoryProvider`
- `user_profile_state_provider.dart` -> `userProfileStateProvider`
- `app_update_repository_provider.dart` -> `appUpdateRepositoryProvider`
- `app_update_state_provider.dart` -> `appUpdateStateProvider`

### State files

- Prefer singular folder name: `presentation/state/`
- Prefer state class names ending in `State`.
- Examples: `UserProfileState`, `AppUpdateState`

### Widget files

- Prefix feature widgets with the feature UI root.
- Example: `app_update_sheet_release_notes_tile.dart`

## Recommended Canonical Feature Template

For new business features, prefer this layout:

```text
lib/features/<feature>/
  data/
    mappers/
      <feature>_mapper.dart
    models/
      <feature>_model.dart
    repositories/
      <feature>_repository_impl.dart
  domain/
    entities/
      <feature>.dart
    repositories/
      <feature>_repository.dart
  presentation/
    pages/
      <feature>_screen.dart
    providers/
      <feature>_repository_provider.dart
      <feature>_state_provider.dart
    state/
      <feature>_state.dart
    widgets/
      <feature>_<widget>.dart
```

## Canonical Naming Shape

Once a feature name is chosen, every class and file should derive directly from that feature name.

Example using `user_profile`:

```text
Feature folder: user_profile
Entity: UserProfile
Model: UserProfileModel
Repository contract: UserProfileRepository
Repository impl: UserProfileRepositoryImpl
Repository provider: userProfileRepositoryProvider
State class: UserProfileState
State notifier: UserProfileStateNotifier
State provider: userProfileStateProvider
Screen: UserProfileScreen or ProfileScreen
Primary widget prefix: user_profile_...
```

Example using `app_update`:

```text
Feature folder: app_update
Entity: AppUpdateInfo
Model: AppUpdateInfoModel
Repository contract: AppUpdateRepository
Repository impl: AppUpdateRepositoryImpl
Repository provider: appUpdateRepositoryProvider
State class: AppUpdateState
State notifier: AppUpdateStateNotifier
State provider: appUpdateStateProvider
Screen or sheet root: AppUpdateSheet
Primary widget prefix: app_update_...
```

Rule:

- Avoid mixing multiple naming roots inside one feature.
- If the feature is named `app_update`, do not mix `remote_config_app_update`, `app_update_info`, and `update_checker` unless they are clearly separate sub-features.

## State Management Rules For AI Agents

- Use `@Riverpod(keepAlive: true)` for feature notifiers unless there is a clear reason not to.
- Keep async workflow inside the notifier, not inside widgets.
- Use `OperationState<T>` for loading, success, and failure tracking.
- Expose convenience getters on the feature state such as `fetching`, `isUpdating`, `hasUpdate`, `error`, or `data`.
- Use `ref.read(...)` inside actions and `ref.watch(...)` or `ref.listen(...)` inside widgets.
- Use `ref.mounted` before mutating notifier state after awaits.
- Keep UI side effects such as dialogs, sheets, snackbars, and navigation inside presentation widgets/screens.

## Canonical State Shape

For a read-only feature:

```dart
class FeatureState {
  const FeatureState({
    this.operation = const OperationState<FeatureEntity?>.idle(),
  });

  final OperationState<FeatureEntity?> operation;

  bool get requesting => operation.isLoading;
  bool get hasError => operation.hasError;
  String? get error => operation.errorMessage;
  FeatureEntity? get data => operation.data;

  FeatureState loading() =>
      FeatureState(operation: OperationState.loading(data: data));

  FeatureState success(FeatureEntity? data) =>
      FeatureState(operation: OperationState.success(data));

  FeatureState failure(String? message) =>
      FeatureState(operation: OperationState.failure(message, data: data));
}
```

For a feature with separate fetch and update actions:

```dart
class FeatureState {
  const FeatureState({
    this.fetchOperation = const OperationState<FeatureEntity>.idle(),
    this.updateOperation = const OperationState<FeatureEntity>.idle(),
    this.data,
  });

  final OperationState<FeatureEntity> fetchOperation;
  final OperationState<FeatureEntity> updateOperation;
  final FeatureEntity? data;

  bool get fetching => fetchOperation.isLoading;
  bool get updating => updateOperation.isLoading;
  String? get error =>
      updateOperation.errorMessage ?? fetchOperation.errorMessage;
}
```

Rule:

- Use one `operation` for simple single-action features.
- Use separate operation fields when fetch/update or multiple user actions need independent tracking.

## Repository Rules For AI Agents

- Repository interfaces live in `domain/repositories`.
- Repository implementations live in `data/repositories`.
- Repositories return `EitherResponseOrException<T>`.
- Wrap async repository work in `safeNetworkCall(...)`.
- Parse remote payloads into models first, then map into domain entities.
- Keep `ApiClient`, `FirebaseRemoteConfigService`, `PackageInfo`, and similar infrastructure inside data layer only.

## Canonical Repository Shape

Repository contract:

```dart
abstract class FeatureRepository {
  Future<EitherResponseOrException<FeatureEntity>> fetchFeature({
    required int id,
    bool forceRefresh = true,
  });
}
```

Repository implementation:

```dart
class FeatureRepositoryImpl implements FeatureRepository {
  const FeatureRepositoryImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<EitherResponseOrException<FeatureEntity>> fetchFeature({
    required int id,
    bool forceRefresh = true,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.get(
        'feature-endpoint/$id',
        forceRefresh: forceRefresh,
      );

      final model = ResponseValidator.parse(
        response,
        (data) => FeatureModel.fromJson(data),
        dataValidator: (data) => data is Map,
      );

      return model.toEntity();
    });
  }
}
```

## Mapper Rules For AI Agents

- Map API JSON into `Model`.
- Map `Model` into `Entity`.
- Do not expose raw JSON maps to presentation.
- Use extension methods when there is a 1:1 mapping pattern.

## Canonical Mapper Shape

```dart
extension FeatureModelMapper on FeatureModel {
  FeatureEntity toEntity() {
    return FeatureEntity(
      id: id,
      name: name,
    );
  }
}

extension FeatureEntityMapper on FeatureEntity {
  FeatureModel toModel() {
    return FeatureModel(
      id: id,
      name: name,
    );
  }
}
```

## UI Rules For AI Agents

- Screens should orchestrate feature actions, not contain data-access logic.
- Feature widgets should stay feature-scoped until they are clearly reusable.
- Move reusable UI into `lib/shared/widgets/` only after a second real usage appears.
- Use `context.appLocalization` and shared theme extensions consistently.

## Canonical Notifier Shape

```dart
@Riverpod(keepAlive: true)
class FeatureStateNotifier extends _$FeatureStateNotifier {
  @override
  FeatureState build() => const FeatureState();

  Future<void> fetchFeature({
    required int id,
    void Function(FeatureEntity? data)? onCompleted,
  }) async {
    if (ref.mounted) {
      state = state.loading();
    }

    final response = await ref
        .read(featureRepositoryProvider)
        .fetchFeature(id: id);

    response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.failure(error.message);
        }
        onCompleted?.call(null);
      },
      success: (result) {
        if (ref.mounted) {
          state = state.success(result);
        }
        onCompleted?.call(result);
      },
    );
  }
}
```

## Canonical Provider Shape

```dart
@Riverpod(keepAlive: true)
FeatureRepository featureRepository(Ref ref) {
  final apiClient = ref.read(apiClientProvider);
  return FeatureRepositoryImpl(apiClient);
}
```

## Screen Composition Rules

- A screen may trigger initial load from `initState()` using `addPostFrameCallback(...)`.
- A screen may use `ref.watch(...)` for rebuild state.
- A screen may use `ref.listen(...)` for one-time side effects.
- A screen should not parse API data, call `ApiClient`, or map models.
- A screen should delegate user actions to notifier methods such as `fetchFeature()`, `submitForm()`, or `updateProfile()`.

## When To Split Widgets

Split a feature widget when any of these become true:

- The screen body becomes visually sectioned into distinct blocks.
- A widget has its own props and can be named clearly.
- A widget contains interaction logic that is easier to isolate.
- The parent screen becomes harder to scan because of UI density.

Do not move a widget into `shared/` just because it is small. Move it only when it becomes reusable across features.

## Current Repo Inconsistencies To Avoid Repeating

The codebase is already solid, but future implementations should normalize these:

- Prefer `presentation/state/` over mixing `state/` and `states/`.
- Prefer provider names without extra filler words when not needed. Example: `remoteConfigAppUpdateInfoRepositoryProvider` is more verbose than necessary.
- Use one repository style consistently. Prefer `implements` for repository implementations instead of mixing `extends` and `implements`.
- Keep one naming shape per feature. Example: if the feature is `app_update`, use `AppUpdateState`, `AppUpdateRepository`, and `appUpdateStateProvider` consistently.
- Avoid making the canonical pattern depend on any current feature file path.

## Recommended AI Agent Rule Snippet

Use this as the instruction baseline for future feature implementation:

```text
When implementing a new feature in this Flutter codebase:

1. Create the feature under lib/features/<feature_name>/ using snake_case.
2. Keep the structure limited to data, domain, and presentation layers.
3. Put repository contracts in domain and implementations in data.
4. Use model -> mapper -> entity transformation. Do not pass raw API JSON into presentation.
5. Create a Riverpod repository provider and a Riverpod state notifier provider.
6. Represent UI state with a dedicated <Feature>State class built on shared OperationState<T>.
7. Keep async logic in providers/notifiers and keep navigation/dialog/snackbar behavior in screens/widgets.
8. Prefer small feature widgets over large screens.
9. Reuse shared services from core and shared instead of re-implementing infrastructure.
10. Match file, class, and provider names exactly to the feature name for consistency.
```

## Final Rule For Future Agents

Future implementations should follow the pattern defined in this document even if older features differ in small naming or structure details.

When there is a conflict between an old feature and this document, prefer this document unless the team explicitly decides to migrate the standard.
