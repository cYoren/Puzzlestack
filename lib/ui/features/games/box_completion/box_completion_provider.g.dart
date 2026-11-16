// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'box_completion_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BoxCompletionNotifier)
final boxCompletionProvider = BoxCompletionNotifierProvider._();

final class BoxCompletionNotifierProvider
    extends $NotifierProvider<BoxCompletionNotifier, BoxCompletionState> {
  BoxCompletionNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'boxCompletionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$boxCompletionNotifierHash();

  @$internal
  @override
  BoxCompletionNotifier create() => BoxCompletionNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BoxCompletionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BoxCompletionState>(value),
    );
  }
}

String _$boxCompletionNotifierHash() =>
    r'ae08e43e9a797dcca71955405c607ad69f23f704';

abstract class _$BoxCompletionNotifier extends $Notifier<BoxCompletionState> {
  BoxCompletionState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<BoxCompletionState, BoxCompletionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BoxCompletionState, BoxCompletionState>,
              BoxCompletionState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
