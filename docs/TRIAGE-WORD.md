# Triage: Word

Mechanical pass over every game in the room against [PUZZLE-BAR.md](PUZZLE-BAR.md), by
`tool/triage_room.py`. Regenerate with:

```bash
python3 tool/triage_room.py word
```

**What this is, and is not.** The checks a machine can decide are decided here, from the
code and from a mounted board at 320dp in both themes. The checks that need a person at
the board (1 *there is a decision*, 3 *five-second read* beyond string length, 4 *about a
minute*) are marked `needs-play` and are **not** guesses dressed as verdicts. Nothing in
this file marks a game verified; that is the play pass.

**Check 2, by genre.** `pass` and `pass-named-unique` mean the code has a solver, so the
generator proves its own deal. `pass-fair-not-unique` means the code has a prover that
enumerates the cheaper layouts and proves the deal cannot be won with fewer mirrors than
it demands, while several answers of that size are legal and any of them wins: proved
finishable, not unique. `unproven` means the game generates content and nothing
proves the deal is winnable, or has one answer where the genre implies one:
the `uniqueness` job. `pool-fairness` means a fixed content pool, where the proof is
"every row is solvable", i.e. check 10. `fair-by-play` means a lab task, worksheet or
quiz, whose answer is the task's own and not deduced from clues, so fairness is judged
by playing.

| | Deck | Library | Archive |
| --- | --- | --- | --- |
| Games | 22 | 19 | 2 |

**Origin tags** in this room, which is what the uniqueness column above turns on:

| Origin | Games |
| --- | --- |
| puzzle | 26 |
| quiz | 17 |

**Check 6 evidence.** `AUDIT_ONLY=<room ids> flutter test test/board/game_audit.dart`,
light and `AUDIT_DARK=1`:

- light: `AUDIT checked=43 overflow=0 threw=0`
- dark: `AUDIT checked=43 overflow=0 threw=0`

## Per game

| Game | Title | Tier | 2 fair | 5 fresh | 6 app | 7 tap | 8 ends | 9 name | 10 rule |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `affix_factory` | Affix Factory | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `anagram_definition` | Anagram Definition | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `category_fluency` | Category Fluency | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `chain_reaction` | Chain Reaction | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `cognate_catch` | Cognate Catch | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `compound_connect` | Compound Connect | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `context_clues` | Context Clues | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `conundrum_anagram` | Conundrum | library | unproven | pass | audit-clean | pass | pass | pass | pass |
| `crossword` | Crossword | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `cryptogram` | Cryptogram | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `definition_dash` | Definition Dash | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `etymology_origin` | Etymology Origin | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `find_word` | Find Word | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `grammar_police` | Grammar Police | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `homophone_hunt` | Homophone Hunt | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `letter_bridge` | Letter Bridge | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `letter_frequency_scan` | Letter Frequency Scan | archive | unproven | pass | audit-clean | pass | pass | pass | pass |
| `letter_grid_swapper` | Letter Swapper | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `missing_vowels` | Missing Vowels | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `one_letter_shift` | One-Letter Shift | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `oxymoron_hunt` | Oxymoron Hunt | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `palindrome_builder` | Palindrome Builder | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `pangram_sprint` | Pangram Sprint | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `phonetic_guess` | Phonetic Guess | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `portmanteau_split` | Portmanteau Split | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `rhyme_master` | Rhyme Master | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `semantic_link` | Semantic Link | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `sentence_unscramble` | Sentence Unscramble | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `silent_letter_search` | Silent Letter Search | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `spelling_sprint` | Spelling Sprint | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `spoonerism_solver` | Spoonerism Solver | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `syllable_stack` | Syllable Stack | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `typing_speed` | Typing Speed | archive | unproven | pass | audit-clean | pass | pass | pass | pass |
| `typoglycemia_decoder` | Typoglycemia Decoder | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `verbal_analogies` | Verbal Analogies | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `word_grid_connection` | Word Connections | library | unproven | pass | audit-clean | pass | pass | pass | pass |
| `word_ladder` | Word Ladder | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `word_mastermind` | Word Mastermind | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `word_scramble` | Word Scramble | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `word_search` | Word Search | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `word_snake_trail` | Word Snake | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `word_surge` | Word Surge | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `word_wheel` | Word Wheel | deck | unproven | pass | audit-clean | pass | pass | pass | pass |

## What needs a fix job

PUZZLE-BAR.md's working procedure keeps fixes out of the triage PR: each of these is
its own change with its own test. Grouped by the job that fixes it, because the fix is
usually one mechanism and not N edits.

- **`uniqueness` — the generator must prove its deal (check 2)** — 26: `chain_reaction`, `compound_connect`, `conundrum_anagram`, `crossword`, `cryptogram`, `find_word`, `homophone_hunt`, `letter_bridge`, `letter_frequency_scan`, `letter_grid_swapper`, `missing_vowels`, `one_letter_shift`, `pangram_sprint`, `portmanteau_split`, `rhyme_master`, `sentence_unscramble`, `spoonerism_solver`, `typing_speed`, `verbal_analogies`, `word_grid_connection`, `word_ladder`, `word_mastermind`, `word_scramble`, `word_search`, `word_snake_trail`, `word_wheel`

**The `uniqueness` job, in two passes.** A test that shows a generated deal has a
solution does not show it is the only one, but it does mean the deal is not unwinnable:

- winnable, not unique (23): `chain_reaction`, `compound_connect`, `conundrum_anagram`, `crossword`, `cryptogram`, `find_word`, `homophone_hunt`, `letter_bridge`, `letter_grid_swapper`, `missing_vowels`, `one_letter_shift`, `pangram_sprint`, `portmanteau_split`, `rhyme_master`, `sentence_unscramble`, `spoonerism_solver`, `verbal_analogies`, `word_ladder`, `word_mastermind`, `word_scramble`, `word_search`, `word_snake_trail`, `word_wheel`

- neither proven (3): `letter_frequency_scan`, `typing_speed`, `word_grid_connection`

Every game here has a how-to-play guide (`lib/data/game_guides.dart`). The card's
own goal line is still owed to `card-teaches` (check 3), for the room as a whole.

## What the play pass has to answer

41 games. Play five times at phone size, write the first thing that
confused you, then confirm or move the id in `docs/CATALOG.md` with one line of reason:

`affix_factory`, `anagram_definition`, `category_fluency`, `chain_reaction`, `cognate_catch`, `compound_connect`, `context_clues`, `conundrum_anagram`, `crossword`, `cryptogram`, `definition_dash`, `etymology_origin`, `find_word`, `grammar_police`, `homophone_hunt`, `letter_bridge`, `letter_grid_swapper`, `missing_vowels`, `one_letter_shift`, `oxymoron_hunt`, `palindrome_builder`, `pangram_sprint`, `phonetic_guess`, `portmanteau_split`, `rhyme_master`, `semantic_link`, `sentence_unscramble`, `silent_letter_search`, `spelling_sprint`, `spoonerism_solver`, `syllable_stack`, `typoglycemia_decoder`, `verbal_analogies`, `word_grid_connection`, `word_ladder`, `word_mastermind`, `word_scramble`, `word_search`, `word_snake_trail`, `word_surge`, `word_wheel`
