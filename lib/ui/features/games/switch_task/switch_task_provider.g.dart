// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'switch_task_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SwitchTaskNotifier)
final switchTaskProvider = SwitchTaskNotifierProvider._();

final class SwitchTaskNotifierProvider
    extends $NotifierProvider<SwitchTaskNotifier, SwitchTaskState> {
  SwitchTaskNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'switchTaskProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$switchTaskNotifierHash();

  @$internal
  @override
  SwitchTaskNotifier create() => SwitchTaskNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SwitchTaskState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SwitchTaskState>(value),
    );
  }
}

String _$switchTaskNotifierHash() =>
    r'f0b8973cbc7cd97730ccb505d8c3eeb22dbe68cf';

abstract class _$SwitchTaskNotifier extends $Notifier<SwitchTaskState> {
  SwitchTaskState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SwitchTaskState, SwitchTaskState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SwitchTaskState, SwitchTaskState>,
              SwitchTaskState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
