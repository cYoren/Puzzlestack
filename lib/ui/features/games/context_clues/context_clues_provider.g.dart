// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'context_clues_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ContextCluesNotifier)
final contextCluesProvider = ContextCluesNotifierProvider._();

final class ContextCluesNotifierProvider
    extends $NotifierProvider<ContextCluesNotifier, ContextCluesState> {
  ContextCluesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contextCluesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contextCluesNotifierHash();

  @$internal
  @override
  ContextCluesNotifier create() => ContextCluesNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ContextCluesState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ContextCluesState>(value),
    );
  }
}

String _$contextCluesNotifierHash() =>
    r'298544dc3cdbd6a665e86c67335eb5bb134d34bb';

abstract class _$ContextCluesNotifier extends $Notifier<ContextCluesState> {
  ContextCluesState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ContextCluesState, ContextCluesState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ContextCluesState, ContextCluesState>,
              ContextCluesState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
