// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inertia_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(InertiaNotifier)
final inertiaProvider = InertiaNotifierProvider._();

final class InertiaNotifierProvider
    extends $NotifierProvider<InertiaNotifier, InertiaState> {
  InertiaNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inertiaProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inertiaNotifierHash();

  @$internal
  @override
  InertiaNotifier create() => InertiaNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InertiaState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InertiaState>(value),
    );
  }
}

String _$inertiaNotifierHash() => r'c4794b0564a7f6e167097c7cc59a6d76012600df';

abstract class _$InertiaNotifier extends $Notifier<InertiaState> {
  InertiaState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<InertiaState, InertiaState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<InertiaState, InertiaState>,
              InertiaState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
