// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'target_number_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TargetNumberNotifier)
final targetNumberProvider = TargetNumberNotifierProvider._();

final class TargetNumberNotifierProvider
    extends $NotifierProvider<TargetNumberNotifier, TargetNumberState> {
  TargetNumberNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'targetNumberProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$targetNumberNotifierHash();

  @$internal
  @override
  TargetNumberNotifier create() => TargetNumberNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TargetNumberState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TargetNumberState>(value),
    );
  }
}

String _$targetNumberNotifierHash() =>
    r'e060d604e28d80741023c53fec2a54516cf0badc';

abstract class _$TargetNumberNotifier extends $Notifier<TargetNumberState> {
  TargetNumberState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TargetNumberState, TargetNumberState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TargetNumberState, TargetNumberState>,
              TargetNumberState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
