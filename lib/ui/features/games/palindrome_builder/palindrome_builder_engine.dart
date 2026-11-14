import 'dart:math';

class PalindromeBuilderEngine {
  /// A palindrome with a hole in it. A run draws one, so thirteen tasks was the
  /// whole game: fill in the gap and the word reads the same both ways.
  final List<PalindromeTask> _tasks = [
    PalindromeTask(incomplete: 'E_E', solution: 'Y', display: 'E.E'),
    PalindromeTask(incomplete: 'M_M', solution: 'O', display: 'M.M'),
    PalindromeTask(incomplete: 'D_D', solution: 'A', display: 'D.D'),
    PalindromeTask(incomplete: 'P_P', solution: 'O', display: 'P.P'),
    PalindromeTask(incomplete: 'B_B', solution: 'O', display: 'B.B'),
    PalindromeTask(incomplete: 'N_N', solution: 'U', display: 'N.N'),
    PalindromeTask(incomplete: 'P_P', solution: 'U', display: 'P.P'),
    PalindromeTask(incomplete: 'T_T', solution: 'O', display: 'T.T'),
    PalindromeTask(incomplete: 'W_W', solution: 'O', display: 'W.W'),
    PalindromeTask(incomplete: 'PE__', solution: 'EP', display: 'PE..'),
    PalindromeTask(incomplete: 'DE__', solution: 'ED', display: 'DE..'),
    PalindromeTask(incomplete: 'NO__', solution: 'ON', display: 'NO..'),
    PalindromeTask(incomplete: 'C___C', solution: 'IVI', display: 'C...C'),
    PalindromeTask(incomplete: 'R___R', solution: 'ADA', display: 'R...R'),
    PalindromeTask(incomplete: 'L___L', solution: 'EVE', display: 'L...L'),
    PalindromeTask(incomplete: 'M___M', solution: 'ADA', display: 'M...M'),
    PalindromeTask(incomplete: 'K___K', solution: 'AYA', display: 'K...K'),
    PalindromeTask(incomplete: 'R___R', solution: 'OTO', display: 'R...R'),
    PalindromeTask(incomplete: 'R___R', solution: 'EFE', display: 'R...R'),
    PalindromeTask(incomplete: 'M___M', solution: 'INI', display: 'M...M'),
    PalindromeTask(incomplete: 'RE___R', solution: 'DDE', display: 'RE...R'),
    PalindromeTask(incomplete: 'S___S', solution: 'AGA', display: 'S...S'),
    PalindromeTask(incomplete: 'S___S', solution: 'TAT', display: 'S...S'),
    PalindromeTask(incomplete: 'DE____D', solution: 'IFIE', display: 'DE....D'),
    PalindromeTask(incomplete: 'RE____R', solution: 'VIVE', display: 'RE....R'),
    PalindromeTask(incomplete: 'RA____R', solution: 'CECA', display: 'RA....R'),
    PalindromeTask(incomplete: 'S___S', solution: 'OLO', display: 'S...S'),
    PalindromeTask(incomplete: 'T___T', solution: 'ENE', display: 'T...T'),
    PalindromeTask(incomplete: 'RO____R', solution: 'TATO', display: 'RO....R'),
  ];

  /// Every task, so a test can fill the gap and check the answer really reads
  /// the same in both directions.
  List<PalindromeTask> get tasks => List.unmodifiable(_tasks);

  PalindromeTask getRandomTask() {
    return _tasks[Random().nextInt(_tasks.length)];
  }

  bool checkSolution(String guess, String solution) {
    return guess.trim().toUpperCase() == solution.toUpperCase();
  }
}

class PalindromeTask {
  final String incomplete;
  final String solution;
  final String display;
  final String? balance;

  PalindromeTask({
    required this.incomplete,
    required this.solution,
    required this.display,
    this.balance,
  });
}
