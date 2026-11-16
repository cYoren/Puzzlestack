#!/usr/bin/env python3
"""Build the Puzzlestack website from the repo's own data.

    dart run tool/site_export.dart      # tool/site/games.json  (the truth)
    python3 tool/gen_site.py            # docs/                 (the pages)

One page per puzzle the app can open, a page per room, an index, a hub, and a
sitemap, all static HTML with no build step at page-view time. The model is
<https://8puzzle.org/>: a search result lands on the game it names, with the
rules to read and a way to play, not on a marketing page.

Why generated and not hand-written: the catalogue cannot be hand-written twice, and
a page that drifts from the app is worse than no page. The text on each page is
the app's own guide (`lib/data/game_guides.dart`), the title and one-line line are
the English strings (`lib/l10n/app_en.arb`), and the tier comes from
`docs/CATALOG.md`. Only what a player can open is published: an archived lab task
gets no page, because the app will not deal it either.
"""

from __future__ import annotations

import html
import json
import re
import shutil
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"
DATA = ROOT / "tool" / "site" / "games.json"

# Pages are also read from `file://` while working, so every link is relative.
# `--origin` is only used for canonical URLs, the sitemap and the social tags.
ORIGIN = "https://cyoren.github.io/Puzzlestack"

# The app is not on the stores yet (release 1.1.0 is pending). While a URL is
# empty the page offers the browser build instead of a dead store button: a page
# that claims "download now" for a missing app is a broken promise the first
# visitor reports.
#
# `app/` is the Flutter web build, deployed next to these pages by
# `tool/deploy_pages.sh` (Pages serves the `gh-pages` branch, which is `docs/`
# plus `app/`). `?game=<slug>` lands on that puzzle (`lib/utils/deep_link.dart`).
#
# When 1.1.0 is live, set these two and rerun:
#   PLAY_ANDROID = "https://play.google.com/store/apps/details?id=com.medhub.puzzlestack"
#   PLAY_IOS = "https://apps.apple.com/app/id<the App Store id>"
PLAY_WEB = True

# Games whose page hosts a board of its own: plain HTML cells, and a bundle built
# from the app's own engine by `tool/web_build.sh` (dart compile js). These pages
# do not need the 17 MB browser app to be playable, and the app still has all 230.
WEB_BOARDS = {
    "sudoku": {"clues": 35},
}
PLAY_ANDROID = ""
PLAY_IOS = ""
REPO = "https://github.com/cYoren/Puzzlestack"

ROOMS = {
    "logic": {
        "title": "Logic puzzles",
        "blurb": "Deduction with one answer. The grid, the loop and the numbers tell you "
                 "everything you need, and none of it needs a guess.",
        "intro": "Logic is the room this app was built around. Most of these come from the "
                 "Tatham and Nikoli canon: one solution, every clue earning its place, no "
                 "step that requires guessing. Start with Nonogram or Sudoku if you have "
                 "never done one; Slitherlink and Masyu are the same idea with a line.",
    },
    "math": {
        "title": "Math puzzles",
        "blurb": "Numbers with a shape to them. Arithmetic you can see, not a worksheet.",
        "intro": "Math here is puzzles, not drills. Sliding tiles, magic squares, prime "
                 "chains and balance beams: each one gives you a goal and a few moves, and "
                 "the arithmetic is how you get there. 2048 is the friendliest door.",
    },
    "memory": {
        "title": "Memory puzzles",
        "blurb": "Hold a pattern, then report it back. Short, fair, and over in a minute.",
        "intro": "Memory games are played once and scored, so they are the shortest cards in "
                 "the deck. A grid flashes, a sequence plays, then the board asks you what "
                 "you saw. Nothing depends on a device being fast: the timer is yours.",
    },
    "spatial": {
        "title": "Spatial puzzles",
        "blurb": "Turn it, fold it, walk it. Shapes that change when you are not looking.",
        "intro": "Spatial puzzles ask you to hold an object in your head and move it. Some "
                 "are mazes with a strange camera, some are nets that fold into a cube, some "
                 "are silhouettes to match. Paper Folding is the classic.",
    },
    "attention": {
        "title": "Attention puzzles",
        "blurb": "Find the thing, ignore the noise, and keep it up for a minute.",
        "intro": "Attention games give you one rule and a board that argues with it. Tap the "
                 "colour, not the word. Find the one that does not match. They are the "
                 "fastest cards in the app and the ones people replay most.",
    },
    "word": {
        "title": "Word puzzles",
        "blurb": "Letters into words, and words into a small satisfying click.",
        "intro": "Word games are the widest room: anagrams, ladders, crosswords, word "
                 "searches and a few that lean on how English sounds. Find Word and Word "
                 "Search need nothing explained; the ladders are for a longer minute.",
    },
}

