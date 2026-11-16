// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sternberg_task_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SternbergTaskNotifier)
final sternbergTaskProvider = SternbergTaskNotifierProvider._();

final class SternbergTaskNotifierProvider
    extends $NotifierProvider<SternbergTaskNotifier, SternbergState> {
  SternbergTaskNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sternbergTaskProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sternbergTaskNotifierHash();

  @$internal
  @override
  SternbergTaskNotifier create() => SternbergTaskNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SternbergState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SternbergState>(value),
    );
  }
}

String _$sternbergTaskNotifierHash() =>
    r'9ff441b5dcf397c169921647e2cdcb54aaf6a0f8';

abstract class _$SternbergTaskNotifier extends $Notifier<SternbergState> {
  SternbergState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SternbergState, SternbergState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SternbergState, SternbergState>,
              SternbergState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
