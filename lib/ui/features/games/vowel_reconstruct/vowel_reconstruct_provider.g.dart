// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vowel_reconstruct_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(VowelReconstructNotifier)
final vowelReconstructProvider = VowelReconstructNotifierProvider._();

final class VowelReconstructNotifierProvider
    extends $NotifierProvider<VowelReconstructNotifier, VowelReconstructState> {
  VowelReconstructNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'vowelReconstructProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vowelReconstructNotifierHash();

  @$internal
  @override
  VowelReconstructNotifier create() => VowelReconstructNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VowelReconstructState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VowelReconstructState>(value),
    );
  }
}

String _$vowelReconstructNotifierHash() =>
    r'a8ad06c3c29223413ebbefce5bed2fe43b1a2e7d';

abstract class _$VowelReconstructNotifier
    extends $Notifier<VowelReconstructState> {
  VowelReconstructState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<VowelReconstructState, VowelReconstructState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<VowelReconstructState, VowelReconstructState>,
              VowelReconstructState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
