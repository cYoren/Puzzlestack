// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pipes_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PipesNotifier)
final pipesProvider = PipesNotifierProvider._();

final class PipesNotifierProvider
    extends $NotifierProvider<PipesNotifier, PipesState> {
  PipesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pipesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pipesNotifierHash();

  @$internal
  @override
  PipesNotifier create() => PipesNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PipesState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PipesState>(value),
    );
  }
}

String _$pipesNotifierHash() => r'13e6e0cc2e3fa576cc26652b8d82ae3bb4b5833d';

abstract class _$PipesNotifier extends $Notifier<PipesState> {
  PipesState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PipesState, PipesState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PipesState, PipesState>,
              PipesState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
