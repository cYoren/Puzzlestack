// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crown_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CrownNotifier)
final crownProvider = CrownNotifierProvider._();

final class CrownNotifierProvider
    extends $NotifierProvider<CrownNotifier, CrownState> {
  CrownNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'crownProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$crownNotifierHash();

  @$internal
  @override
  CrownNotifier create() => CrownNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CrownState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CrownState>(value),
    );
  }
}

String _$crownNotifierHash() => r'310e4b58c07950ad94b112a831748d5802a2295d';

abstract class _$CrownNotifier extends $Notifier<CrownState> {
  CrownState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CrownState, CrownState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CrownState, CrownState>,
              CrownState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
