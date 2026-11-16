// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paper_folding_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PaperFoldingNotifier)
final paperFoldingProvider = PaperFoldingNotifierProvider._();

final class PaperFoldingNotifierProvider
    extends $NotifierProvider<PaperFoldingNotifier, PaperFoldingState> {
  PaperFoldingNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'paperFoldingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$paperFoldingNotifierHash();

  @$internal
  @override
  PaperFoldingNotifier create() => PaperFoldingNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PaperFoldingState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PaperFoldingState>(value),
    );
  }
}

String _$paperFoldingNotifierHash() =>
    r'19965fe317a3161df926e40952ed3c2294aecbe0';

abstract class _$PaperFoldingNotifier extends $Notifier<PaperFoldingState> {
  PaperFoldingState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PaperFoldingState, PaperFoldingState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PaperFoldingState, PaperFoldingState>,
              PaperFoldingState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
