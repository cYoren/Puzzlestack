// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cognate_catch_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CognateCatchNotifier)
final cognateCatchProvider = CognateCatchNotifierProvider._();

final class CognateCatchNotifierProvider
    extends $NotifierProvider<CognateCatchNotifier, CognateCatchState> {
  CognateCatchNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cognateCatchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cognateCatchNotifierHash();

  @$internal
  @override
  CognateCatchNotifier create() => CognateCatchNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CognateCatchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CognateCatchState>(value),
    );
  }
}

String _$cognateCatchNotifierHash() =>
    r'7712f2e83175324660d3e0ec0865ef638de82a42';

abstract class _$CognateCatchNotifier extends $Notifier<CognateCatchState> {
  CognateCatchState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CognateCatchState, CognateCatchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CognateCatchState, CognateCatchState>,
              CognateCatchState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
