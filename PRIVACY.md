# Privacy Policy for Puzzlestack

**Last updated: 23 November 2026**

Published at <https://cyoren.github.io/Puzzlestack/privacy.html>. The published page is
`docs/privacy.html`; change both together.

Puzzlestack is a collection of offline brain puzzles. It does not sell your
data, does not ask who you are, and has no accounts and no advertising. The
things it sends are the anonymous usage described below, which you can switch
off, and an update check once a release carries the updater.

## What Puzzlestack stores

Puzzlestack stores a small amount of data **locally on your device only**, so the
app can remember your progress between sessions:

- A nickname you choose during onboarding (you may enter anything, including a
  random one the app suggests).
- Your experience points, level, solve times, and total puzzles solved.
- Per-puzzle streaks, Daily Five completion times and streaks, and daily free
  pick and hint counters.
- Your favourite and hidden puzzles, saved difficulty choices, app settings such
  as theme, and whether your device owns Puzzlestack Plus.

This data never leaves your device. It is not uploaded to us or to anyone else,
because Puzzlestack has no server to upload it to. The games you open and finish
are counted anonymously; that is the next section.

## Usage analytics

We use PostHog (PostHog, Inc., USA) to understand how Puzzlestack is used, for
example which puzzles are opened and where people stop. PostHog receives
anonymous usage events, never your name, your email, anything you type or a
board. The app does not send your IP address; PostHog sees the connection
address as any server does, and we do not use it to identify anyone. Data is
transferred to the USA under the EU Standard Contractual Clauses. You can turn
this off in Settings, under Privacy, with "Share anonymous usage data".

The events are a short list: the app was opened, a puzzle was opened, a puzzle
was finished, today's Daily Five was finished, the first puzzle you ever
finished, the Plus sheet was shown, what came of a purchase, and the switch
being turned off. They carry a random identifier made on this device, the app
version, the platform and the language. A finished puzzle adds a rough duration
bucket, its exact length in milliseconds, how many hints it took and whether it
was helped. Never a board, a seed, an answer or your nickname.

Outside the store's own billing and review prompt, this is the only network
call the app makes. The rest of Puzzlestack plays with no connection at all.

## The website

The pages at <https://cyoren.github.io/Puzzlestack/> count pageviews
anonymously with the same PostHog project, under the name `puzzlestack-web`, so
we can see which puzzles people look up. That is separate from the app events
and carries a different random identifier. It uses no cookie and stores nothing
in your browser: the identifier lives in the open page and dies when you close
the tab, and nothing you type is read. Only the page path is sent, plus the name
of the game when someone opens the puzzles in the browser. Blocking the site's
`js/analytics.js`, or using a private window, stops it. The app's switch does
not affect the website, and the website's script does not affect the app.

## In-app purchase

Puzzlestack offers one optional, one-time purchase (`Puzzlestack Plus`). When
you buy or restore Puzzlestack Plus, the payment and receipt check are processed
directly by Apple (App Store) or Google (Google Play) under their respective
privacy policies. Puzzlestack never receives your name, billing address, or
payment details, and records only a local unlock flag on your device.

## App updates

From the release that ships with the update service, Puzzlestack asks Shorebird
(Shorebird, Inc., USA) at launch whether a newer version of its own Dart code
exists for the build you have installed. The request carries the app id, the app
version, the platform and the release the build came from, plus the connection
address as any server sees it. It carries no account, no nickname, no puzzle
data and no identifier stored on your device. If a newer version exists it is
downloaded and applied the next time you open the app. Playing offline is
unaffected: the check fails quietly and the installed build keeps working.
Builds older than that have no updater in them and make no such request.

## What Puzzlestack does not do

- It does not collect personal information such as your name, email address,
  phone number, contacts, photos, or precise location.
- It does not contain advertising, advertising identifiers, or ad SDKs.
- It does not contain crash-reporting SDKs, session recording, or heatmaps.
- It does not track you across apps or websites.
- It does not require an account or an internet connection to play.

## Deleting your data

All your progress is held in the app's own private storage. Uninstalling the
app, or clearing its storage through your device's settings, permanently
deletes everything listed above. No copy of it is retained anywhere else.

The usage events are different. They carry only the random install id, never a
name or an email, and no screen in the app shows that id, so a request cannot be
matched to a stored event. If you ask us to erase them, we answer as best we
can with nothing to look up. What does stop the events is in your hands:
switching analytics off in Settings stops everything further, and uninstalling
removes the id from the device.

## Links to other sites

Some screens link out to external pages, such as the project's source
repository on GitHub or its store listing. Opening one hands off to your
browser or store app, and those services have their own privacy policies. This
policy covers the app and its own website, not the pages they link to.

## Children's privacy

Puzzlestack is suitable for general audiences. Nothing it collects identifies
anyone, so it collects nothing identifying from children either.

## Changes to this policy

If a future version of Puzzlestack changes what it stores or introduces any new
network communication, this policy will be updated before that version is
released, and the date at the top will change.

## Contact

Questions about this policy can be sent to:

**gustavo.cesar.marcelino4@gmail.com**

The full source code is available at <https://github.com/cYoren/Puzzlestack>, so
every claim above can be independently verified.
