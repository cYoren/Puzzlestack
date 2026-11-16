// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'magic_squares_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MagicSquaresNotifier)
final magicSquaresProvider = MagicSquaresNotifierProvider._();

final class MagicSquaresNotifierProvider
    extends $NotifierProvider<MagicSquaresNotifier, MagicSquaresState> {
  MagicSquaresNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'magicSquaresProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$magicSquaresNotifierHash();

  @$internal
  @override
  MagicSquaresNotifier create() => MagicSquaresNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MagicSquaresState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MagicSquaresState>(value),
    );
  }
}

String _$magicSquaresNotifierHash() =>
    r'646d8d4d266e52dc9ff949dc615bfd73c056bc85';

abstract class _$MagicSquaresNotifier extends $Notifier<MagicSquaresState> {
  MagicSquaresState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MagicSquaresState, MagicSquaresState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MagicSquaresState, MagicSquaresState>,
              MagicSquaresState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
