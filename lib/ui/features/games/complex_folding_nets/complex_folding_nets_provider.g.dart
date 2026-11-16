// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'complex_folding_nets_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ComplexFoldingNetsNotifier)
final complexFoldingNetsProvider = ComplexFoldingNetsNotifierProvider._();

final class ComplexFoldingNetsNotifierProvider
    extends
        $NotifierProvider<ComplexFoldingNetsNotifier, ComplexFoldingNetsState> {
  ComplexFoldingNetsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'complexFoldingNetsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$complexFoldingNetsNotifierHash();

  @$internal
  @override
  ComplexFoldingNetsNotifier create() => ComplexFoldingNetsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ComplexFoldingNetsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ComplexFoldingNetsState>(value),
    );
  }
}

String _$complexFoldingNetsNotifierHash() =>
    r'd1cb65f9c339fe5ee06de65b91f565704b0e5d48';

abstract class _$ComplexFoldingNetsNotifier
    extends $Notifier<ComplexFoldingNetsState> {
  ComplexFoldingNetsState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<ComplexFoldingNetsState, ComplexFoldingNetsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ComplexFoldingNetsState, ComplexFoldingNetsState>,
              ComplexFoldingNetsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
