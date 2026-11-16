#!/usr/bin/env python3
"""Tell Bing about the puzzle pages, a hundred at a time.

Bing's API allows 100 URL submissions per day per site, and the sitemap endpoint
is not available to this account, so the pages are pushed in sitemap order:

    python3 tool/bing_submit.py              # the next 100 from the start
    python3 tool/bing_submit.py --offset 100 # the hundred after that

Order matters because the quota may run out before the site does: the index, the
room pages and the games Gus sells first are already at the top of the sitemap.
"""
import argparse
import json
import re
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SITE = "https://cyoren.github.io/Puzzlestack/"
KEY = Path.home() / ".config" / "bing-webmaster" / "credentials.env"


def urls() -> list[str]:
    xml = (ROOT / "docs" / "sitemap.xml").read_text()
    return re.findall(r"<loc>([^<]+)</loc>", xml)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--offset", type=int, default=0)
    parser.add_argument("--limit", type=int, default=100)
    args = parser.parse_args()

    batch = urls()[args.offset : args.offset + args.limit]
    if not batch:
        print(f"nothing left after offset {args.offset}")
        return

    key = KEY.read_text().split("=", 1)[1].strip()
    body = json.dumps({"siteUrl": SITE, "urlList": batch}).encode()
    request = urllib.request.Request(
        "https://ssl.bing.com/webmaster/api.svc/json/SubmitUrlbatch?apikey=" + key,
        data=body,
        headers={"content-type": "application/json; charset=utf-8"},
    )
    try:
        print(urllib.request.urlopen(request, timeout=60).read().decode()[:400])
    except urllib.error.HTTPError as error:
        print(error.code, error.read().decode()[:400].replace(key, "***"))
        raise SystemExit(1)
    print(f"submitted {len(batch)} urls (offset {args.offset})")


if __name__ == "__main__":
    main()
