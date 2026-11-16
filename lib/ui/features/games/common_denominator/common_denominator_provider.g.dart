// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'common_denominator_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CommonDenominatorNotifier)
final commonDenominatorProvider = CommonDenominatorNotifierProvider._();

final class CommonDenominatorNotifierProvider
    extends
        $NotifierProvider<CommonDenominatorNotifier, CommonDenominatorState> {
  CommonDenominatorNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'commonDenominatorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$commonDenominatorNotifierHash();

  @$internal
  @override
  CommonDenominatorNotifier create() => CommonDenominatorNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CommonDenominatorState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CommonDenominatorState>(value),
    );
  }
}

String _$commonDenominatorNotifierHash() =>
    r'a187a301f1aa678f91f1e46026457ac11d4c7cdf';

abstract class _$CommonDenominatorNotifier
    extends $Notifier<CommonDenominatorState> {
  CommonDenominatorState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<CommonDenominatorState, CommonDenominatorState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CommonDenominatorState, CommonDenominatorState>,
              CommonDenominatorState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
