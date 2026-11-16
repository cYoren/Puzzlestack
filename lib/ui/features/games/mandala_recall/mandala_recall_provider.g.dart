// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mandala_recall_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MandalaRecallNotifier)
final mandalaRecallProvider = MandalaRecallNotifierProvider._();

final class MandalaRecallNotifierProvider
    extends $NotifierProvider<MandalaRecallNotifier, MandalaRecallState> {
  MandalaRecallNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mandalaRecallProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mandalaRecallNotifierHash();

  @$internal
  @override
  MandalaRecallNotifier create() => MandalaRecallNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MandalaRecallState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MandalaRecallState>(value),
    );
  }
}

String _$mandalaRecallNotifierHash() =>
    r'2e138fde92ffc223bdc9a1150133207ac2268bee';

abstract class _$MandalaRecallNotifier extends $Notifier<MandalaRecallState> {
  MandalaRecallState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MandalaRecallState, MandalaRecallState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MandalaRecallState, MandalaRecallState>,
              MandalaRecallState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
