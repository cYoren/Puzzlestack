// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_2048_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Game2048Notifier)
final game2048Provider = Game2048NotifierProvider._();

final class Game2048NotifierProvider
    extends $NotifierProvider<Game2048Notifier, Game2048State> {
  Game2048NotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'game2048Provider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$game2048NotifierHash();

  @$internal
  @override
  Game2048Notifier create() => Game2048Notifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Game2048State value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Game2048State>(value),
    );
  }
}

String _$game2048NotifierHash() => r'b08465a192a3d3094d4c972a2debcce7553433e3';

abstract class _$Game2048Notifier extends $Notifier<Game2048State> {
  Game2048State build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Game2048State, Game2048State>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Game2048State, Game2048State>,
              Game2048State,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
