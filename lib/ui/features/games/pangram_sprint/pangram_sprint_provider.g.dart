// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pangram_sprint_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PangramSprintNotifier)
final pangramSprintProvider = PangramSprintNotifierProvider._();

final class PangramSprintNotifierProvider
    extends $NotifierProvider<PangramSprintNotifier, PangramSprintState> {
  PangramSprintNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pangramSprintProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pangramSprintNotifierHash();

  @$internal
  @override
  PangramSprintNotifier create() => PangramSprintNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PangramSprintState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PangramSprintState>(value),
    );
  }
}

String _$pangramSprintNotifierHash() =>
    r'440525832d0a91b6614d8cf8b9dd477362e6d145';

abstract class _$PangramSprintNotifier extends $Notifier<PangramSprintState> {
  PangramSprintState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PangramSprintState, PangramSprintState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PangramSprintState, PangramSprintState>,
              PangramSprintState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