ROOM_ORDER = ["logic", "math", "memory", "spatial", "attention", "word"]

# The headliners, by slug: the names people actually search for. A hub that
# features whatever sorted first is a random shelf, and the tiles people land on
# from a search are these ten.
FEATURED = [
    "sudoku", "nonogram", "minesweeper", "slitherlink", "kakuro",
    "2048", "word-search", "crossword", "akari", "lights-out",
    "hitori", "tents-and-trees",
]


def esc(text: str) -> str:
    return html.escape(text, quote=True)


def clean_for_meta(text: str) -> str:
    """Meta descriptions are plain text: no emoji, no pipes, no double spaces."""
    text = re.sub(r"[^\x00-\x7F]+", "", text)
    text = text.replace("|", ",")
    return re.sub(r"\s+", " ", text).strip(" ,.")


def strip_step(text: str) -> str:
    return re.sub(r"^Step \d+:\s*", "", text.strip())


def truncate(text: str, limit: int) -> str:
    if len(text) <= limit:
        return text
    cut = text[:limit].rsplit(" ", 1)[0]
    return cut.rstrip(" ,.;:") + "."


def slugify(title: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", title.lower()).strip("-")


class Site:
    def __init__(self) -> None:
        payload = json.loads(DATA.read_text())
        self.games: list[dict] = payload["games"]
        self.by_id = {g["id"]: g for g in self.games}
        self.by_room: dict[str, list[dict]] = {room: [] for room in ROOM_ORDER}
        for game in self.games:
            self.by_room.setdefault(game["category"], []).append(game)
        self.today = date.today().isoformat()
        self.pages: list[str] = []

    # --- shared chrome ----------------------------------------------------

    def head(self, *, title: str, description: str, path: str, prefix: str,
             jsonld=None, kind: str = "website") -> str:
        canonical = f"{ORIGIN}/{path}"
        schema = ""
        if jsonld:
            schema = ('<script type="application/ld+json">'
                      + json.dumps(jsonld, ensure_ascii=False, separators=(",", ":"))
                      + "</script>\n")
        return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<!-- Bing Webmaster: the site is a project page, so verification has to sit on
     the page itself. Nothing else in the build reads this. -->
<meta name="msvalidate.01" content="DFE132ECE62D3F6AC2E582289D8C75EF">
<title>{esc(title)}</title>
<meta name="description" content="{esc(description)}">
<link rel="canonical" href="{esc(canonical)}">
<meta name="theme-color" media="(prefers-color-scheme: light)" content="#EBE6D8">
<meta name="theme-color" media="(prefers-color-scheme: dark)" content="#08080A">
<meta property="og:type" content="{kind}">
<meta property="og:site_name" content="Puzzlestack">
<meta property="og:title" content="{esc(title)}">
<meta property="og:description" content="{esc(description)}">
<meta property="og:url" content="{esc(canonical)}">
<meta name="twitter:card" content="summary">
<link rel="stylesheet" href="{prefix}site.css">
{schema}</head>
<body>
"""

    def bar(self, prefix: str) -> str:
        return f"""<header class="bar">
  <a class="mark" href="{prefix}index.html">PUZZLE<em>STACK</em></a>
  <nav>
    <a href="{prefix}games/index.html">All puzzles</a>
    <a href="{prefix}index.html#rooms">Rooms</a>
    <a class="play" href="{prefix}app/index.html">Play</a>
  </nav>
</header>
"""

    def foot(self, prefix: str) -> str:
        return f"""<footer>
  <p class="foot-links">
    <a href="{prefix}index.html">Puzzlestack</a>
    <a href="{prefix}games/index.html">All {len(self.games)} puzzles</a>
    <a href="{prefix}privacy.html">Privacy</a>
    <a href="{prefix}terms.html">Terms</a>
    <a href="{REPO}">Source</a>
    <a href="{REPO}/issues">Report a problem</a>
  </p>
  <p class="foot-note">Free, no ads, no account, no data collected. Puzzlestack is free
  software under the GNU GPL, version 3 or later. It is a modified derivative of
  <a href="https://github.com/sidhant947/Puzzle">Puzzle</a> by Sidhant Khatkar.</p>
</footer>
</body>
</html>
"""

    # --- game page --------------------------------------------------------

    def play_block(self, label: str = "Play", slug: str | None = None,
                   prefix: str = "") -> str:
        """The one action a page offers: the puzzle, in the browser, right now."""
        buttons = []
        if PLAY_WEB:
            target = f"{prefix}app/index.html"
            if slug:
                target += f"?game={slug}"
            buttons.append(f'<a class="btn primary" href="{target}">{esc(label)}</a>')
        if PLAY_ANDROID:
            buttons.append(f'<a class="btn" href="{PLAY_ANDROID}">Android</a>')
        if PLAY_IOS:
            buttons.append(f'<a class="btn" href="{PLAY_IOS}">iPhone</a>')
        note = ("Runs in your browser, nothing to install."
                if PLAY_WEB else "The 1.1.0 release is finishing. The source is public today.")
        if not PLAY_WEB and not PLAY_ANDROID and not PLAY_IOS:
            buttons.append(f'<a class="btn primary" href="{REPO}">Get Puzzlestack</a>')
        return ('<p class="cta">' + "".join(buttons)
                + f'<span class="note">{note}</span></p>')

    def play_area(self, game: dict) -> str:
        """The board if this page has one, the browser app otherwise."""
        board = self.board_block(game)
        if not board:
            return self.play_block(label=f'Play {game["title"]}',
                                   slug=game["slug"], prefix="../")
        slug = game["slug"]
        return board + (
            '<p class="cta"><a class="btn" href="../app/index.html?game='
            f'{slug}">Open in the app</a><span class="note">The other 229 '
            'puzzles are in the app.</span></p>\n')

    def board_block(self, game: dict) -> str:
        """A playable board, when this page has one."""
        config = WEB_BOARDS.get(game["id"])
        if not config:
            return ""
        slug = game["slug"]
        attrs = " ".join(f'data-{k}="{v}"' for k, v in config.items())
        return f'''<div class="board" data-board="{slug}" {attrs}></div>
<p class="note" id="boardStatus" role="status">Loading the board&hellip;</p>
<noscript><p class="note">The board needs JavaScript. The same puzzle runs in the
<a href="../app/index.html?game={slug}">browser app</a>.</p></noscript>
<script src="../js/{slug}.js" defer></script>
<script src="../js/board.js" defer></script>
'''

    def related(self, game: dict) -> list[dict]:
        pool = [g for g in self.by_room.get(game["category"], []) if g["id"] != game["id"]]
        # Deterministic neighbours: the next few in the room's alphabetical order,
        # wrapping, so every page links out and every page gets linked back to.
        start = 0
        ids = [g["id"] for g in pool]
        if game["id"] in ids:
            start = ids.index(game["id"]) + 1
        return [pool[(start + i) % len(pool)] for i in range(min(5, len(pool)))]

    def game_page(self, game: dict) -> tuple[str, str]:
        slug = game["slug"]
        room = game["category"]
        room_info = ROOMS[room]
        title = game["title"]
        subtitle = game["subtitle"]
        objective = game["objective"]
        minutes = ("About a minute." if game["tier"] == "deck"
                   else "A few minutes at the size it opens; bigger boards are in the library.")
        heading = f"{title} (free online puzzle)" if len(title) < 32 else f"{title}"
        meta = truncate(f"{subtitle} How to play {title}, the rules, and the one strategy "
                        f"that gets you unstuck. Free, no ads, no account.", 155)

        steps = "".join(f"<li>{esc(strip_step(s))}</li>" for s in game["walkthrough"])
        strategies = "".join(f"<li>{esc(s)}</li>" for s in game["strategies"])

        faq = [
            (f"Is {title} free?",
             "Yes. Puzzlestack is free to download, with no advertising, no account and "
             "nothing collected about you. Every puzzle can be played at least once."),
            (f"How long does one {title} take?",
             f"{minutes} Dealt from the deck it uses the size a first-timer finishes in "
             f"under two minutes; the full sizes are in the library." if game["tier"] == "deck"
             else f"{minutes}"),
            (f"Do I have to guess in {title}?",
             "No. Where a puzzle has one answer, the generator proves it before dealing, and "
             "the clues are enough to get there by reasoning."),
            (f"What does {title} practice?",
             f"It is a {room_info['title'].split()[0].lower()} puzzle: "
             f"{objective[0].lower() + objective[1:] if objective else 'a small problem with one answer.'}"),
        ]
        faq_html = "".join(
            f'<div class="qa"><h3>{esc(q)}</h3><p>{esc(a)}</p></div>' for q, a in faq
        )

        neighbours = "".join(
            f'<li><a href="{g["slug"]}.html">{esc(g["title"])}'
            f'<span>{esc(g["subtitle"])}</span></a></li>'
            for g in self.related(game)
        )

        jsonld = {
            "@context": "https://schema.org",
            "@graph": [
                {
                    "@type": "BreadcrumbList",
                    "itemListElement": [
                        {"@type": "ListItem", "position": 1, "name": "Puzzlestack",
                         "item": f"{ORIGIN}/index.html"},
                        {"@type": "ListItem", "position": 2,
                         "name": room_info["title"], "item": f"{ORIGIN}/rooms/{room}.html"},
                        {"@type": "ListItem", "position": 3, "name": title,
                         "item": f"{ORIGIN}/games/{slug}.html"},
                    ],
                },
                {
                    "@type": "SoftwareApplication",
                    "name": f"Puzzlestack, {title}",
                    "applicationCategory": "GameApplication",
                    "operatingSystem": "Android, iOS",
                    "url": f"{ORIGIN}/games/{slug}.html",
                    "offers": {"@type": "Offer", "price": "0", "priceCurrency": "USD"},
                    "isPartOf": {"@type": "WebSite", "name": "Puzzlestack",
                                 "url": f"{ORIGIN}/index.html"},
                },
                {
                    "@type": "FAQPage",
                    "mainEntity": [
                        {"@type": "Question", "name": q,
                         "acceptedAnswer": {"@type": "Answer", "text": a}}
                        for q, a in faq
                    ],
                },
            ],
        }

        page = self.head(title=f"{heading} | Puzzlestack", description=meta,
                         path=f"games/{slug}.html", prefix="../", jsonld=jsonld,
                         kind="article")
        page += self.bar("../")
        page += f"""<main>
<nav class="crumbs"><a href="../index.html">Puzzlestack</a><span>/</span>
<a href="../rooms/{room}.html">{esc(room_info['title'])}</a><span>/</span>
<span aria-current="page">{esc(title)}</span></nav>

<h1>{esc(title)}</h1>
<p class="lede">{esc(subtitle)}</p>
{self.play_area(game)}

<h2>How to play</h2>
<p>{esc(game['controls'])}</p>
<ol class="steps">{steps}</ol>

<h2>Strategy</h2>
<ul class="plain">{strategies}</ul>

<h2>What it asks of you</h2>
<p>{esc(objective)}</p>

<h2>Questions</h2>
<div class="faq">{faq_html}</div>

<h2>More {esc(room_info['title'].lower())}</h2>
<ul class="cards">{neighbours}</ul>
<p class="more"><a href="index.html">All {len(self.games)} puzzles</a></p>
</main>
"""
        page += self.foot("../")
        return f"games/{slug}.html", page

    # --- room, index, hub -------------------------------------------------

    def room_page(self, room: str) -> tuple[str, str]:
        info = ROOMS[room]
        games = self.by_room.get(room, [])
        title = f"{info['title']}: {len(games)} free puzzles | Puzzlestack"
        meta = truncate(f"{info['blurb']} {len(games)} puzzles, each playable in a minute. "
                        f"Free, no ads, no account.", 155)
        items = "".join(
            f'<li><a href="../games/{g["slug"]}.html">{esc(g["title"])}'
            f'<span>{esc(g["subtitle"])}</span></a></li>'
            for g in games
        )
        jsonld = {
            "@context": "https://schema.org",
            "@type": "CollectionPage",
            "name": info["title"],
            "url": f"{ORIGIN}/rooms/{room}.html",
            "description": info["blurb"],
            "isPartOf": {"@type": "WebSite", "name": "Puzzlestack",
                         "url": f"{ORIGIN}/index.html"},
            "hasPart": [
                {"@type": "SoftwareApplication", "name": g["title"],
                 "url": f"{ORIGIN}/games/{g['slug']}.html"}
                for g in games[:30]
            ],
        }
        page = self.head(title=title, description=meta, path=f"rooms/{room}.html",
                         prefix="../", jsonld=jsonld, kind="article")
        page += self.bar("../")
        page += f"""<main>
<nav class="crumbs"><a href="../index.html">Puzzlestack</a><span>/</span>
<span aria-current="page">{esc(info['title'])}</span></nav>

<h1>{esc(info['title'])}</h1>
<p class="lede">{esc(info['blurb'])}</p>
<p>{esc(info['intro'])}</p>
{self.play_block(label='Play a puzzle', prefix='../')}

<h2>Every {esc(info['title'].lower())} puzzle ({len(games)})</h2>
<ul class="cards">{items}</ul>
<p class="more"><a href="../games/index.html">All {len(self.games)} puzzles</a></p>
</main>
"""
        page += self.foot("../")
        return f"rooms/{room}.html", page

    def index_page(self) -> tuple[str, str]:
        blocks = []
        for room in ROOM_ORDER:
            info = ROOMS[room]
            games = self.by_room.get(room, [])
            items = "".join(
                f'<li><a href="{g["slug"]}.html">{esc(g["title"])}</a></li>' for g in games
            )
            blocks.append(
                f'<section><h2><a href="../rooms/{room}.html">{esc(info["title"])}</a>'
                f'<span class="count">{len(games)}</span></h2>'
                f'<p class="blurb">{esc(info["blurb"])}</p>'
                f'<ul class="inline">{items}</ul></section>'
            )
        meta = (f"All {len(self.games)} Puzzlestack puzzles, filed by room: logic, math, memory, spatial, "
                "attention and word. Each one has its rules and a strategy.")
        page = self.head(title=f"All {len(self.games)} puzzles, by room | Puzzlestack",
                         description=truncate(meta, 155), path="games/index.html",
                         prefix="../")
        page += self.bar("../")
        page += f"""<main>
<nav class="crumbs"><a href="../index.html">Puzzlestack</a><span>/</span>
<span aria-current="page">All puzzles</span></nav>

<h1>All {len(self.games)} puzzles</h1>
<p class="lede">Every game the app can open, filed by room. Every one of them has a page
with the rules, the strategy and a way to play.</p>
{''.join(blocks)}
</main>
"""
        page += self.foot("../")
        return "games/index.html", page

    def hub_page(self) -> tuple[str, str]:
        by_slug = {g["slug"]: g for g in self.games}
        picks = [by_slug[s] for s in FEATURED if s in by_slug]
        if len(picks) < 6:
            # A catalog move must not leave the hub with an empty shelf.
            picks += [g for g in self.games if g["tier"] == "deck"][:8 - len(picks)]
        pick_items = "".join(
            f'<li><a href="games/{g["slug"]}.html">{esc(g["title"])}'
            f'<span>{esc(g["subtitle"])}</span></a></li>' for g in picks
        )
        room_items = "".join(
            f'<li><a href="rooms/{room}.html">{esc(ROOMS[room]["title"])}'
            f'<span>{len(self.by_room.get(room, []))} puzzles</span></a></li>'
            for room in ROOM_ORDER
        )
        jsonld = {
            "@context": "https://schema.org",
            "@graph": [
                {"@type": "WebSite", "name": "Puzzlestack", "url": f"{ORIGIN}/index.html",
                 "description": "230 real puzzles in one app: one good puzzle, then another.",
                 "inLanguage": "en"},
                {"@type": "Organization", "name": "Puzzlestack", "url": f"{ORIGIN}/index.html",
                 "sameAs": [REPO]},
            ],
        }
        page = self.head(
            title="Puzzlestack: 230 real puzzles, one at a time",
            description=truncate("A feed of real puzzles: logic, math, memory, spatial, "
                                 "attention and word. Each one about a minute, each one fair, "
                                 "none of them filler.", 155),
            path="index.html", prefix="", jsonld=jsonld)
        page += self.bar("")
        page += f"""<main class="hub">
<h1>One good puzzle, then another</h1>
<p class="lede">Puzzlestack opens on a puzzle, not a menu. 230 of them, in six rooms, every
one with one answer and about a minute of your time.</p>
{self.play_block(label='Play now', prefix='')}

<h2 id="rooms">Six rooms</h2>
<ul class="cards">{room_items}</ul>

<h2>Start here</h2>
<ul class="cards">{pick_items}</ul>
<p class="more"><a href="games/index.html">All {len(self.games)} puzzles</a></p>

<h2>What it is not</h2>
<p>No feed to scroll, no streak to protect, no energy to spend. A puzzle arrives, you
solve it, the next one is dealt. If you want to choose instead, the whole catalogue is one
tap away and filed by room.</p>
<p>Every puzzle here is played in the app, and everything the app is made of is public:
<a href="{REPO}">the source</a>, <a href="games/index.html">the full list</a>, and the rules
for each card written on its page.</p>
</main>
"""
        page += self.foot("")
        return "index.html", page

    # --- output -----------------------------------------------------------

    def prune(self) -> None:
        """Delete pages this run did not write.

        A slug that changes (or a game that leaves the catalog) would otherwise
        leave its old page behind, and a stale page is a duplicate of a live one
        with a link to a puzzle that moved.
        """
        keep = set(self.pages)
        for folder in ("games", "rooms"):
            target = DOCS / folder
            if not target.is_dir():
                continue
            for file in target.glob("*.html"):
                rel = f"{folder}/{file.name}"
                if rel not in keep:
                    file.unlink()
                    print(f"removed stale page {rel}")

    def write(self, path: str, body: str) -> None:
        target = DOCS / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(body, encoding="utf-8")
        self.pages.append(path)

    def sitemap(self) -> str:
        url = f"{ORIGIN}/"
        entries = []
        for path in sorted(self.pages):
            priority = "1.0" if path == "index.html" else (
                "0.8" if path.startswith("games/") else "0.7")
            entries.append(f"  <url><loc>{esc(url + path)}</loc>"
                           f"<lastmod>{self.today}</lastmod>"
                           f"<priority>{priority}</priority></url>")
        return ('<?xml version="1.0" encoding="UTF-8"?>\n'
                '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
                + "\n".join(entries) + "\n</urlset>\n")

    def build(self) -> None:
        for game in self.games:
            self.write(*self.game_page(game))
        for room in ROOM_ORDER:
            self.write(*self.room_page(room))
        self.write(*self.index_page())
        self.write(*self.hub_page())

        self.prune()
        (DOCS / "sitemap.xml").write_text(self.sitemap(), encoding="utf-8")
        (DOCS / "robots.txt").write_text(
            "User-agent: *\nAllow: /\n\n"
            f"Sitemap: {ORIGIN}/sitemap.xml\n", encoding="utf-8")

        fonts = DOCS / "fonts"
        fonts.mkdir(exist_ok=True)
        for src, name in [
            (ROOT / "assets/fonts/Bebas_Neue/BebasNeue-Regular.ttf", "BebasNeue-Regular.ttf"),
            (ROOT / "assets/fonts/Geist/static/Geist-Regular.ttf", "Geist-Regular.ttf"),
            (ROOT / "assets/fonts/Geist/static/Geist-SemiBold.ttf", "Geist-SemiBold.ttf"),
        ]:
            if src.exists():
                shutil.copyfile(src, fonts / name)

        print(f"{len(self.pages)} pages, sitemap and robots in {DOCS}")


if __name__ == "__main__":
    Site().build()
