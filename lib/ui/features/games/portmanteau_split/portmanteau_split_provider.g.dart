// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'portmanteau_split_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PortmanteauSplitNotifier)
final portmanteauSplitProvider = PortmanteauSplitNotifierProvider._();

final class PortmanteauSplitNotifierProvider
    extends $NotifierProvider<PortmanteauSplitNotifier, PortmanteauSplitState> {
  PortmanteauSplitNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'portmanteauSplitProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$portmanteauSplitNotifierHash();

  @$internal
  @override
  PortmanteauSplitNotifier create() => PortmanteauSplitNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PortmanteauSplitState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PortmanteauSplitState>(value),
    );
  }
}

String _$portmanteauSplitNotifierHash() =>
    r'8d1b621b3f85a7b3710ab19168482dda622fed22';

abstract class _$PortmanteauSplitNotifier
    extends $Notifier<PortmanteauSplitState> {
  PortmanteauSplitState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PortmanteauSplitState, PortmanteauSplitState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PortmanteauSplitState, PortmanteauSplitState>,
              PortmanteauSplitState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
