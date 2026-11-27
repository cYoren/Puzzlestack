# Triage: Math

Mechanical pass over every game in the room against [PUZZLE-BAR.md](PUZZLE-BAR.md), by
`tool/triage_room.py`. Regenerate with:

```bash
python3 tool/triage_room.py math
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
| Games | 16 | 28 | 9 |

**Origin tags** in this room, which is what the uniqueness column above turns on:

| Origin | Games |
| --- | --- |
| puzzle | 19 |
| worksheet | 34 |

**Check 6 evidence.** `AUDIT_ONLY=<room ids> flutter test test/board/game_audit.dart`,
light and `AUDIT_DARK=1`:

- light: `AUDIT checked=53 overflow=0 threw=0`
- dark: `AUDIT checked=53 overflow=0 threw=0`

## Per game

| Game | Title | Tier | 2 fair | 5 fresh | 6 app | 7 tap | 8 ends | 9 name | 10 rule |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `algebraic_balance` | Algebraic Balance | library | pass-named-unique | pass | audit-clean | pass | pass | pass | pass |
| `angle_finder` | Angle Finder | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `area_perimeter_match` | Area & Perimeter | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `arithmetic_chain` | Chain Calc | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `balance_scale` | Balance Scale | library | unproven | pass | audit-clean | pass | pass | pass | pass |
| `base_shift` | Base Shift | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `binary_code` | Binary Speed | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `binary_matrix_rank` | Matrix Rank | archive | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `binomial_match` | Binomial Match | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `calculation_sprint` | Calculation Sprint | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `collatz` | Collatz Path | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `common_denominator` | Common Denominator | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `countdown_math` | Countdown Math | library | unproven | pass | audit-clean | pass | pass | pass | pass |
| `crypto_arithmetic` | Crypto-Arithmetic | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `digit_swap_eq` | Digit Swap Equations | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `divisibility_dash` | Divisibility Dash | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `exponent_tower` | Exponent Tower | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `factor_finder` | Factor Finder | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `fibonacci_merge` | Fibonacci Merge | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `fraction_match` | Fraction Match | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `fractional_pizza` | Fractional Pizza | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `game_2048` | 2048 | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `graph_coordinate_plot` | Graph Plotter | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `inequality_dash` | Inequality Dash | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `kenken` | KenKen | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `magic_squares` | Magic Square | library | unproven | pass | audit-clean | pass | pass | pass | pass |
| `math_guess` | Math Guess | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `math_maze` | Math Maze | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `math_path` | Math Path | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `matrix_multiplier` | Matrix Multiplier | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `matrix_multiplier_match` | Matrix Matcher | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `mental_abacus` | Mental Abacus | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `mental_calendar` | Mental Calendar | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `missing_operator` | Operator Mix | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `modulo_clock` | Modulo Clock | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `number_bonds` | Number Bonds | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `numerical_estimation` | Numerical Estimation | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `percentage_peak` | Percentage Peak | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `prime_factor_trees` | Prime Factor Trees | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `prime_hunter` | Prime Hunter | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `pythagorean_triple_builder` | Pythagoras | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `quick_math` | Quick Math | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `radical_roots` | Radical Roots | archive | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `roman_arithmetic` | Roman Arithmetic | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `sequence_sleuth` | Sequence Sleuth | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `set_theory_venn` | Venn Sets | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `sum_pyramid` | Sum Pyramid | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `sum_snake` | Sum Snake | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `target_10` | Target 10 | deck | unproven | pass | audit-clean | pass | pass | pass | pass |
| `unit_converter_pro` | Unit Converter | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |
| `vector_dot_product` | Dot Product | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `vektor_vector` | Vector Vector | archive | fair-by-play | pass | audit-clean | pass | pass | pass | fail |
| `venn_numbers` | Venn Numbers | library | fair-by-play | pass | audit-clean | pass | pass | pass | pass |

## What needs a fix job

PUZZLE-BAR.md's working procedure keeps fixes out of the triage PR: each of these is
its own change with its own test. Grouped by the job that fixes it, because the fix is
usually one mechanism and not N edits.

- **`uniqueness` — the generator must prove its deal (check 2)** — 19: `arithmetic_chain`, `balance_scale`, `countdown_math`, `crypto_arithmetic`, `digit_swap_eq`, `fibonacci_merge`, `game_2048`, `kenken`, `magic_squares`, `math_guess`, `math_maze`, `math_path`, `missing_operator`, `number_bonds`, `quick_math`, `sequence_sleuth`, `sum_pyramid`, `sum_snake`, `target_10`
- **`rule-tests` — a test that fails if the content breaks the game (check 10)** — 7: `binomial_match`, `graph_coordinate_plot`, `matrix_multiplier`, `matrix_multiplier_match`, `pythagorean_triple_builder`, `vector_dot_product`, `vektor_vector`

**The `uniqueness` job, in two passes.** A test that shows a generated deal has a
solution does not show it is the only one, but it does mean the deal is not unwinnable:

- winnable, not unique (17): `arithmetic_chain`, `countdown_math`, `crypto_arithmetic`, `digit_swap_eq`, `fibonacci_merge`, `game_2048`, `kenken`, `math_guess`, `math_maze`, `math_path`, `missing_operator`, `number_bonds`, `quick_math`, `sequence_sleuth`, `sum_pyramid`, `sum_snake`, `target_10`

- neither proven (2): `balance_scale`, `magic_squares`

Every game here has a how-to-play guide (`lib/data/game_guides.dart`). The card's
own goal line is still owed to `card-teaches` (check 3), for the room as a whole.

## What the play pass has to answer

44 games. Play five times at phone size, write the first thing that
confused you, then confirm or move the id in `docs/CATALOG.md` with one line of reason:

`algebraic_balance`, `angle_finder`, `area_perimeter_match`, `arithmetic_chain`, `balance_scale`, `base_shift`, `binary_code`, `calculation_sprint`, `collatz`, `common_denominator`, `countdown_math`, `crypto_arithmetic`, `digit_swap_eq`, `divisibility_dash`, `exponent_tower`, `factor_finder`, `fibonacci_merge`, `fraction_match`, `fractional_pizza`, `game_2048`, `inequality_dash`, `kenken`, `magic_squares`, `math_guess`, `math_maze`, `math_path`, `mental_abacus`, `mental_calendar`, `missing_operator`, `modulo_clock`, `number_bonds`, `numerical_estimation`, `percentage_peak`, `prime_factor_trees`, `prime_hunter`, `quick_math`, `roman_arithmetic`, `sequence_sleuth`, `set_theory_venn`, `sum_pyramid`, `sum_snake`, `target_10`, `unit_converter_pro`, `venn_numbers`
