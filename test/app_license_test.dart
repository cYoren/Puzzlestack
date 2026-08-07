import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/main.dart';

/// GPL-3.0 requires that this modified work carry notice of the modification
/// and preserve attribution to the original. That notice lives only in
/// registerAppLicense(), so guard it: a refactor that drops or empties it
/// would otherwise be a silent licence-compliance regression.
void main() {
  test('app license is registered with GPL terms and upstream attribution',
      () async {
    registerAppLicense();

    final entries = <LicenseEntry>[];
    await for (final entry in LicenseRegistry.licenses) {
      entries.add(entry);
    }

    final ours = entries.where((e) => e.packages.contains('Mindstack'));
    expect(ours, isNotEmpty, reason: 'Mindstack license entry not registered');

    final text = ours.first.paragraphs.map((p) => p.text).join(' ');
    expect(text, contains('GNU General Public License'));
    expect(text, contains('sidhant947/Puzzle'),
        reason: 'upstream attribution required by GPL-3.0 sections 4 and 5');
    expect(text, contains('github.com/cYoren/Mindstack'),
        reason: 'GPL-3.0 requires pointing users at the corresponding source');
  });
}
