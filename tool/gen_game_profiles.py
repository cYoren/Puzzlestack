#!/usr/bin/env python3
"""Generate lib/data/game_profiles.dart from docs/CATALOG.md.

CATALOG.md is the verdict: every registry id sits in exactly one list per room. This script
reads those lists and emits the code copy the app actually uses, so the doc stays the place a
person edits and the app cannot drift from it. `test/content/game_profiles_test.dart` parses the
doc again and fails if the two disagree, which is what keeps "generated" honest.

Run it with the repo root as the working directory:

    python3 tool/gen_game_profiles.py
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
CATALOG = REPO / "docs" / "CATALOG.md"
OUT = REPO / "lib" / "data" / "game_profiles.dart"

ROOMS = {
    "Logic": "LOGIC",
    "Math": "MATH",
    "Memory": "MEMORY",
    "Attention": "ATTENTION",
    "Word": "WORD",
    "Spatial": "SPATIAL",
}

# CS in these rooms is a cognitive-psychology task under a lab name, so the origin tag defaults
# to `lab`. CATALOG.md states these defaults; triage corrects individual rows with a note.
LAB_ROOMS = {"MEMORY", "ATTENTION"}

# Where the catalog overrides its own defaults: an archive entry with a reason other than
# `no-game`. Keep this list short and say why, because each line is a claim about a game.
ARCHIVE_REASONS = {
    # "a listening game without sound is not a game" -- CATALOG.md, Attention notes.
    "chalk_and_talk": "brokenConcept",
}


def parse_catalog(text: str) -> dict[str, dict[str, str]]:
    """id -> {room, tier, family, reason}."""
    games: dict[str, dict[str, str]] = {}
    room = None
    for line in text.splitlines():
        header = re.match(r"^## (Logic|Math|Memory|Attention|Word|Spatial) \(\d+\)", line)
        if header:
            room = ROOMS[header.group(1)]
            continue
        if room is None:
            continue
        fence = re.match(r"^```(deck|library|merge|archive)$", line.strip())
        if not fence:
            continue
        block = fence.group(1)
        # Read the block body: every id until the closing fence.
        continue

    # Second pass, because blocks need their body.
    room = None
    block = None
    for raw in text.splitlines():
        line = raw.strip()
        header = re.match(r"^## (Logic|Math|Memory|Attention|Word|Spatial) \(\d+\)", raw)
        if header:
            room = ROOMS[header.group(1)]
            block = None
            continue
        if room is None:
            continue
        opening = re.match(r"^```(deck|library|merge|archive)$", line)
        if opening:
            block = opening.group(1)
            continue
        if line == "```":
            block = None
            continue
        if block is None or not line or line.startswith("#"):
            continue

        if block == "merge":
            keeper, absorbed = line.split("<-")
            keeper = keeper.strip()
            for other in absorbed.split():
                other = other.strip()
                if not other:
                    continue
                games[other] = {
                    "room": room,
                    "tier": "archive",
                    "family": keeper,
                    "reason": "twin",
                }
            continue

        for word in line.split():
            game_id = word.strip()
            if not re.fullmatch(r"[a-z0-9_]+", game_id):
                continue
            entry = games.setdefault(
                game_id,
                {"room": room, "tier": block, "family": "", "reason": ""},
            )
            entry["tier"] = block

    for game_id, entry in games.items():
        if entry["tier"] != "archive":
            continue
        # A twin is archived because a keeper absorbed it. Some rooms list the absorbed game
        # in the archive block as well, so the merge is what decides the reason, not the block
        # order; an explicit note still wins.
        entry["reason"] = ARCHIVE_REASONS.get(
            game_id, "twin" if entry["family"] else "noGame"
        )
    return games


def origin_for(entry: dict[str, str]) -> str:
    room, tier = entry["room"], entry["tier"]
    if room in LAB_ROOMS:
        return "lab"
    if room == "MATH" and tier in {"library", "archive"}:
        return "worksheet"
    if room == "WORD" and tier == "library":
        return "quiz"
    return "puzzle"


def kind_for(entry: dict[str, str]) -> str:
    room = entry["room"]
    if room == "WORD":
        return "word"
    if room in LAB_ROOMS:
        return "snap"
    return "think"


def main() -> int:
    text = CATALOG.read_text()
    games = parse_catalog(text)
    if not games:
        print("parsed no games from docs/CATALOG.md", file=sys.stderr)
        return 1

    tiers = {}
    for entry in games.values():
        tiers[entry["tier"]] = tiers.get(entry["tier"], 0) + 1

    lines = [
        "// GENERATED FILE -- do not edit by hand.",
        "//",
        "// One tier, kind, origin and family per game, read from docs/CATALOG.md by",
        "// tool/gen_game_profiles.py. Edit the catalog, run the script, commit both.",
        "// test/content/game_profiles_test.dart parses the markdown again and fails if",
        "// this file and the document disagree.",
        "",
        "import 'game_metadata.dart';",
        "",
        "/// Which surface a game appears on.",
        "enum GameTier {",
        "  /// The deal, the Daily Five and the Library: passes all ten checks.",
        "  deck,",
        "  /// Its room and search only: passes the Library floor.",
        "  library,",
        "  /// Nowhere in the app. Hidden, tagged, still in the repo as material.",
        "  archive,",
        "}",
        "",
        "/// What kind of card a game makes, for the rhythm of the deal.",
        "enum CardKind { think, word, snap }",
        "",
        "/// Where a game came from. A lab task and a worksheet can be a good card, but they",
        "/// are tagged so they can be found in one query.",
        "enum GameOrigin { puzzle, lab, worksheet, quiz }",
        "",
        "/// Why a game is archived.",
        "enum ArchiveReason {",
        "  /// Absorbed by a keeper that does the same thing better.",
        "  twin,",
        "  /// There is no decision in it to make.",
        "  noGame,",
        "  /// It cannot work in this app as it stands (for example it needs audio).",
        "  brokenConcept,",
        "}",
        "",
        "/// Everything the app needs to know about one game that is not the game itself.",
        "class GameProfile {",
        "  const GameProfile({",
        "    required this.tier,",
        "    required this.kind,",
        "    required this.origin,",
        "    this.family,",
        "    this.reason,",
        "  });",
        "",
        "  final GameTier tier;",
        "  final CardKind kind;",
        "  final GameOrigin origin;",
        "",
        "  /// The id of the game that absorbed this one, when the catalog merged a twin.",
        "  final String? family;",
        "",
        "  /// Only an archived game has one.",
        "  final ArchiveReason? reason;",
        "}",
        "",
        f"/// {len(games)} games: " + ", ".join(f"{count} {tier}" for tier, count in sorted(tiers.items())) + ".",
        "const Map<String, GameProfile> gameProfiles = {",
    ]

    for game_id in sorted(games):
        entry = games[game_id]
        tier = entry["tier"]
        family = entry["family"]
        reason = entry["reason"]
        parts = [
            f"tier: GameTier.{tier}",
            f"kind: CardKind.{kind_for(entry)}",
            f"origin: GameOrigin.{origin_for(entry)}",
        ]
        if family:
            parts.append(f"family: '{family}'")
        if tier == "archive":
            parts.append(f"reason: ArchiveReason.{reason}")
        lines.append(f"  '{game_id}': GameProfile({', '.join(parts)}),")

    lines += [
        "};",
        "",
        "/// The profile for [id], or null when the id is not in the catalog at all.",
        "GameProfile? profileOf(String id) => gameProfiles[id];",
        "",
        "/// The profile, reachable from the game itself.",
        "///",
        "/// The fields live in one table instead of in 313 `_metadata.dart` files: adding a",
        "/// required field to `GameMetadata` would mean editing every one of them, and three of",
        "/// these (tier, family, reason) are the catalog's business, not the game's.",
        "extension GameMetadataProfile on GameMetadata {",
        "  GameProfile? get profile => profileOf(id);",
        "",
        "  /// Not in the catalog means not dealt and not listed: a new game has to be given a",
        "  /// verdict in docs/CATALOG.md before a player can see it.",
        "  GameTier get tier => profile?.tier ?? GameTier.archive;",
        "  CardKind get kind => profile?.kind ?? CardKind.think;",
        "  GameOrigin get origin => profile?.origin ?? GameOrigin.puzzle;",
        "  String? get family => profile?.family;",
        "  ArchiveReason? get archiveReason => profile?.reason;",
        "}",
        "",
        "/// Every game in the registry that the catalog leaves out, which should be none.",
        "List<GameMetadata> gamesWithoutVerdict(List<GameMetadata> registry) =>",
        "    registry.where((game) => !gameProfiles.containsKey(game.id)).toList();",
        "",
        "/// Every id the catalog puts in the deal.",
        "Set<String> get deckIds => {",
        "  for (final entry in gameProfiles.entries)",
        "    if (entry.value.tier == GameTier.deck) entry.key,",
        "};",
        "",
        "/// Every id a player can open: the deal and the library, never the archive.",
        "Set<String> get visibleIds => {",
        "  for (final entry in gameProfiles.entries)",
        "    if (entry.value.tier != GameTier.archive) entry.key,",
        "};",
        "",
    ]
    OUT.write_text("\n".join(lines))

    # The registry is a list of imports plus one `...Metadata` per game, so the ids are the
    # paths: `games/<id>/<id>_metadata.dart`.
    registry = set(
        re.findall(
            r"games/([a-z0-9_]+)/\1_metadata\.dart",
            (REPO / "lib" / "data" / "game_registry.dart").read_text(),
        )
    )
    unknown = sorted(set(games) - registry)
    missing = sorted(registry - set(games))
    print(f"wrote {OUT.relative_to(REPO)}: {len(games)} games, {tiers}")
    if unknown:
        print(f"IN THE CATALOG, NOT IN THE REGISTRY ({len(unknown)}): {unknown}", file=sys.stderr)
    if missing:
        print(f"IN THE REGISTRY, NOT IN THE CATALOG ({len(missing)}): {missing}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
