// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mental_calendar_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MentalCalendarNotifier)
final mentalCalendarProvider = MentalCalendarNotifierProvider._();

final class MentalCalendarNotifierProvider
    extends $NotifierProvider<MentalCalendarNotifier, MentalCalendarState> {
  MentalCalendarNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mentalCalendarProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mentalCalendarNotifierHash();

  @$internal
  @override
  MentalCalendarNotifier create() => MentalCalendarNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MentalCalendarState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MentalCalendarState>(value),
    );
  }
}

String _$mentalCalendarNotifierHash() =>
    r'7a2485574bad14794a21dde1418b25c76a25f4da';

abstract class _$MentalCalendarNotifier extends $Notifier<MentalCalendarState> {
  MentalCalendarState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MentalCalendarState, MentalCalendarState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MentalCalendarState, MentalCalendarState>,
              MentalCalendarState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
