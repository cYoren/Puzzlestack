// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_session_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GameSessionNotifier)
final gameSessionProvider = GameSessionNotifierProvider._();

final class GameSessionNotifierProvider
    extends $NotifierProvider<GameSessionNotifier, GameSession> {
  GameSessionNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gameSessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gameSessionNotifierHash();

  @$internal
  @override
  GameSessionNotifier create() => GameSessionNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GameSession value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GameSession>(value),
    );
  }
}

String _$gameSessionNotifierHash() =>
    r'8e6cfd6031bae53c30653e1594c2be7b7c54b637';

abstract class _$GameSessionNotifier extends $Notifier<GameSession> {
  GameSession build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<GameSession, GameSession>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GameSession, GameSession>,
              GameSession,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
