// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mental_mapping_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MentalMappingNotifier)
final mentalMappingProvider = MentalMappingNotifierProvider._();

final class MentalMappingNotifierProvider
    extends $NotifierProvider<MentalMappingNotifier, MentalMappingState> {
  MentalMappingNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mentalMappingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mentalMappingNotifierHash();

  @$internal
  @override
  MentalMappingNotifier create() => MentalMappingNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MentalMappingState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MentalMappingState>(value),
    );
  }
}

String _$mentalMappingNotifierHash() =>
    r'6a10283bd64145f467b501ae48c6b2407cd00ad1';

abstract class _$MentalMappingNotifier extends $Notifier<MentalMappingState> {
  MentalMappingState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MentalMappingState, MentalMappingState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MentalMappingState, MentalMappingState>,
              MentalMappingState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
