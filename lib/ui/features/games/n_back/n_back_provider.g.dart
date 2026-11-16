// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'n_back_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(NBackNotifier)
final nBackProvider = NBackNotifierProvider._();

final class NBackNotifierProvider
    extends $NotifierProvider<NBackNotifier, NBackState> {
  NBackNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nBackProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nBackNotifierHash();

  @$internal
  @override
  NBackNotifier create() => NBackNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NBackState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NBackState>(value),
    );
  }
}

String _$nBackNotifierHash() => r'6f4e4cfa9546830482cf893781387a3b1ca40a97';

abstract class _$NBackNotifier extends $Notifier<NBackState> {
  NBackState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<NBackState, NBackState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NBackState, NBackState>,
              NBackState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
