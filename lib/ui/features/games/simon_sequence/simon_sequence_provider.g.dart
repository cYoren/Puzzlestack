// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'simon_sequence_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SimonSequenceNotifier)
final simonSequenceProvider = SimonSequenceNotifierProvider._();

final class SimonSequenceNotifierProvider
    extends $NotifierProvider<SimonSequenceNotifier, SimonSequenceState> {
  SimonSequenceNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'simonSequenceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$simonSequenceNotifierHash();

  @$internal
  @override
  SimonSequenceNotifier create() => SimonSequenceNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SimonSequenceState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SimonSequenceState>(value),
    );
  }
}

String _$simonSequenceNotifierHash() =>
    r'd92138555eb3bf6b81d4d9340d6a23248896bdf7';

abstract class _$SimonSequenceNotifier extends $Notifier<SimonSequenceState> {
  SimonSequenceState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SimonSequenceState, SimonSequenceState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SimonSequenceState, SimonSequenceState>,
              SimonSequenceState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
