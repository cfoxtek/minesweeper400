# Mines — IBM i Minesweeper

Four versions of a Minesweeper game for IBM i (AS/400), all running natively on a POWER system via [pub400.com](https://pub400.com).

## Files

| File | Language | Display File | Description |
|------|----------|--------------|-------------|
| `mines_original.cbl` | IBM Cobol/400 | `minesw_original.dds` → `MINESW` | Original game by Ales Linda, 1999. Found in `GAMES400` library on pub400.com. |
| `minesw_original.dds` | DDS | — | Display file for the original game. Reconstructed from the compiled object — original source was not preserved. |
| `mines2.rpgle` | ILE RPG (free-format) | `minesd.dds` → `MINESD` | Rewrite with modern rules: WASD movement, Enter to reveal, flood fill, safe first move, win condition. |
| `mines2c.cbl` | IBM ILE COBOL | `minesd.dds` → `MINESD` | Exact port of `mines2.rpgle` to ILE COBOL. Same logic, compiled with `CRTBNDCBL`. |
| `mines2d.cbl` | IBM Cobol/400 (OPM) | `minesd.dds` → `MINESD` | Port of `mines2c.cbl` to OPM Cobol/400 style, compiled with `CRTCBLPGM`. |
| `minesd.dds` | DDS | — | Display file shared by `mines2.rpgle`, `mines2c.cbl`, and `mines2d.cbl`. Must be compiled first. |

## The Original (1999)

Written by Ales Linda (`linda@its.cz`) for the NEWS/400 Games Pack. Compiled May 16, 1999 by user `CHUCK` on system `S1038805`. The object sat in `GAMES400/MINES` on pub400.com for 26 years and has been played 807 days.

Gameplay: move with numeric keys `1/2/3/5`, reach the exit gate at the top center without hitting a mine (`¤`). Press Space or Enter to activate the boss key (fake WRKSPLF screen).

## The Rewrite (mines2 / mines2c / mines2d)

A modernized version with classic Minesweeper rules:

- **WASD** to move cursor, **Enter** to reveal a cell
- Mines are placed *after* the first reveal, guaranteeing a safe start
- Flood fill auto-reveals adjacent zero-count cells
- Win by revealing all safe cells
- **F5** to start a new game, **F3** to exit

All three rewrite versions are functionally identical and share the same `MINESD` display file.

## Running on pub400.com

```
CALL GAMES400/MINES    -- original 1999 COBOL version
CALL CFOX1/MINES2      -- ILE RPG rewrite
CALL CFOX1/MINES2C     -- ILE COBOL rewrite (CRTBNDCBL)
CALL CFOX1/MINES2D     -- OPM Cobol/400 rewrite (CRTCBLPGM)
```

Requires a TN5250 emulator (e.g. [tn5250j](http://tn5250j.sourceforge.net/), [Mochasoft](https://www.mochasoft.dk/), or IBM i Access).

## Compiler Notes

- Original: `CRTCBLPGM` (Cobol/400, OPM)
- RPG rewrite: `CRTBNDRPG` (ILE RPG, free-format `**FREE`)
- ILE COBOL rewrite (`mines2c`): `CRTBNDCBL` (IBM ILE COBOL, `5770WDS`)
- OPM COBOL rewrite (`mines2d`): `CRTCBLPGM` (IBM Cobol/400, OPM)

The ILE COBOL compiler (`5770WDS`) required two workarounds compared to the RPG version:
1. `STATUS` is a reserved word in ILE COBOL — the DDS field was renamed to `STATLN`
2. Reference modification cannot be used directly on COPY DDS fields — a working storage intermediate is used for the cursor overlay

Converting `mines2c` (ILE COBOL) to `mines2d` (OPM Cobol/400) required two changes:
1. `COMP-5` → `COMP` for large binary arithmetic variables (`SEED`, `SEED-WORK`, `SEED-REM`)
2. `CONTINUE` is not available in OPM Cobol/400 — restructured with `IF NOT (condition)` logic instead
