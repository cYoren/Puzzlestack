// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'consonant_reconstruct_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ConsonantReconstructNotifier)
final consonantReconstructProvider = ConsonantReconstructNotifierProvider._();

final class ConsonantReconstructNotifierProvider
    extends
        $NotifierProvider<
          ConsonantReconstructNotifier,
          ConsonantReconstructState
        > {
  ConsonantReconstructNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'consonantReconstructProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$consonantReconstructNotifierHash();

  @$internal
  @override
  ConsonantReconstructNotifier create() => ConsonantReconstructNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConsonantReconstructState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConsonantReconstructState>(value),
    );
  }
}

String _$consonantReconstructNotifierHash() =>
    r'e385f03cb58406450ea245db82871c1aeb8a8234';

abstract class _$ConsonantReconstructNotifier
    extends $Notifier<ConsonantReconstructState> {
  ConsonantReconstructState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<ConsonantReconstructState, ConsonantReconstructState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ConsonantReconstructState, ConsonantReconstructState>,
              ConsonantReconstructState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
