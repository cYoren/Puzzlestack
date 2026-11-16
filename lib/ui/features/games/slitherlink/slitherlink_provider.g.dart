// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'slitherlink_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SlitherlinkNotifier)
final slitherlinkProvider = SlitherlinkNotifierProvider._();

final class SlitherlinkNotifierProvider
    extends $NotifierProvider<SlitherlinkNotifier, SlitherlinkState> {
  SlitherlinkNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'slitherlinkProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$slitherlinkNotifierHash();

  @$internal
  @override
  SlitherlinkNotifier create() => SlitherlinkNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SlitherlinkState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SlitherlinkState>(value),
    );
  }
}

String _$slitherlinkNotifierHash() =>
    r'c5a5ea8aa769f2878a696a3f51432a1d8acfa873';

abstract class _$SlitherlinkNotifier extends $Notifier<SlitherlinkState> {
  SlitherlinkState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SlitherlinkState, SlitherlinkState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SlitherlinkState, SlitherlinkState>,
              SlitherlinkState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
