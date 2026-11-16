// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rhythm_master_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RhythmMasterNotifier)
final rhythmMasterProvider = RhythmMasterNotifierProvider._();

final class RhythmMasterNotifierProvider
    extends $NotifierProvider<RhythmMasterNotifier, RhythmMasterState> {
  RhythmMasterNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'rhythmMasterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$rhythmMasterNotifierHash();

  @$internal
  @override
  RhythmMasterNotifier create() => RhythmMasterNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RhythmMasterState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RhythmMasterState>(value),
    );
  }
}

String _$rhythmMasterNotifierHash() =>
    r'47e59b0ce202b4de4aa752c0dc8cdb07999cbbee';

abstract class _$RhythmMasterNotifier extends $Notifier<RhythmMasterState> {
  RhythmMasterState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RhythmMasterState, RhythmMasterState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RhythmMasterState, RhythmMasterState>,
              RhythmMasterState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
