// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fillomino_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FillominoNotifier)
final fillominoProvider = FillominoNotifierProvider._();

final class FillominoNotifierProvider
    extends $NotifierProvider<FillominoNotifier, FillominoState> {
  FillominoNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fillominoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fillominoNotifierHash();

  @$internal
  @override
  FillominoNotifier create() => FillominoNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FillominoState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FillominoState>(value),
    );
  }
}

String _$fillominoNotifierHash() => r'1304afeb2d2dee18f3584f48048c5b0b5ad40303';

abstract class _$FillominoNotifier extends $Notifier<FillominoState> {
  FillominoState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<FillominoState, FillominoState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FillominoState, FillominoState>,
              FillominoState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
