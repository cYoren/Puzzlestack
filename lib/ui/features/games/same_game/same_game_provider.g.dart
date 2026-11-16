// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'same_game_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SameGameNotifier)
final sameGameProvider = SameGameNotifierProvider._();

final class SameGameNotifierProvider
    extends $NotifierProvider<SameGameNotifier, SameGameState> {
  SameGameNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sameGameProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sameGameNotifierHash();

  @$internal
  @override
  SameGameNotifier create() => SameGameNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SameGameState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SameGameState>(value),
    );
  }
}

String _$sameGameNotifierHash() => r'1fb3665307024d8b153ef9221c75332dcf289ec9';

abstract class _$SameGameNotifier extends $Notifier<SameGameState> {
  SameGameState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SameGameState, SameGameState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SameGameState, SameGameState>,
              SameGameState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
