import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puzzle/l10n/app_localizations.dart';
import 'package:puzzle/providers/user_providers.dart';
import 'package:puzzle/utils/design_system.dart';
import 'package:puzzle/utils/haptic_feedback.dart';
import 'package:puzzle/utils/l10n_game_helpers.dart';
import 'package:puzzle/widgets/game_completion_dialog.dart';
import 'package:puzzle/widgets/tangible.dart';
import '../../../core/juice/game_scaffold.dart';
import '../../../../widgets/game_hud.dart';

/// Sentences to scramble. A run scrambles one, so ten sentences was ten
/// rounds; the old ten were also all about typoglycemia itself, which is
/// filler dressed as content -- and one of them cited a study that this app
/// cannot point to.
final List<String> typoglycemiaSentences = [
  'The library opens at nine in the morning and closes at six.',
  'A gentle breeze moved the curtains across the open window.',
  'Fresh bread smells better than anything else in the kitchen.',
  'The train to the coast leaves from the second platform.',
  'She keeps a small notebook in her coat pocket.',
  'Our neighbours painted their front door dark green last spring.',
  'The river runs slowly past the old stone bridge.',
  'He learned to play the guitar during a long winter indoors.',
  'A good map turns a strange city into a friendly one.',
  'The museum is free on the first Sunday of each month.',
  'Two cats slept on the warm tiles beside the kitchen stove.',
  'The recipe needs four eggs, a cup of flour and a pinch of salt.',
  'Thunder rolled over the hills long before the rain arrived.',
  'A narrow path leads from the harbour up to the lighthouse.',
  'The clock in the hallway has been slow for many years.',
  'Bees return to the same flowers every morning in summer.',
  'He wrote the address on the envelope and posted it.',
  'The garden hedge hides a small wooden gate at the back.',
  'Cold water tastes better after a long walk in the sun.',
  'A row of lamps lit the long street all the way to the square.',
  'The bookshop on the corner sells old maps and postcards.',
  'She planted tomatoes along the south wall of the house.',
  'The ferry crosses the bay twice every hour in winter.',
  'A single star appeared above the rooftops before dark.',
  'The children built a long tunnel through the sand.',
  'My grandfather kept every letter he ever received.',
  'The bakery sells out of cinnamon rolls before noon.',
  'Rain had washed the dust from the leaves overnight.',
  'The workshop smells of sawdust, oil and fresh coffee.',
  'Every window in the old house faces the morning sun.',
];

/// Every sentence, so a test can check the pool is prose and not a claim.

class TypoglycemiaDecoderScreen extends ConsumerStatefulWidget {
  const TypoglycemiaDecoderScreen({super.key});

  @override
  ConsumerState<TypoglycemiaDecoderScreen> createState() => _TypoglycemiaDecoderScreenState();
}

class _TypoglycemiaDecoderScreenState extends ConsumerState<TypoglycemiaDecoderScreen> {
  List<String> get _sentencePool => typoglycemiaSentences;

  late String _currentScrambled;
  late List<String> _currentOptions;
  late int _correctAnswerIndex;

  @override
  void initState() {
    super.initState();
    _generatePuzzle();
  }

  void _generatePuzzle() {
    final random = Random();
    final sentence = _sentencePool[random.nextInt(_sentencePool.length)];

    final words = sentence.split(' ');
    final scrambledWords = words.map((word) {
      if (word.length <= 3) return word;
      String cleanWord = word;
      String punctuation = '';
      if (RegExp(r'[.,!?]').hasMatch(word.substring(word.length - 1))) {
        cleanWord = word.substring(0, word.length - 1);
        punctuation = word.substring(word.length - 1);
      }
      if (cleanWord.length <= 3) return word;
      
      final first = cleanWord.substring(0, 1);
      final last = cleanWord.substring(cleanWord.length - 1);
      final middle = cleanWord.substring(1, cleanWord.length - 1).split('');
      middle.shuffle(random);
      return '$first${middle.join()}$last$punctuation';
    }).toList();

    _currentScrambled = scrambledWords.join(' ');

    final d1Words = sentence.split(' ');
    if (d1Words.length > 3) {
      final temp = d1Words[2];
      d1Words[2] = d1Words[3];
      d1Words[3] = temp;
    }
    final d1 = d1Words.join(' ');

    String d2 = sentence
        .replaceAll('research', 'researcher')
        .replaceAll('important', 'impotent')
        .replaceAll('human', 'humor')
        .replaceAll('scrambled', 'screaming')
        .replaceAll('brain', 'brand')
        .replaceAll('puzzles', 'puddles')
        .replaceAll('interactive', 'internet');
    if (d2 == sentence) {
      d2 = '$sentence Extra.';
    }

    String d3 = sentence.replaceAll(' the ', ' that ').replaceAll(' to ', ' too ').replaceAll(' is ', ' was ');
    if (d3 == sentence) {
      d3 = '${sentence.substring(0, sentence.length - 1)}?';
    }

    final allOptions = [sentence, d1, d2, d3];
    allOptions.shuffle(random);

    _correctAnswerIndex = allOptions.indexOf(sentence);
    _currentOptions = allOptions;
  }

  void _onOptionSelected(int index) {
    if (index == _correctAnswerIndex) {
      HapticFeedbackUtil.victory();
      ref.read(gameStreakNotifierProvider.notifier).completeGame('typoglycemia_decoder');
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => GameCompletionDialog(
          title: AppLocalizations.of(context)!.winDecodedCorrectly,
          message: AppLocalizations.of(context)!.winDecodedMessage,
          onPlayAgain: () {
            setState(() {
              _generatePuzzle();
            });
            Navigator.pop(context);
          },
          onHome: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
        ),
      );
    } else {
      HapticFeedbackUtil.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.snackbarIncorrectLookClose),
          duration: Duration(milliseconds: 1500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String scrambled = _currentScrambled;
    final List<String> options = _currentOptions;

    return GameScaffold(
      title: L10nGameHelpers.getGameTitle(context, 'typoglycemia_decoder'),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
                child: GameHud(children: [
                  Text(AppLocalizations.of(context)!.phaseDecodeTheSentence, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
            // Scrambled Text Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: TangibleContainer(
                depth: 3,
                color: DesignSystem.gamePurple,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.phaseDecodeTheSentence.toUpperCase(),
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        scrambled,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Options List
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: ListView.builder(
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _onOptionSelected(index),
                          style: ElevatedButton.styleFrom(
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            options[index],
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.3),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
