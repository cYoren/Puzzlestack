// A plain board for the puzzle pages: HTML cells and CSS, no canvas.
//
// A page opts in with <div class="board" data-board="sudoku" data-clues="35">
// and the bundle for that game (docs/js/sudoku.js) supplies the board: the same
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

  function sudoku(host, say) {
    var clues = parseInt(host.getAttribute('data-clues') || '35', 10);
    var data = JSON.parse(window.sudokuNew(clues));
    var given = data.given;
    var cells = given.slice();
    var grid = document.createElement('div');
    var pad = document.createElement('div');
    var selected = -1;
    var started = Date.now();
    var finished = false;

    host.setAttribute('role', 'grid');
    host.setAttribute('aria-label', 'Sudoku board');
    for (var i = 0; i < 81; i++) {
      var cell = document.createElement('button');
      cell.type = 'button';
      cell.className = 'cell' + (given[i] ? ' given' : '');
      cell.dataset.row = String(Math.floor(i / 9));
      cell.dataset.col = String(i % 9);
      cell.dataset.index = String(i);
      cell.textContent = given[i] ? String(given[i]) : '';
      cell.setAttribute('aria-label', label(i));
      if (given[i]) cell.disabled = true;
      grid.appendChild(cell);
    }
    host.appendChild(grid);
    // Under the board, above the line that says what is happening.
    (status || host).insertAdjacentElement('afterend', pad);
    pad.className = 'pad';
    pad.hidden = false;

    for (var n = 1; n <= 9; n++) {
      pad.appendChild(key(String(n), String(n)));
    }
    pad.appendChild(key('Erase', '\u232B'));

    function key(text, glyph) {
      var button = document.createElement('button');
      button.type = 'button';
      button.className = 'pad-key';
      button.setAttribute('aria-label', text);
      button.textContent = glyph;
      button.addEventListener('click', function () { write(text === 'Erase' ? 0 : parseInt(glyph, 10)); });
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

    function paint() {
      var bad = window.sudokuConflicts(JSON.stringify(cells));
      var marked = {};
      for (var b = 0; b < bad.length; b++) marked[bad[b]] = true;
      for (var i = 0; i < 81; i++) {
        var cell = grid.children[i];
        cell.textContent = cells[i] ? String(cells[i]) : '';
        cell.className = 'cell' + (given[i] ? ' given' : '') +
          (i === selected ? ' sel' : '') + (marked[i] ? ' bad' : '');
        cell.setAttribute('aria-label', label(i));
      }
    }

    function check() {
      if (cells.indexOf(0) >= 0) {
        say('In progress. ' + (Math.round((Date.now() - started) / 1000)) + 's.', false);
        return;
      }
      var bad = window.sudokuConflicts(JSON.stringify(cells));
      if (bad.length) {
        say('Every square is filled, but ' + bad.length + ' of them repeat a number.', false);
        return;
      }
      finished = true;
      var seconds = Math.round((Date.now() - started) / 1000);
      say('Solved in ' + seconds + 's. Reload for a new board, or play the ' +
        'other 229 puzzles in the app.', true);
    }

    grid.addEventListener('click', function (event) {
      var cell = event.target.closest('.cell');
      if (!cell) return;
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
})();
