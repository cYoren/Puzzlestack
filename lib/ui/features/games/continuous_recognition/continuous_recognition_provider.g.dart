// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'continuous_recognition_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ContinuousRecognitionNotifier)
final continuousRecognitionProvider = ContinuousRecognitionNotifierProvider._();

final class ContinuousRecognitionNotifierProvider
    extends
        $NotifierProvider<
          ContinuousRecognitionNotifier,
          ContinuousRecognitionState
        > {
  ContinuousRecognitionNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'continuousRecognitionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$continuousRecognitionNotifierHash();

  @$internal
  @override
  ContinuousRecognitionNotifier create() => ContinuousRecognitionNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ContinuousRecognitionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ContinuousRecognitionState>(value),
    );
  }
}

String _$continuousRecognitionNotifierHash() =>
    r'48f61cbb29d36b067f55acf5f336040cdab25cce';

abstract class _$ContinuousRecognitionNotifier
    extends $Notifier<ContinuousRecognitionState> {
  ContinuousRecognitionState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<ContinuousRecognitionState, ContinuousRecognitionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                ContinuousRecognitionState,
                ContinuousRecognitionState
              >,
              ContinuousRecognitionState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
