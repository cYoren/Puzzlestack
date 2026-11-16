// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sequence_sleuth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SequenceSleuthNotifier)
final sequenceSleuthProvider = SequenceSleuthNotifierProvider._();

final class SequenceSleuthNotifierProvider
    extends $NotifierProvider<SequenceSleuthNotifier, SequenceSleuthState> {
  SequenceSleuthNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sequenceSleuthProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sequenceSleuthNotifierHash();

  @$internal
  @override
  SequenceSleuthNotifier create() => SequenceSleuthNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SequenceSleuthState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SequenceSleuthState>(value),
    );
  }
}

String _$sequenceSleuthNotifierHash() =>
    r'c091593c7c891166eb62f951bad9845e14119380';

abstract class _$SequenceSleuthNotifier extends $Notifier<SequenceSleuthState> {
  SequenceSleuthState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SequenceSleuthState, SequenceSleuthState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SequenceSleuthState, SequenceSleuthState>,
              SequenceSleuthState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
