// A plain board for the puzzle pages: HTML cells and CSS, no canvas.
//
// A page opts in with <div class="board" data-board="sudoku" data-clues="35">
// and the bundle for that game (docs/js/<slug>.js) supplies the puzzle: the same
// engine the app runs, compiled to JavaScript. Everything below is presentation
// and input, which is the only part that is written twice.
(function () {
  'use strict';

  var mount = document.querySelector('[data-board]');
  if (!mount) return;

  var game = mount.getAttribute('data-board');
  var status = document.getElementById('boardStatus');
  var say = function (text, done) {
    if (!status) return;
    status.textContent = text;
    status.className = done ? 'note solved' : 'note';
  };

  if (game === 'sudoku') sudoku(mount, say);
  else if (status) status.textContent = '';

  function key(text, glyph, className) {
    var button = document.createElement('button');
    button.type = 'button';
    button.className = className || 'pad-key';
    button.setAttribute('aria-label', text);
    button.textContent = glyph;
    return button;
  }

  function sudoku(host, say) {
    var clues = parseInt(host.getAttribute('data-clues') || '35', 10);
    var pad = key('', '');
    pad.className = 'pad';
    pad.hidden = false;
    (status || host).insertAdjacentElement('afterend', pad);

    deal();

    // A new grid, in place. Every square is rebuilt, so a finished board and a
    // fresh one need no reload in between.
    function deal() {
      var data = JSON.parse(window.sudokuNew(clues));
      var given = data.given;
      var solution = data.solution;
      var cells = given.slice();
      var selected = -1;
      var started = Date.now();
      var finished = false;

      // The page can read the board it is hosting: `board.board.solution` is
      // what a test (or a "show me" button) would want.
      host.board = { given: given.slice(), solution: solution };

      host.innerHTML = '';
      pad.innerHTML = '';
      host.setAttribute('role', 'grid');
      host.setAttribute('aria-label', 'Sudoku board');

      for (var i = 0; i < 81; i++) {
        var cell = key(label(i), given[i] ? String(given[i]) : '', 'cell');
        cell.dataset.row = String(Math.floor(i / 9));
        cell.dataset.col = String(i % 9);
        cell.dataset.index = String(i);
        if (given[i]) {
          cell.classList.add('given');
          cell.disabled = true;
        }
        host.appendChild(cell);
      }
      for (var n = 1; n <= 9; n++) pad.appendChild(numberKey(String(n), String(n)));
      pad.appendChild(eraseKey());

      function numberKey(text, glyph) {
        var button = key(text, glyph);
        button.addEventListener('click', function () {
          write(parseInt(glyph, 10));
        });
        return button;
      }

      function eraseKey() {
        var button = key('Erase', '\u232B');
        button.addEventListener('click', function () {
          write(0);
        });
        return button;
      }

      function label(index) {
        var row = Math.floor(index / 9) + 1;
        var col = (index % 9) + 1;
        var value = cells[index];
        return 'Row ' + row + ', column ' + col + (value ? ', ' + value : ', empty');
      }

      function write(value) {
        if (finished || selected < 0 || given[selected]) return;
        cells[selected] = value;
        paint();
        check();
      }

      function conflicts() {
        return JSON.parse(window.sudokuConflicts(JSON.stringify(cells)));
      }

      function paint() {
        var marked = {};
        var bad = conflicts();
        for (var b = 0; b < bad.length; b++) marked[bad[b]] = true;
        for (var i = 0; i < 81; i++) {
          var cell = host.children[i];
          cell.textContent = cells[i] ? String(cells[i]) : '';
          cell.className = 'cell' + (given[i] ? ' given' : '') +
            (i === selected ? ' sel' : '') + (marked[i] ? ' bad' : '');
          cell.setAttribute('aria-label', label(i));
        }
      }

      function check() {
        if (cells.indexOf(0) >= 0) {
          say('In progress. ' + Math.round((Date.now() - started) / 1000) + 's.', false);
          return;
        }
        var wrong = 0;
        for (var i = 0; i < 81; i++) if (cells[i] !== solution[i]) wrong++;
        if (wrong) {
          say('Every square is filled, but ' + wrong +
            ' of them are not the number this grid needs.', false);
          return;
        }
        finished = true;
        var seconds = Math.round((Date.now() - started) / 1000);
        say('Solved in ' + seconds + 's.', true);
        pad.innerHTML = '';
        var again = key('New board', 'New board');
        again.addEventListener('click', deal);
        pad.appendChild(again);
        pad.appendChild(document.createTextNode(
          ' The other 229 puzzles are in the app.'));
      }

      host.addEventListener('click', function (event) {
        var cell = event.target.closest('.cell');
        if (!cell || !host.contains(cell)) return;
        selected = Number(cell.dataset.index);
        paint();
      });

      document.addEventListener('keydown', function (event) {
        if (event.key >= '1' && event.key <= '9') write(parseInt(event.key, 10));
        else if (event.key === 'Backspace' || event.key === 'Delete' || event.key === '0') write(0);
        else return;
        event.preventDefault();
      });

      say('Tap a square, then a number.');
    }
  }
})();
