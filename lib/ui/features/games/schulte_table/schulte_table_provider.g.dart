// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schulte_table_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SchulteTableNotifier)
final schulteTableProvider = SchulteTableNotifierProvider._();

final class SchulteTableNotifierProvider
    extends $NotifierProvider<SchulteTableNotifier, SchulteTableState> {
  SchulteTableNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'schulteTableProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$schulteTableNotifierHash();

  @$internal
  @override
  SchulteTableNotifier create() => SchulteTableNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SchulteTableState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SchulteTableState>(value),
    );
  }
}

String _$schulteTableNotifierHash() =>
    r'affdc5b94861a5cc33130e4cac73230422218637';

abstract class _$SchulteTableNotifier extends $Notifier<SchulteTableState> {
  SchulteTableState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SchulteTableState, SchulteTableState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SchulteTableState, SchulteTableState>,
              SchulteTableState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
