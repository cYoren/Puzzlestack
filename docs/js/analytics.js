// The whole web analytics module for the Puzzlestack site.
//
// Cookieless: no cookie, no localStorage, no session replay, no autocapture of
// inputs. One pageview, and one event when a visitor opens the puzzles in the
// browser. Nothing typed anywhere is read, and no puzzle or board is sent.
//
// The install is anonymous and per-tab: the id lives in a JS variable and dies
// with the page, so `persistence: memory` has nothing to turn on.
//
// No posthog-js here (the repo has no npm): every property below is built by
// this file, so the blocked-key filter only ever sees our own keys and can
// never strip a field the SDK needs. Pages are sent as a path, without query
// string or fragment.
//
// Three ways to switch it off, cheapest first:
//   1. reset the project API key in PostHog (every page stops collecting),
//   2. set KEY below to '' (this file then does nothing),
//   3. delete this file and the one <script> tag in tool/gen_site.py.
(function () {
  'use strict';

  var KEY = 'phc_zLwpAJq2pqBggPtCN2VF4EvuNR8wk2uoSpK62A6hhT6o';
  if (!KEY) return;

  var HOST = 'https://us.i.posthog.com/batch/';
  var APP = 'puzzlestack-web';
  var BLOCKED = /(email|name|token|password|secret|message|text|query|prompt|content|transcript|note)/i;

  function uuid() {
    if (window.crypto && window.crypto.randomUUID) return window.crypto.randomUUID();
    var hex = 'xxxxxxxxxxxx4xxxyxxxxxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
      var r = (Math.random() * 16) | 0;
      var v = c === 'x' ? r : (r & 0x3) | 0x8;
      return v.toString(16);
    });
    return hex;
  }

  var id = uuid();

  function safe(props) {
    var out = {};
    for (var key in props) {
      if (!Object.prototype.hasOwnProperty.call(props, key)) continue;
      if (BLOCKED.test(key)) continue;
      var value = props[key];
      var type = typeof value;
      if (value === null || value === undefined) continue;
      if (type === 'string' || type === 'number' || type === 'boolean') out[key] = value;
    }
    return out;
  }

  function capture(event, props) {
    var properties = {
      app: APP,
      platform: 'web',
      locale: (navigator.language || '').slice(0, 8),
      $process_person_profile: false
    };
    var extra = safe(props || {});
    for (var key in extra) properties[key] = extra[key];

    var body = JSON.stringify({
      api_key: KEY,
      batch: [{
        event: event,
        distinct_id: id,
        timestamp: new Date().toISOString(),
        properties: properties
      }]
    });

    // fetch with keepalive, not sendBeacon: a JSON Blob is not a safelisted
    // content type, so a cross-origin beacon can return true and then be
    // dropped without a CORS preflight, losing the event silently.
    try {
      fetch(HOST, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: body,
        keepalive: true,
        credentials: 'omit'
      }).catch(function () { /* analytics is never a visible failure */ });
    } catch (error) { /* ignore */ }
  }

  function pageName() {
    var path = window.location.pathname.replace(/^.*Puzzlestack\//, '');
    return path || 'index.html';
  }

  capture('$pageview', { page: pageName() });

  // The site's one conversion: opening the puzzles in the browser.
  document.addEventListener('click', function (event) {
    var link = event.target && event.target.closest ? event.target.closest('a') : null;
    if (!link) return;
    var url;
    try {
      url = new URL(link.getAttribute('href') || '', window.location.href);
    } catch (error) {
      return;
    }
    if (!/(^|\/)app\/index\.html$/.test(url.pathname)) return;
    // URLSearchParams, not a substring: a future link carrying utm_content or
    // a campaign tag must never ride along under the `game` key.
    capture('play_opened', {
      page: pageName(),
      game: url.searchParams.get('game') || 'feed'
    });
  }, true);
})();
