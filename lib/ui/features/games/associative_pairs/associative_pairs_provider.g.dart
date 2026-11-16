// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'associative_pairs_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AssociativePairsNotifier)
final associativePairsProvider = AssociativePairsNotifierProvider._();

final class AssociativePairsNotifierProvider
    extends $NotifierProvider<AssociativePairsNotifier, AssociativePairsState> {
  AssociativePairsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'associativePairsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$associativePairsNotifierHash();

  @$internal
  @override
  AssociativePairsNotifier create() => AssociativePairsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AssociativePairsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AssociativePairsState>(value),
    );
  }
}

String _$associativePairsNotifierHash() =>
    r'ba0b48c21468c2bf5f3efa5ab6c00dc4ecbb18e2';

abstract class _$AssociativePairsNotifier
    extends $Notifier<AssociativePairsState> {
  AssociativePairsState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AssociativePairsState, AssociativePairsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AssociativePairsState, AssociativePairsState>,
              AssociativePairsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
