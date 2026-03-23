**FREE
// MINES2 - Minesweeper for IBM i (classic rules)
// CFOX1 library - by cfox
// Move with F6/F7/F8/F9. Press Enter to reveal a cell.
// Reveal all safe cells to win|
ctl-opt dftactgrp(*no) actgrp(*caller);

dcl-f MINESD workstn;

// Forward reference for nearbyCount procedure
dcl-pr nearbyCount int(3);
  r int(3) value;
  c int(3) value;
end-pr;

// Board dimensions
dcl-c ROWS   20;
dcl-c COLS   40;
dcl-c STARTR 10;
dcl-c STARTC 20;

// Internal mine grid: 'M' = mine, ' ' = safe
dcl-s mineRow char(40) dim(20);

// Display grid: '.' unrevealed, '-' clear, '1'-'8' count, '*' boom
dcl-s dispRow char(40) dim(20);

// Player position
dcl-s pRow int(3);
dcl-s pCol int(3);

// Game state
dcl-s gameOver  ind inz(*off);
dcl-s won       ind inz(*off);
dcl-s firstMove ind inz(*on);

// Working variables
dcl-s seed         packed(15:0);
dcl-s cnt          int(3);
dcl-s r            int(3);
dcl-s c            int(3);
dcl-s dr           int(3);
dcl-s dc           int(3);
dcl-s nr           int(3);
dcl-s nc           int(3);
dcl-s tsStr        char(26);
dcl-s totalSafe    int(5);
dcl-s revealedSafe int(5);
dcl-s changed      ind;

// -------------------------------------------------------
// MAIN
// -------------------------------------------------------
*inlr = *off;
exsr initGame;

dow not *in03;
  exsr renderBoard;
  if firstMove;
    STATLN = 'Move cursor. Press Enter to reveal.';
  else;
    STATLN = 'Nearby: ' + %char(nearbyCount(pRow: pCol)) +
             '   Left: ' + %char(totalSafe - revealedSafe) +
             '   R:' + %char(pRow) + ' C:' + %char(pCol);
  endif;
  KEYIN = *blanks;
  exfmt GAMESCREEN;

  if *in03;
    leave;
  endif;

  if *in05;
    exsr initGame;
    iter;
  endif;

  if gameOver;
    iter;
  endif;

  // WASD movement; blank KEYIN (just Enter) = reveal
  if KEYIN = *blanks;
    exsr revealCell;
  elseif %upper(KEYIN) = 'A';
    if pCol > 1;
      pCol -= 1;
    endif;
  elseif %upper(KEYIN) = 'D';
    if pCol < COLS;
      pCol += 1;
    endif;
  elseif %upper(KEYIN) = 'W';
    if pRow > 1;
      pRow -= 1;
    endif;
  elseif %upper(KEYIN) = 'S';
    if pRow < ROWS;
      pRow += 1;
    endif;
  endif;
enddo;

*inlr = *on;
return;

// -------------------------------------------------------
// Initialize a new game (mines placed on first reveal)
// -------------------------------------------------------
begsr initGame;
  gameOver     = *off;
  won          = *off;
  firstMove    = *on;
  MESSAGE      = *blanks;
  STATLN       = *blanks;
  totalSafe    = 0;
  revealedSafe = 0;

  // Clear both grids
  for r = 1 to ROWS;
    mineRow(r) = *blanks;
    dispRow(r) = '........................................';
  endfor;

  // Seed from timestamp microseconds
  tsStr = %char(%timestamp());
  seed  = %int(%subst(tsStr: 21: 6));
  if seed = 0;
    seed = 77777;
  endif;

  // Place player at center
  pRow = STARTR;
  pCol = STARTC;
endsr;

// -------------------------------------------------------
// Place mines, excluding neighborhood of first reveal
// Called on first reveal to guarantee a safe start
// -------------------------------------------------------
begsr placeMines;
  for r = 1 to ROWS;
    for c = 1 to COLS;
      // Guarantee safe start: skip player and all 8 neighbors
      if r >= pRow - 1 and r <= pRow + 1 and
         c >= pCol - 1 and c <= pCol + 1;
        iter;
      endif;
      seed = %rem(%abs(seed * 1103515245 + 12345): 2147483647);
      if %rem(seed: 7) = 0;
        %subst(mineRow(r): c: 1) = 'M';
      endif;
    endfor;
  endfor;

  // Count total safe cells
  totalSafe = 0;
  for r = 1 to ROWS;
    for c = 1 to COLS;
      if %subst(mineRow(r): c: 1) <> 'M';
        totalSafe += 1;
      endif;
    endfor;
  endfor;
endsr;

// -------------------------------------------------------
// Reveal current player cell (Enter key action)
// -------------------------------------------------------
begsr revealCell;
  if %subst(dispRow(pRow): pCol: 1) <> '.';
    // Already revealed - nothing to do
  elseif firstMove;
    // First reveal: place mines now, guaranteeing safe start
    firstMove = *off;
    exsr placeMines;
    cnt = nearbyCount(pRow: pCol);
    if cnt = 0;
      %subst(dispRow(pRow): pCol: 1) = '-';
    else;
      %subst(dispRow(pRow): pCol: 1) = %subst('12345678': cnt: 1);
    endif;
    exsr floodFill;
    exsr checkWin;
    MESSAGE = *blanks;
  elseif %subst(mineRow(pRow): pCol: 1) = 'M';
    %subst(dispRow(pRow): pCol: 1) = '*';
    gameOver = *on;
    MESSAGE = '*** BOOM| Hit a mine| F5=New Game  F3=Exit ***';
  else;
    cnt = nearbyCount(pRow: pCol);
    if cnt = 0;
      %subst(dispRow(pRow): pCol: 1) = '-';
    else;
      %subst(dispRow(pRow): pCol: 1) = %subst('12345678': cnt: 1);
    endif;
    exsr floodFill;
    exsr checkWin;
    MESSAGE = *blanks;
  endif;
