// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'netslide_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(NetslideNotifier)
final netslideProvider = NetslideNotifierProvider._();

final class NetslideNotifierProvider
    extends $NotifierProvider<NetslideNotifier, NetState> {
  NetslideNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'netslideProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$netslideNotifierHash();

  @$internal
  @override
  NetslideNotifier create() => NetslideNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NetState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NetState>(value),
    );
  }
}

String _$netslideNotifierHash() => r'd5274497f6b08e60243d82001485fed8f3da30bd';

abstract class _$NetslideNotifier extends $Notifier<NetState> {
  NetState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<NetState, NetState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NetState, NetState>,
              NetState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
