// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vocabulary_builder_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(VocabularyBuilderNotifier)
final vocabularyBuilderProvider = VocabularyBuilderNotifierProvider._();

final class VocabularyBuilderNotifierProvider
    extends
        $NotifierProvider<VocabularyBuilderNotifier, VocabularyBuilderState> {
  VocabularyBuilderNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'vocabularyBuilderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vocabularyBuilderNotifierHash();

  @$internal
  @override
  VocabularyBuilderNotifier create() => VocabularyBuilderNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VocabularyBuilderState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VocabularyBuilderState>(value),
    );
  }
}

String _$vocabularyBuilderNotifierHash() =>
    r'1dcbafe6ba6b233e6216fae63499d2d991ac2cac';

abstract class _$VocabularyBuilderNotifier
    extends $Notifier<VocabularyBuilderState> {
  VocabularyBuilderState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<VocabularyBuilderState, VocabularyBuilderState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<VocabularyBuilderState, VocabularyBuilderState>,
              VocabularyBuilderState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
