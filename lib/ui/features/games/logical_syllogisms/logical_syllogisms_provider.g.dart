// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logical_syllogisms_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LogicalSyllogismsNotifier)
final logicalSyllogismsProvider = LogicalSyllogismsNotifierProvider._();

final class LogicalSyllogismsNotifierProvider
    extends
        $NotifierProvider<LogicalSyllogismsNotifier, LogicalSyllogismsState> {
  LogicalSyllogismsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'logicalSyllogismsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$logicalSyllogismsNotifierHash();

  @$internal
  @override
  LogicalSyllogismsNotifier create() => LogicalSyllogismsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LogicalSyllogismsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LogicalSyllogismsState>(value),
    );
  }
}

String _$logicalSyllogismsNotifierHash() =>
    r'a47b00c6a58cf19acff67f2380cc8e1d5b241d3d';

abstract class _$LogicalSyllogismsNotifier
    extends $Notifier<LogicalSyllogismsState> {
  LogicalSyllogismsState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<LogicalSyllogismsState, LogicalSyllogismsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LogicalSyllogismsState, LogicalSyllogismsState>,
              LogicalSyllogismsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
