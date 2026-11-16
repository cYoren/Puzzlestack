// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'target_10_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Target10Notifier)
final target10Provider = Target10NotifierProvider._();

final class Target10NotifierProvider
    extends $NotifierProvider<Target10Notifier, Target10State> {
  Target10NotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'target10Provider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$target10NotifierHash();

  @$internal
  @override
  Target10Notifier create() => Target10Notifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Target10State value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Target10State>(value),
    );
  }
}

String _$target10NotifierHash() => r'881661c239da345276b66a682dbe66b7cd3c9f9f';

abstract class _$Target10Notifier extends $Notifier<Target10State> {
  Target10State build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Target10State, Target10State>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Target10State, Target10State>,
              Target10State,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
