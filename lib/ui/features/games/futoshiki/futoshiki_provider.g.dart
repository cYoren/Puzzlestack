// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'futoshiki_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FutoshikiNotifier)
final futoshikiProvider = FutoshikiNotifierProvider._();

final class FutoshikiNotifierProvider
    extends $NotifierProvider<FutoshikiNotifier, FutoshikiState> {
  FutoshikiNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'futoshikiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$futoshikiNotifierHash();

  @$internal
  @override
  FutoshikiNotifier create() => FutoshikiNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FutoshikiState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FutoshikiState>(value),
    );
  }
}

String _$futoshikiNotifierHash() => r'faf8bd489ec49f084a43695b2bded62756c6f56d';

abstract class _$FutoshikiNotifier extends $Notifier<FutoshikiState> {
  FutoshikiState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<FutoshikiState, FutoshikiState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FutoshikiState, FutoshikiState>,
              FutoshikiState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
