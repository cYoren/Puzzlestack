// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'minesweeper_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MinesweeperNotifier)
final minesweeperProvider = MinesweeperNotifierProvider._();

final class MinesweeperNotifierProvider
    extends $NotifierProvider<MinesweeperNotifier, MinesweeperState> {
  MinesweeperNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'minesweeperProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$minesweeperNotifierHash();

  @$internal
  @override
  MinesweeperNotifier create() => MinesweeperNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MinesweeperState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MinesweeperState>(value),
    );
  }
}

String _$minesweeperNotifierHash() =>
    r'56eaa75de5aca59d49c28c39ffc78deb39ddd118';

abstract class _$MinesweeperNotifier extends $Notifier<MinesweeperState> {
  MinesweeperState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MinesweeperState, MinesweeperState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MinesweeperState, MinesweeperState>,
              MinesweeperState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
