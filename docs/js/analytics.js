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

    try {
      if (navigator.sendBeacon && navigator.sendBeacon(HOST, new Blob([body], { type: 'application/json' }))) return;
    } catch (error) { /* fall through to fetch */ }

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
    var href = link.getAttribute('href') || '';
    if (href.indexOf('app/index.html') === 0 || href.indexOf('../app/index.html') === 0) {
      capture('play_opened', { page: pageName(), game: link.getAttribute('href').split('game=')[1] || 'feed' });
    }
  }, true);
})();
