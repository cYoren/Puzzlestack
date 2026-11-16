// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(userRepository)
final userRepositoryProvider = UserRepositoryProvider._();

final class UserRepositoryProvider
    extends $FunctionalProvider<UserRepository, UserRepository, UserRepository>
    with $Provider<UserRepository> {
  UserRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userRepositoryHash();

  @$internal
  @override
  $ProviderElement<UserRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UserRepository create(Ref ref) {
    return userRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserRepository>(value),
    );
  }
}

String _$userRepositoryHash() => r'b177bedb444b72fc1d0cf28ac01fbe6d1b4d9f6b';

@ProviderFor(UserDataNotifier)
final userDataProvider = UserDataNotifierProvider._();

final class UserDataNotifierProvider
    extends $NotifierProvider<UserDataNotifier, UserData> {
  UserDataNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userDataProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userDataNotifierHash();

  @$internal
  @override
  UserDataNotifier create() => UserDataNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserData>(value),
    );
  }
}

String _$userDataNotifierHash() => r'0ac92e76f55e732d3b55b6eac6ec631fbd97913f';

abstract class _$UserDataNotifier extends $Notifier<UserData> {
  UserData build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<UserData, UserData>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<UserData, UserData>,
              UserData,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(GameStreakNotifier)
final gameStreakProvider = GameStreakNotifierProvider._();

final class GameStreakNotifierProvider
    extends $NotifierProvider<GameStreakNotifier, Map<String, GameStreak>> {
  GameStreakNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gameStreakProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gameStreakNotifierHash();

  @$internal
  @override
  GameStreakNotifier create() => GameStreakNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, GameStreak> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, GameStreak>>(value),
    );
  }
}

String _$gameStreakNotifierHash() =>
    r'637832777b0a69c067592586b2184aaa4aec388f';

abstract class _$GameStreakNotifier extends $Notifier<Map<String, GameStreak>> {
  Map<String, GameStreak> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<Map<String, GameStreak>, Map<String, GameStreak>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, GameStreak>, Map<String, GameStreak>>,
              Map<String, GameStreak>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
