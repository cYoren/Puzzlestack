// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rule_switcher_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RuleSwitcherNotifier)
final ruleSwitcherProvider = RuleSwitcherNotifierProvider._();

final class RuleSwitcherNotifierProvider
    extends $NotifierProvider<RuleSwitcherNotifier, RuleSwitcherState> {
  RuleSwitcherNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ruleSwitcherProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ruleSwitcherNotifierHash();

  @$internal
  @override
  RuleSwitcherNotifier create() => RuleSwitcherNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RuleSwitcherState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RuleSwitcherState>(value),
    );
  }
}

String _$ruleSwitcherNotifierHash() =>
    r'b3965230cd1f2d8705e2b443babceed9f2b75937';

abstract class _$RuleSwitcherNotifier extends $Notifier<RuleSwitcherState> {
  RuleSwitcherState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RuleSwitcherState, RuleSwitcherState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RuleSwitcherState, RuleSwitcherState>,
              RuleSwitcherState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