endsr;

// -------------------------------------------------------
// Flood fill: auto-reveal neighbors of 0-count cells
// -------------------------------------------------------
begsr floodFill;
  changed = *on;
  dow changed;
    changed = *off;
    for r = 1 to ROWS;
      for c = 1 to COLS;
        if %subst(dispRow(r): c: 1) = '-';
          for dr = -1 to 1;
            for dc = -1 to 1;
              if not (dr = 0 and dc = 0);
                nr = r + dr;
                nc = c + dc;
                if nr >= 1 and nr <= ROWS and
                   nc >= 1 and nc <= COLS and
                   %subst(dispRow(nr): nc: 1) = '.' and
                   %subst(mineRow(nr): nc: 1) <> 'M';
                  cnt = nearbyCount(nr: nc);
                  if cnt = 0;
                    %subst(dispRow(nr): nc: 1) = '-';
                  else;
                    %subst(dispRow(nr): nc: 1) = %subst('12345678': cnt: 1);
                  endif;
                  changed = *on;
                endif;
              endif;
            endfor;
          endfor;
        endif;
      endfor;
    endfor;
  enddo;
endsr;

// -------------------------------------------------------
// Check if all safe cells are revealed (win condition)
// -------------------------------------------------------
begsr checkWin;
  revealedSafe = 0;
  for r = 1 to ROWS;
    for c = 1 to COLS;
      if %subst(dispRow(r): c: 1) <> '.' and
         %subst(mineRow(r): c: 1) <> 'M';
        revealedSafe += 1;
      endif;
    endfor;
  endfor;
  if revealedSafe = totalSafe;
    won     = *on;
    gameOver = *on;
    MESSAGE = '*** YOU WIN| All cells revealed| F5=New  F3=Exit ***';
  endif;
endsr;

// -------------------------------------------------------
// Copy dispRow to DDS output fields, overlay 'O' at player
// -------------------------------------------------------
begsr renderBoard;
  ROW01 = dispRow(1);
  ROW02 = dispRow(2);
  ROW03 = dispRow(3);
  ROW04 = dispRow(4);
  ROW05 = dispRow(5);
  ROW06 = dispRow(6);
  ROW07 = dispRow(7);
  ROW08 = dispRow(8);
  ROW09 = dispRow(9);
  ROW10 = dispRow(10);
  ROW11 = dispRow(11);
  ROW12 = dispRow(12);
  ROW13 = dispRow(13);
  ROW14 = dispRow(14);
  ROW15 = dispRow(15);
  ROW16 = dispRow(16);
  ROW17 = dispRow(17);
  ROW18 = dispRow(18);
  ROW19 = dispRow(19);
  ROW20 = dispRow(20);
  // Overlay player cursor 'O' without storing in dispRow
  select;
    when pRow = 1;
      %subst(ROW01: pCol: 1) = 'O';
    when pRow = 2;
      %subst(ROW02: pCol: 1) = 'O';
    when pRow = 3;
      %subst(ROW03: pCol: 1) = 'O';
    when pRow = 4;
      %subst(ROW04: pCol: 1) = 'O';
    when pRow = 5;
      %subst(ROW05: pCol: 1) = 'O';
    when pRow = 6;
      %subst(ROW06: pCol: 1) = 'O';
    when pRow = 7;
      %subst(ROW07: pCol: 1) = 'O';
    when pRow = 8;
      %subst(ROW08: pCol: 1) = 'O';
    when pRow = 9;
      %subst(ROW09: pCol: 1) = 'O';
    when pRow = 10;
      %subst(ROW10: pCol: 1) = 'O';
    when pRow = 11;
      %subst(ROW11: pCol: 1) = 'O';
    when pRow = 12;
      %subst(ROW12: pCol: 1) = 'O';
    when pRow = 13;
      %subst(ROW13: pCol: 1) = 'O';
    when pRow = 14;
      %subst(ROW14: pCol: 1) = 'O';
    when pRow = 15;
      %subst(ROW15: pCol: 1) = 'O';
    when pRow = 16;
      %subst(ROW16: pCol: 1) = 'O';
    when pRow = 17;
      %subst(ROW17: pCol: 1) = 'O';
    when pRow = 18;
      %subst(ROW18: pCol: 1) = 'O';
    when pRow = 19;
      %subst(ROW19: pCol: 1) = 'O';
    when pRow = 20;
      %subst(ROW20: pCol: 1) = 'O';
  endsl;
endsr;

// -------------------------------------------------------
// Count mines in all 8 surrounding cells
// -------------------------------------------------------
dcl-proc nearbyCount;
  dcl-pi *n int(3);
    r int(3) value;
    c int(3) value;
  end-pi;

  dcl-s count int(3) inz(0);
  dcl-s dr    int(3);
  dcl-s dc    int(3);
  dcl-s nr    int(3);
  dcl-s nc    int(3);

  for dr = -1 to 1;
    for dc = -1 to 1;
      if dr = 0 and dc = 0;
        iter;
      endif;
      nr = r + dr;
      nc = c + dc;
      if nr >= 1 and nr <= ROWS and nc >= 1 and nc <= COLS;
        if %subst(mineRow(nr): nc: 1) = 'M';
          count += 1;
        endif;
      endif;
    endfor;
  endfor;

  return count;
end-proc;
