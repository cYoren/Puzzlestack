// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'definition_dash_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DefinitionDashNotifier)
final definitionDashProvider = DefinitionDashNotifierProvider._();

final class DefinitionDashNotifierProvider
    extends $NotifierProvider<DefinitionDashNotifier, DefinitionDashState> {
  DefinitionDashNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'definitionDashProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$definitionDashNotifierHash();

  @$internal
  @override
  DefinitionDashNotifier create() => DefinitionDashNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DefinitionDashState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DefinitionDashState>(value),
    );
  }
}

String _$definitionDashNotifierHash() =>
    r'4f23b7771a165c692385aa3dc03c0c1c72922663';

abstract class _$DefinitionDashNotifier extends $Notifier<DefinitionDashState> {
  DefinitionDashState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DefinitionDashState, DefinitionDashState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DefinitionDashState, DefinitionDashState>,
              DefinitionDashState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
