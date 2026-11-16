// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mental_rotation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MentalRotationNotifier)
final mentalRotationProvider = MentalRotationNotifierProvider._();

final class MentalRotationNotifierProvider
    extends $NotifierProvider<MentalRotationNotifier, MentalRotationState> {
  MentalRotationNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mentalRotationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mentalRotationNotifierHash();

  @$internal
  @override
  MentalRotationNotifier create() => MentalRotationNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MentalRotationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MentalRotationState>(value),
    );
  }
}

String _$mentalRotationNotifierHash() =>
    r'0a52f590b896d4816a1c8c7d214b0b2ec09a4fe0';

abstract class _$MentalRotationNotifier extends $Notifier<MentalRotationState> {
  MentalRotationState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MentalRotationState, MentalRotationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MentalRotationState, MentalRotationState>,
              MentalRotationState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
