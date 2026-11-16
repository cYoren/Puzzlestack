// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'multiple_object_tracking_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MOTNotifier)
final mOTProvider = MOTNotifierProvider._();

final class MOTNotifierProvider
    extends $NotifierProvider<MOTNotifier, MOTState> {
  MOTNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mOTProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mOTNotifierHash();

  @$internal
  @override
  MOTNotifier create() => MOTNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MOTState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MOTState>(value),
    );
  }
}

String _$mOTNotifierHash() => r'77c4b74a4cfc5599f4e4693929e0e1aff48ba148';

abstract class _$MOTNotifier extends $Notifier<MOTState> {
  MOTState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MOTState, MOTState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MOTState, MOTState>,
              MOTState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
