#!/usr/bin/env python3
"""Triage one room against PUZZLE-BAR.md, from the code, and write the report.

What this can decide, it decides. What needs a person at the board, it marks
`needs-play` rather than guessing, because PUZZLE-BAR.md's working procedure starts with
"play it five times on a phone-sized window" and nothing here can do that.

    python3 tool/triage_room.py logic            # -> docs/TRIAGE-LOGIC.md

Checks that are mechanical here:

- **6 it is this app**: a mounted board at 320dp, light and dark, with no overflow and no
  thrown exception. That evidence comes from `test/board/game_audit.dart`; this script runs
  it with this room's ids (`AUDIT_ONLY=...`) and pastes in what it prints, once per theme.
- **9 honest name**: the title and subtitle a stranger reads, checked against the lab
  vocabulary the bar lists as slop.
- **10 tested against its own rule**: a test file for the game that asserts something
  about how it plays, not just that it renders.
- **3 the card teaches itself**: whether the game has a guide at all. It reads
  `lib/data/game_guides.dart`, the one file the app reads and `test/content/registry_test.dart`
  keeps complete. (This check used to read the localized metadata instead and reported every
  game without an `xHowToPlay` key as guideless, which was wrong for all of them.)
- **2 fair**, by genre, because "one answer" is only the right question in a deduction game:
  - `pass` / `pass-named-unique`: the code has a solver, so the generator proves its deal.
  - `unproven`: the game generates its content and nothing proves the deal is winnable (or
    has one answer, where the genre implies one). That is the `uniqueness` job, and the report
    splits it into games whose tests at least show a solution exists and games where nothing is
    proven at all.
  - `pool-fairness`: a fixed content pool, where the proof is "every row is solvable", i.e.
    check 10, not a generator.
  - `fair-by-play`: a lab task, worksheet or quiz, read from the origin tag in
    `lib/data/game_profiles.dart`. Its answer is the task's own, not deduced from clues on the
    screen, so a uniqueness proof does not apply and fairness is judged by playing. This is
    where every Memory and Attention card lands.
- **5 stays fresh**: a generator, or a pool big enough for 30 sessions.
- **8 ends well**: undo and restart exist.
- **7 tap alone**: a board whose only interaction is a drag fails; one with a tap does not.

One more thing the parser does: the room's Deck and Library counts are read from the catalog's
`deck` and `library` blocks only. A `merge` line names a keeper that is already in one of them,
so counting it again used to inflate the Deck by the number of merges in the room.

Checks 1, 3 and 4 (a decision, a five-second read, about a minute) are the ones a person
answers by playing, and they stay `needs-play` in the report.
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
ROOMS = {
    "logic": ("LOGIC", "Logic"),
    "math": ("MATH", "Math"),
    "memory": ("MEMORY", "Memory"),
    "attention": ("ATTENTION", "Attention"),
    "word": ("WORD", "Word"),
    "spatial": ("SPATIAL", "Spatial"),
}

# Words the bar names as slop in a title: a term only a psychologist uses.
LAB_WORDS = {
    "n-back",
    "nback",
    "stroop",
    "wisconsin",
    "corsi",
    "sdmt",
    "posner",
    "sternberg",
    "flanker",
    "navon",
    "subitizing",
    "dichotic",
    "go/no-go",
    "priming",
    "span",
    "paradigm",
    "task",
}

DRAG = re.compile(r"onPan(Update|Start|End)|onHorizontalDrag\w*|onVerticalDrag\w*|onScaleUpdate")
TAP = re.compile(r"onTap|onTapDown|GestureDetector|InkWell")
# A generator that can prove its answer, rather than a game that merely has a solved state.
DEDUCTION = re.compile(r"core/deduction\.dart")
# Names a generator uses when it proves its own answer, discovered by reading the engines:
# `_countSolutions(puzzle) == 1`, `hasUniqueSolution`, `solutionCount`, `countSolutions`.
UNIQUE = re.compile(
    r"countSolutions|solutionCount|hasUniqueSolution|uniqueSolution|isUnique|"
    r"generateUnique|solveUnique|_isUnique|oneSolution|solutions\.length == 1|"
    # Not a uniqueness proof: a proof that the deal is finishable by deduction, which is what
    # a solitaire game like minesweeper needs (`isSolvableWithoutGuess`).
    r"isSolvableWithoutGuess|solvableWithoutGuess"
)
# Chrome the shared scaffold provides, so a screen does not repeat it.
SCAFFOLD = re.compile(r"GameScaffold\(")
# Where a game's origin tag lives. Generated from CATALOG.md, so it costs one parse.
PROFILE = re.compile(
    r"^\s+'([a-z0-9_]+)': GameProfile\(tier: GameTier\.(\w+), kind: CardKind\.(\w+), "
    r"origin: GameOrigin\.(\w+)",
    re.M,
)
# The app's guides, one per registry id, kept complete by test/content/registry_test.dart.
GUIDES = re.compile(r'^\s+"([a-z0-9_]+)": GameGuide\(', re.M)

# Origins whose fairness is judged by playing, not by a proof: a cognitive task, a drill and
# a quiz all have an answer that is theirs, not one the player deduces from clues.
PLAY_JUDGED = {"lab", "worksheet", "quiz"}


def parse_room(room_line: str) -> dict[str, list[str]]:
    """The four lists of one room, straight out of CATALOG.md."""
    text = (REPO / "docs" / "CATALOG.md").read_text()
    header = re.search(rf"^## {room_line} \(\d+\)$", text, re.M)
    if header is None:
        raise SystemExit(f"no room {room_line} in docs/CATALOG.md")
    body = text[header.end():]
    nxt = re.search(r"^## ", body, re.M)
    if nxt:
        body = body[: nxt.start()]

    out: dict[str, list[str]] = {"deck": [], "library": [], "merge": [], "archive": []}
    for kind, block in re.findall(r"```(deck|library|merge|archive)\n(.*?)```", body, re.S):
        if kind == "merge":
            # A keeper is already listed under `deck` or `library`; the merge line only says
            # which ids it absorbed. Appending it here used to inflate the Deck count.
            for line in block.strip().splitlines():
                keeper, absorbed = line.split("<-")
                out["merge"].append(keeper.strip() + " <- " + absorbed.strip())
            continue
        out[kind] += [w for w in block.split() if re.fullmatch(r"[a-z0-9_]+", w)]
    return out


def arb_strings() -> dict[str, str]:
    path = REPO / "lib" / "l10n" / "app_en.arb"
    return json.loads(path.read_text())


def origins() -> dict[str, str]:
    """game id -> origin tag, from the generated profile map."""
    text = (REPO / "lib" / "data" / "game_profiles.dart").read_text()
    return {m[0]: m[3] for m in PROFILE.findall(text)}


def guided() -> set[str]:
    """Every game with a how-to-play guide in the app."""
    text = (REPO / "lib" / "data" / "game_guides.dart").read_text()
    return {m for m in GUIDES.findall(text)}


def test_files(game_id: str) -> list[Path]:
    out = []
    for big in (REPO / "test").rglob("*.dart"):
        if game_id in big.name or game_id in big.read_text(errors="ignore"):
            out.append(big.relative_to(REPO))
    return out


def rule_test(game_id: str) -> Path | None:
    """A test named after the game that asserts how it plays, not just that it renders."""
    skip = {"game_audit.dart", "screen_test.dart", "new_games_screen_test.dart"}
    for path in test_files(game_id):
        if path.name in skip:
            continue
        named = game_id in path.stem
        text = path.read_text(errors="ignore")
        asserts_play = re.search(
            r"unique|solv|generat|valid|winnable|expect\(.*(count|length|length)", text
        )
        if named and asserts_play:
            return path
    return None


# A test that proves a generated deal has a solution. It does not prove the answer is the only
# one, which is a separate sentence in the report.
SOLVED_TEST = re.compile(
    r"checkVictory|isSolved|isWin|winnable|solvable|hasSolution|valid solution", re.I
)


def winnable_tested(game_id: str) -> bool:
    """Does any test of this game assert that a generated deal has a solution?"""
    skip = {"game_audit.dart", "screen_test.dart", "new_games_screen_test.dart"}
    for path in test_files(game_id):
        if path.name in skip:
            continue
        if SOLVED_TEST.search(path.read_text(errors="ignore")):
            return True
    return False


def triage(room_key: str, audit_clean: bool = True) -> dict:
    category, room_name = ROOMS[room_key]
    lists = parse_room(room_name)
    arb = arb_strings()
    origin_of = origins()
    has_guide = guided()
    games: dict[str, dict] = {}

    for tier, ids in lists.items():
        if tier == "merge":
            continue
        for game_id in ids:
            if game_id in games:
                continue
            directory = REPO / "lib" / "ui" / "features" / "games" / game_id
            own = sorted(directory.glob("*.dart")) if directory.exists() else []
            source = "\n".join(p.read_text(errors="ignore") for p in own)
            # A generator or a solver usually lives one import away from the screen.
            for path in list(own):
                for name in re.findall(
                    r"import '([^']+)'", path.read_text(errors="ignore")
                ):
                    resolved = (path.parent / name).resolve()
                    if resolved.exists() and resolved.is_relative_to(REPO / "lib"):
                        source += "\n" + resolved.read_text(errors="ignore")
            meta = directory / f"{game_id}_metadata.dart"
            meta_text = meta.read_text(errors="ignore") if meta.exists() else ""
            keys = re.findall(r"AppLocalizations\.of\(context\)!\.(\w+)", meta_text)
            title = next(
                (arb[k] for k in keys if k.endswith("Title")),
                arb.get(f"{game_id}Title", ""),
            )
            subtitle = next(
                (arb[k] for k in keys if k.endswith("Subtitle")),
                arb.get(f"{game_id}Subtitle", ""),
            )
            guide = game_id in has_guide
            origin = origin_of.get(game_id, "puzzle")

            checks: dict[str, str] = {}
            checks["1 decision"] = "needs-play"
            if DEDUCTION.search(source):
                checks["2 fair"] = "pass"
            elif UNIQUE.search(source):
                checks["2 fair"] = "pass-named-unique"
            elif origin in PLAY_JUDGED:
                # A lab task, a worksheet or a quiz has no answer to deduce: the uniqueness
                # clause of check 2 is about genres where the screen implies one answer.
                checks["2 fair"] = "fair-by-play"
            elif re.search(r"Random\(|generate", source):
                checks["2 fair"] = "unproven"
            else:
                checks["2 fair"] = "pool-fairness"
            # Check 3 is about the goal line on the card, and no game has one yet
            # (`card-teaches` writes them). A missing goal line is not this game's fault,
            # so it is not a failure here; a missing guide is.
            checks["3 goal line"] = "needs-goal-line" if guide else "no-guide"
            checks["4 about a minute"] = "needs-play"
            checks["5 stays fresh"] = (
                "pass" if ("Random(" in source or "generate" in source) else "check-pool"
            )
            checks["6 this app"] = "audit-clean" if audit_clean else "audit-failed"
            slop = sorted(w for w in LAB_WORDS if w in f"{title} {subtitle}".lower())
            shouting = title.isupper() or subtitle.isupper()
            checks["9 honest name"] = (
                "fail" if slop else "shouting" if shouting else "pass"
            )
            rule = rule_test(game_id)
            checks["10 own rule"] = "pass" if rule else "fail"
            drags = bool(DRAG.search(source))
            taps = bool(TAP.search(source))
            checks["7 tap alone"] = "fail" if drags and not taps else "pass"
            has_undo = bool(re.search(r"\bundo\b", source, re.I))
            has_restart = bool(re.search(r"restart|reset", source, re.I))
            shared = bool(SCAFFOLD.search(source))
            if (has_undo and has_restart) or (shared and has_restart):
                checks["8 ends well"] = "pass"
            elif shared:
                # Restart comes from the scaffold's app bar; undo is the game's own.
                checks["8 ends well"] = "needs-play"
            else:
                checks["8 ends well"] = "fail"

            games[game_id] = {
                "tier": "deck" if game_id in lists["deck"] else tier,
                "title": title,
                "subtitle": subtitle,
                "origin": origin,
                "checks": checks,
                "slop": slop,
                "rule_test": str(rule) if rule else None,
                "winnable_tested": winnable_tested(game_id),
                "tests": [str(p) for p in test_files(game_id)],
            }

    return {"room": room_name, "category": category, "games": games}


def render(report: dict, audit_numbers: dict[str, str]) -> str:
    room = report["room"]
    games = report["games"]
    order = ["deck", "library", "archive"]
    counts = {t: sum(1 for g in games.values() if g["tier"] == t) for t in order}

    lines = [
        f"# Triage: {room}",
        "",
        "Mechanical pass over every game in the room against [PUZZLE-BAR.md](PUZZLE-BAR.md), by",
        "`tool/triage_room.py`. Regenerate with:",
        "",
        "```bash",
        f"python3 tool/triage_room.py {room.lower()}",
        "```",
        "",
        "**What this is, and is not.** The checks a machine can decide are decided here, from the",
        "code and from a mounted board at 320dp in both themes. The checks that need a person at",
        "the board (1 *there is a decision*, 3 *five-second read* beyond string length, 4 *about a",
        "minute*) are marked `needs-play` and are **not** guesses dressed as verdicts. Nothing in",
        "this file marks a game verified; that is the play pass.",
        "",
        "**Check 2, by genre.** `pass` and `pass-named-unique` mean the code has a solver, so the",
        "generator proves its own deal. `unproven` means the game generates content and nothing",
        "proves the deal is winnable, or has one answer where the genre implies one:\n"
        "the `uniqueness` job. `pool-fairness` means a fixed content pool, where the proof is",
        "\"every row is solvable\", i.e. check 10. `fair-by-play` means a lab task, worksheet or",
        "quiz, whose answer is the task's own and not deduced from clues, so fairness is judged",
        "by playing.",
        "",
        f"| | Deck | Library | Archive |",
        "| --- | --- | --- | --- |",
        f"| Games | {counts['deck']} | {counts['library']} | {counts['archive']} |",
        "",
        "**Origin tags** in this room, which is what the uniqueness column above turns on:",
        "",
        "| Origin | Games |",
        "| --- | --- |",
    ]
    for origin in ("puzzle", "lab", "worksheet", "quiz"):
        n = sum(1 for g in games.values() if g["origin"] == origin)
        if n:
            lines.append(f"| {origin} | {n} |")
    lines += [""]
    lines += [
        "**Check 6 evidence.** `AUDIT_ONLY=<room ids> flutter test test/board/game_audit.dart`,",
        "light and `AUDIT_DARK=1`:",
        "",
    ]
    for mode, value in audit_numbers.items():
        lines.append(f"- {mode}: `{value}`")
    lines += [
        "",
        "## Per game",
        "",
        "| Game | Title | Tier | 2 fair | 5 fresh | 6 app | 7 tap | 8 ends | 9 name | 10 rule |",
        "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    for game_id in sorted(games):
        g = games[game_id]
        c = g["checks"]
        lines.append(
            f"| `{game_id}` | {g['title'] or '?'} | {g['tier']} | {c['2 fair']} | "
            f"{c['5 stays fresh']} | {c['6 this app']} | {c['7 tap alone']} | "
            f"{c['8 ends well']} | {c['9 honest name']} | {c['10 own rule']} |"
        )

    failures = {
        game_id: {
            k: v
            for k, v in g["checks"].items()
            if v
            not in {
                "pass",
                "pass-named-unique",
                "needs-play",
                "needs-goal-line",
                "fair-by-play",
                "audit-clean",
            }
        }
        for game_id, g in games.items()
    }
    failures = {k: v for k, v in failures.items() if v}

    # Every mechanical failure already has an owner in ROADMAP.md. The report routes them
    # rather than inventing a job per game, because the fix is usually one mechanism.
    routes = {
        "unproven": "`uniqueness` — the generator must prove its deal (check 2)",
        "pool-fairness": "`rule-tests` — every pool row is solvable (check 2 and 10)",
        "shouting": "`plain-names` — sentence case titles (check 9)",
        "fail": "see the column",
        "check-pool": "`feed-size` / pool size (check 5)",
        "no-guide": "`card-teaches` — the guide behind `?` (check 3)",
        "audit-failed": "`layout-320` (check 6)",
        "partial": "`card-result` — undo and restart (check 8)",
    }

    by_job: dict[str, list[str]] = {}
    lines += ["", "## What needs a fix job", ""]
    if not failures:
        lines.append("Nothing mechanical failed. The play pass is what remains.")
    else:
        for game_id, checks in sorted(failures.items()):
            for check, value in checks.items():
                job = routes.get(value, value)
                if check == "10 own rule":
                    job = "`rule-tests` — a test that fails if the content breaks the game (check 10)"
                elif check == "2 fair":
                    job = routes.get(value, "check 2")
                elif check == "9 honest name":
                    job = "`plain-names` — sentence case, no lab vocabulary (check 9)"
                elif check == "3 goal line":
                    job = "`card-teaches` — goal line and guide (check 3)"
                by_job.setdefault(job, []).append(game_id)

        lines += [
            "PUZZLE-BAR.md's working procedure keeps fixes out of the triage PR: each of these is",
            "its own change with its own test. Grouped by the job that fixes it, because the fix is",
            "usually one mechanism and not N edits.",
            "",
        ]
        for job, ids in sorted(by_job.items(), key=lambda kv: -len(kv[1])):
            unique = sorted(set(ids))
            lines.append(f"- **{job}** — {len(unique)}: " + ", ".join(f"`{i}`" for i in unique))

    unproven = sorted(
        game_id
        for game_id, g in games.items()
        if g["checks"]["2 fair"] == "unproven"
    )
    if unproven:
        proven = [g for g in unproven if games[g]["winnable_tested"]]
        neither = [g for g in unproven if not games[g]["winnable_tested"]]
        lines += [
            "",
            "**The `uniqueness` job, in two passes.** A test that shows a generated deal has a",
            "solution does not show it is the only one, but it does mean the deal is not unwinnable:",
            "",
            f"- winnable, not unique ({len(proven)}): " + ", ".join(f"`{g}`" for g in proven or ["none"]),
            "",
            f"- neither proven ({len(neither)}): " + ", ".join(f"`{g}`" for g in neither or ["none"]),
        ]

    # Check 3's remaining work is the card's own goal line, which is a card-teaches job and
    # not a per-game defect; say so where the reader looks for the room's worklist.
    if by_job and not any("card-teaches" in job for job in by_job):
        lines += [
            "",
            "Every game here has a how-to-play guide (`lib/data/game_guides.dart`). The card's",
            "own goal line is still owed to `card-teaches` (check 3), for the room as a whole.",
        ]

    needs_play = sorted(
        game_id
        for game_id, g in games.items()
        if g["tier"] != "archive" and "needs-play" in g["checks"].values()
    )
    lines += [
        "",
        "## What the play pass has to answer",
        "",
        f"{len(needs_play)} games. Play five times at phone size, write the first thing that",
        "confused you, then confirm or move the id in `docs/CATALOG.md` with one line of reason:",
        "",
        ", ".join(f"`{g}`" for g in needs_play),
        "",
    ]
    return "\n".join(lines)


def run_audit(report: dict) -> dict:
    """Mount this room's cards and return the audit line for each theme.

    It used to read `/tmp/audit_light.log`, which meant every room's evidence
    section claimed whatever the last whole-catalogue sweep had printed - 52
    cards, in all six rooms. Evidence that is copied is not evidence.
    """
    ids = ",".join(sorted(report["games"]))
    lines = {}
    clean = True
    for mode, env_extra in (
        # The light pass sets the variable rather than leaving it out: a shell
        # that already exports AUDIT_DARK=1 would otherwise make both passes dark
        # and the report claim two.
        ("light", {"AUDIT_DARK": "0"}),
        ("dark", {"AUDIT_DARK": "1"}),
    ):
        env = {**os.environ, "TMPDIR": str(Path.home() / ".cache" / "tmp"),
               "AUDIT_ONLY": ids, **env_extra}
        try:
            done = subprocess.run(
                ["flutter", "test", "test/board/game_audit.dart"],
                cwd=REPO, env=env, capture_output=True, text=True, timeout=1200,
            )
        except (OSError, subprocess.SubprocessError) as error:
            lines[mode] = f"audit did not run: {error}"
            continue
        found = re.search(r"^AUDIT checked=.*$", done.stdout, re.M)
        # `checked=` must be the number of cards asked for, or the sweep skipped
        # something and its zero means nothing.
        asked = len(ids.split(","))
        covered = found and re.search(r"checked=(\d+)", found.group(0))
        if done.returncode == 0 and covered and int(covered.group(1)) == asked:
            lines[mode] = found.group(0)
            continue
        # A sweep that did not pass must not be published as if it had: the whole
        # point of running it per room is that the number is about this room.
        clean = False
        lines[mode] = (
            found.group(0) + " (audit failed)"
            if found
            else f"audit failed (exit {done.returncode}, no summary)"
        )
    return lines, clean


def main() -> int:
    room_key = (sys.argv[1] if len(sys.argv) > 1 else "logic").lower()
    if room_key not in ROOMS:
        raise SystemExit(f"rooms: {', '.join(ROOMS)}")
    # Ids first, then the sweep, then the verdicts: a room whose cards overflow
    # must not render "audit-clean" for every card, which is what happens when the
    # verdicts are decided before the audit runs.
    probe = triage(room_key, audit_clean=False)
    audit, clean = run_audit(probe)
    report = triage(room_key, audit_clean=clean)
    out = REPO / "docs" / f"TRIAGE-{report['room'].upper()}.md"
    out.write_text(render(report, audit))
    print(f"wrote {out.relative_to(REPO)}")
    if not clean:
        print("check 6 FAILED: see the evidence section", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
