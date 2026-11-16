// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'negative_space_detection_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(NegativeSpaceDetectionNotifier)
final negativeSpaceDetectionProvider =
    NegativeSpaceDetectionNotifierProvider._();

final class NegativeSpaceDetectionNotifierProvider
    extends
        $NotifierProvider<
          NegativeSpaceDetectionNotifier,
          NegativeSpaceDetectionState
        > {
  NegativeSpaceDetectionNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'negativeSpaceDetectionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$negativeSpaceDetectionNotifierHash();

  @$internal
  @override
  NegativeSpaceDetectionNotifier create() => NegativeSpaceDetectionNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NegativeSpaceDetectionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NegativeSpaceDetectionState>(value),
    );
  }
}

String _$negativeSpaceDetectionNotifierHash() =>
    r'77cecd0e61954503cb0bbabd113d1df593380a7d';

abstract class _$NegativeSpaceDetectionNotifier
    extends $Notifier<NegativeSpaceDetectionState> {
  NegativeSpaceDetectionState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<NegativeSpaceDetectionState, NegativeSpaceDetectionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                NegativeSpaceDetectionState,
                NegativeSpaceDetectionState
              >,
              NegativeSpaceDetectionState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
