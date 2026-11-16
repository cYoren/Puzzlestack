// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rhyme_master_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RhymeMasterNotifier)
final rhymeMasterProvider = RhymeMasterNotifierProvider._();

final class RhymeMasterNotifierProvider
    extends $NotifierProvider<RhymeMasterNotifier, RhymeMasterState> {
  RhymeMasterNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'rhymeMasterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$rhymeMasterNotifierHash();

  @$internal
  @override
  RhymeMasterNotifier create() => RhymeMasterNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RhymeMasterState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RhymeMasterState>(value),
    );
  }
}

String _$rhymeMasterNotifierHash() =>
    r'942cd5353723b8c518c3ef7b6f87fba363e414cb';

abstract class _$RhymeMasterNotifier extends $Notifier<RhymeMasterState> {
  RhymeMasterState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RhymeMasterState, RhymeMasterState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RhymeMasterState, RhymeMasterState>,
              RhymeMasterState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
