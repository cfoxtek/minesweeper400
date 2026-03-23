       IDENTIFICATION DIVISION.
      *****************************************************************
      *  MINES2C - Minesweeper for IBM i (COBOL version of MINES2)   *
      *  CFOX1 library - by cfox                                      *
      *  Move with WASD. Press Enter to reveal a cell.               *
      *  Reveal all safe cells to win.                                *
      *****************************************************************
       PROGRAM-ID. MINES2C.
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-AS400.
       OBJECT-COMPUTER. IBM-AS400.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT WS ASSIGN TO WORKSTATION-MINESD
               ORGANIZATION IS TRANSACTION
               ACCESS MODE IS SEQUENTIAL
               CONTROL-AREA IS WS-CONTROL.
       DATA DIVISION.
       FILE SECTION.
       FD  WS.
       01  WS-REC PIC X(4096).
       WORKING-STORAGE SECTION.
       01  GAMESCREEN-O-FORMAT.
           COPY DDS-GAMESCREEN-O OF MINESD.
       01  GAMESCREEN-I-FORMAT.
           COPY DDS-GAMESCREEN-I OF MINESD.
       01  WS-CONTROL.
           05 BEF-TASTEN     PIC XX.
           05 WKST-ID        PIC X(10) VALUE SPACES.
           05 REC-FMT        PIC X(10) VALUE SPACES.
       01  INDICATOR-AREA.
           05 IN03           PIC 1 INDIC 03.
              88 F3-EXIT         VALUE B"1".
           05 IN05           PIC 1 INDIC 05.
              88 F5-NEW-GAME     VALUE B"1".
      * Board grids
       01  MINE-GRID.
           03 MINE-ROW       PIC X(40) OCCURS 20.
       01  DISP-GRID.
           03 DISP-ROW       PIC X(40) OCCURS 20.
      * Player position
       77  P-ROW             PIC S9(4) COMP.
       77  P-COL             PIC S9(4) COMP.
      * Game state
       77  GAME-OVER-F       PIC X VALUE 'N'.
           88 GAME-OVER          VALUE 'Y'.
       77  FIRST-MOVE-F      PIC X VALUE 'Y'.
           88 IS-FIRST-MOVE      VALUE 'Y'.
      * Working variables
       01  TIM.
           03 TIM-HH         PIC 99.
           03 TIM-MM         PIC 99.
           03 TIM-SS         PIC 99.
           03 TIM-HS         PIC 99.
       77  SEED              PIC S9(18) COMP-5.
       77  SEED-WORK         PIC S9(18) COMP-5.
       77  SEED-REM          PIC S9(18) COMP-5.
       77  CNT               PIC S9(4) COMP.
       77  R                 PIC S9(4) COMP.
       77  C                 PIC S9(4) COMP.
       77  DR                PIC S9(4) COMP.
       77  DC                PIC S9(4) COMP.
       77  NR                PIC S9(4) COMP.
       77  NC                PIC S9(4) COMP.
       77  TOTAL-SAFE        PIC S9(5) COMP.
       77  REVEALED-SAFE     PIC S9(5) COMP.
       77  CHANGED-F         PIC X.
           88 HAS-CHANGED        VALUE 'Y'.
       77  NEARBY-COUNT      PIC S9(4) COMP.
       77  NB-DR             PIC S9(4) COMP.
       77  NB-DC             PIC S9(4) COMP.
       77  NB-NR             PIC S9(4) COMP.
       77  NB-NC             PIC S9(4) COMP.
       77  NB-R              PIC S9(4) COMP.
       77  NB-C              PIC S9(4) COMP.
       77  COUNT-CHARS       PIC X(8)  VALUE '12345678'.
       77  COUNT-DISP        PIC Z9.
       77  LEFT-DISP         PIC Z9.
       77  ROW-DISP          PIC Z9.
       77  COL-DISP          PIC Z9.
       77  LEFT-COUNT        PIC S9(5) COMP.
       77  KEYIN-WORK        PIC X.
       PROCEDURE DIVISION.
       MAIN SECTION.
       BEG.
           OPEN I-O WS.
           PERFORM INIT-GAME.
       MAIN-LOOP.
           PERFORM RENDER-BOARD.
           IF IS-FIRST-MOVE
               MOVE 'Move cursor. Press Enter to reveal.'
                   TO STATLN OF GAMESCREEN-O
           ELSE
               PERFORM CALC-STATUS
           END-IF.
           MOVE SPACES TO KEYIN OF GAMESCREEN-O.
           WRITE WS-REC FROM GAMESCREEN-O-FORMAT
               FORMAT IS "GAMESCREEN".
           READ WS INTO GAMESCREEN-I-FORMAT.
           MOVE CORR GAMESCREEN-I-INDIC TO INDICATOR-AREA.
           MOVE CORR GAMESCREEN-I TO GAMESCREEN-O.
           IF F3-EXIT GO TO ENDING.
           IF F5-NEW-GAME PERFORM INIT-GAME GO TO MAIN-LOOP.
           IF GAME-OVER GO TO MAIN-LOOP.
           MOVE KEYIN OF GAMESCREEN-O TO KEYIN-WORK.
           EVALUATE TRUE
               WHEN KEYIN-WORK = SPACES
                   PERFORM REVEAL-CELL
               WHEN KEYIN-WORK = 'A' OR 'a'
                   IF P-COL > 1 SUBTRACT 1 FROM P-COL END-IF
               WHEN KEYIN-WORK = 'D' OR 'd'
                   IF P-COL < 40 ADD 1 TO P-COL END-IF
               WHEN KEYIN-WORK = 'W' OR 'w'
                   IF P-ROW > 1 SUBTRACT 1 FROM P-ROW END-IF
               WHEN KEYIN-WORK = 'S' OR 's'
                   IF P-ROW < 20 ADD 1 TO P-ROW END-IF
           END-EVALUATE.
           GO TO MAIN-LOOP.
       ENDING.
           CLOSE WS.
           STOP RUN.
      * ---------------------------------------------------------------
       INIT-GAME SECTION.
       IG.
           MOVE 'N' TO GAME-OVER-F.
           MOVE 'Y' TO FIRST-MOVE-F.
           MOVE SPACES TO MESSAGE OF GAMESCREEN-O.
           MOVE SPACES TO STATLN OF GAMESCREEN-O.
           MOVE 0 TO TOTAL-SAFE REVEALED-SAFE.
           PERFORM VARYING R FROM 1 BY 1 UNTIL R > 20
               MOVE SPACES TO MINE-ROW(R)
               MOVE '........................................'
                   TO DISP-ROW(R)
           END-PERFORM.
           ACCEPT TIM FROM TIME.
           MOVE TIM-HS TO SEED.
           IF SEED = 0 MOVE 77777 TO SEED END-IF.
           MOVE 10 TO P-ROW.
           MOVE 20 TO P-COL.
       IG-EX. EXIT.
      * ---------------------------------------------------------------
       PLACE-MINES SECTION.
       PM.
           PERFORM VARYING R FROM 1 BY 1 UNTIL R > 20
               PERFORM VARYING C FROM 1 BY 1 UNTIL C > 40
                   IF R >= P-ROW - 1 AND R <= P-ROW + 1 AND
                      C >= P-COL - 1 AND C <= P-COL + 1
                       CONTINUE
                   ELSE
                       COMPUTE SEED-WORK =
                           SEED * 1103515245 + 12345
                       IF SEED-WORK < 0
                           COMPUTE SEED-WORK = -SEED-WORK
                       END-IF
                       DIVIDE SEED-WORK BY 2147483647
                           GIVING SEED-WORK REMAINDER SEED
                       DIVIDE SEED BY 7
                           GIVING SEED-WORK REMAINDER SEED-REM
                       IF SEED-REM = 0
                           MOVE 'M' TO MINE-ROW(R)(C:1)
                       END-IF
                   END-IF
               END-PERFORM
           END-PERFORM.
           MOVE 0 TO TOTAL-SAFE.
           PERFORM VARYING R FROM 1 BY 1 UNTIL R > 20
               PERFORM VARYING C FROM 1 BY 1 UNTIL C > 40
                   IF MINE-ROW(R)(C:1) NOT = 'M'
                       ADD 1 TO TOTAL-SAFE
                   END-IF
               END-PERFORM
           END-PERFORM.
       PM-EX. EXIT.
      * ---------------------------------------------------------------
       REVEAL-CELL SECTION.
       RC.
           IF DISP-ROW(P-ROW)(P-COL:1) NOT = '.'
               CONTINUE
           ELSE IF IS-FIRST-MOVE
               MOVE 'N' TO FIRST-MOVE-F
               PERFORM PLACE-MINES
               MOVE P-ROW TO NB-R
               MOVE P-COL TO NB-C
               PERFORM CALC-NEARBY
               MOVE NEARBY-COUNT TO CNT
               IF CNT = 0
                   MOVE '-' TO DISP-ROW(P-ROW)(P-COL:1)
               ELSE
                   MOVE COUNT-CHARS(CNT:1)
                       TO DISP-ROW(P-ROW)(P-COL:1)
               END-IF
               PERFORM FLOOD-FILL
               PERFORM CHECK-WIN
               MOVE SPACES TO MESSAGE OF GAMESCREEN-O
           ELSE IF MINE-ROW(P-ROW)(P-COL:1) = 'M'
               MOVE '*' TO DISP-ROW(P-ROW)(P-COL:1)
               MOVE 'Y' TO GAME-OVER-F
               MOVE
         '*** BOOM - Hit a mine - F5=New Game  F3=Exit ***'
                   TO MESSAGE OF GAMESCREEN-O
           ELSE
               MOVE P-ROW TO NB-R
               MOVE P-COL TO NB-C
               PERFORM CALC-NEARBY
               MOVE NEARBY-COUNT TO CNT
               IF CNT = 0
                   MOVE '-' TO DISP-ROW(P-ROW)(P-COL:1)
               ELSE
                   MOVE COUNT-CHARS(CNT:1)
                       TO DISP-ROW(P-ROW)(P-COL:1)
               END-IF
               PERFORM FLOOD-FILL
               PERFORM CHECK-WIN
               MOVE SPACES TO MESSAGE OF GAMESCREEN-O
           END-IF.
       RC-EX. EXIT.
      * ---------------------------------------------------------------
       FLOOD-FILL SECTION.
       FF.
           MOVE 'Y' TO CHANGED-F.
           PERFORM UNTIL NOT HAS-CHANGED
               MOVE 'N' TO CHANGED-F
               PERFORM VARYING R FROM 1 BY 1 UNTIL R > 20
                 PERFORM VARYING C FROM 1 BY 1 UNTIL C > 40
                   IF DISP-ROW(R)(C:1) = '-'
                     PERFORM VARYING DR FROM -1 BY 1 UNTIL DR > 1
                       PERFORM VARYING DC FROM -1 BY 1 UNTIL DC > 1
                         IF NOT (DR = 0 AND DC = 0)
                           COMPUTE NR = R + DR
                           COMPUTE NC = C + DC
                           IF NR >= 1 AND NR <= 20 AND
                              NC >= 1 AND NC <= 40 AND
                              DISP-ROW(NR)(NC:1) = '.' AND
                              MINE-ROW(NR)(NC:1) NOT = 'M'
                             MOVE NR TO NB-R
                             MOVE NC TO NB-C
                             PERFORM CALC-NEARBY
                             MOVE NEARBY-COUNT TO CNT
                             IF CNT = 0
                               MOVE '-' TO DISP-ROW(NR)(NC:1)
                             ELSE
                               MOVE COUNT-CHARS(CNT:1)
                                 TO DISP-ROW(NR)(NC:1)
                             END-IF
                             MOVE 'Y' TO CHANGED-F
                           END-IF
                         END-IF
                       END-PERFORM
                     END-PERFORM
                   END-IF
                 END-PERFORM
               END-PERFORM
           END-PERFORM.
       FF-EX. EXIT.
      * ---------------------------------------------------------------
       CHECK-WIN SECTION.
       CW.
           MOVE 0 TO REVEALED-SAFE.
           PERFORM VARYING R FROM 1 BY 1 UNTIL R > 20
               PERFORM VARYING C FROM 1 BY 1 UNTIL C > 40
                   IF DISP-ROW(R)(C:1) NOT = '.' AND
                      MINE-ROW(R)(C:1) NOT = 'M'
                       ADD 1 TO REVEALED-SAFE
                   END-IF
               END-PERFORM
           END-PERFORM.
           IF REVEALED-SAFE = TOTAL-SAFE
               MOVE 'Y' TO GAME-OVER-F
               MOVE
         '*** YOU WIN - All cells revealed - F5=New  F3=Exit ***'
                   TO MESSAGE OF GAMESCREEN-O
           END-IF.
       CW-EX. EXIT.
      * ---------------------------------------------------------------
       RENDER-BOARD SECTION.
       RB.
           MOVE DISP-ROW(1)  TO ROW01 OF GAMESCREEN-O.
           MOVE DISP-ROW(2)  TO ROW02 OF GAMESCREEN-O.
           MOVE DISP-ROW(3)  TO ROW03 OF GAMESCREEN-O.
           MOVE DISP-ROW(4)  TO ROW04 OF GAMESCREEN-O.
           MOVE DISP-ROW(5)  TO ROW05 OF GAMESCREEN-O.
           MOVE DISP-ROW(6)  TO ROW06 OF GAMESCREEN-O.
           MOVE DISP-ROW(7)  TO ROW07 OF GAMESCREEN-O.
           MOVE DISP-ROW(8)  TO ROW08 OF GAMESCREEN-O.
           MOVE DISP-ROW(9)  TO ROW09 OF GAMESCREEN-O.
           MOVE DISP-ROW(10) TO ROW10 OF GAMESCREEN-O.
           MOVE DISP-ROW(11) TO ROW11 OF GAMESCREEN-O.
           MOVE DISP-ROW(12) TO ROW12 OF GAMESCREEN-O.
           MOVE DISP-ROW(13) TO ROW13 OF GAMESCREEN-O.
           MOVE DISP-ROW(14) TO ROW14 OF GAMESCREEN-O.
           MOVE DISP-ROW(15) TO ROW15 OF GAMESCREEN-O.
           MOVE DISP-ROW(16) TO ROW16 OF GAMESCREEN-O.
           MOVE DISP-ROW(17) TO ROW17 OF GAMESCREEN-O.
           MOVE DISP-ROW(18) TO ROW18 OF GAMESCREEN-O.
           MOVE DISP-ROW(19) TO ROW19 OF GAMESCREEN-O.
           MOVE DISP-ROW(20) TO ROW20 OF GAMESCREEN-O.
           EVALUATE P-ROW
             WHEN  1 MOVE 'O' TO ROW01 OF GAMESCREEN-O(P-COL:1)
             WHEN  2 MOVE 'O' TO ROW02 OF GAMESCREEN-O(P-COL:1)
             WHEN  3 MOVE 'O' TO ROW03 OF GAMESCREEN-O(P-COL:1)
             WHEN  4 MOVE 'O' TO ROW04 OF GAMESCREEN-O(P-COL:1)
             WHEN  5 MOVE 'O' TO ROW05 OF GAMESCREEN-O(P-COL:1)
             WHEN  6 MOVE 'O' TO ROW06 OF GAMESCREEN-O(P-COL:1)
             WHEN  7 MOVE 'O' TO ROW07 OF GAMESCREEN-O(P-COL:1)
             WHEN  8 MOVE 'O' TO ROW08 OF GAMESCREEN-O(P-COL:1)
             WHEN  9 MOVE 'O' TO ROW09 OF GAMESCREEN-O(P-COL:1)
             WHEN 10 MOVE 'O' TO ROW10 OF GAMESCREEN-O(P-COL:1)
             WHEN 11 MOVE 'O' TO ROW11 OF GAMESCREEN-O(P-COL:1)
             WHEN 12 MOVE 'O' TO ROW12 OF GAMESCREEN-O(P-COL:1)
             WHEN 13 MOVE 'O' TO ROW13 OF GAMESCREEN-O(P-COL:1)
             WHEN 14 MOVE 'O' TO ROW14 OF GAMESCREEN-O(P-COL:1)
             WHEN 15 MOVE 'O' TO ROW15 OF GAMESCREEN-O(P-COL:1)
             WHEN 16 MOVE 'O' TO ROW16 OF GAMESCREEN-O(P-COL:1)
             WHEN 17 MOVE 'O' TO ROW17 OF GAMESCREEN-O(P-COL:1)
             WHEN 18 MOVE 'O' TO ROW18 OF GAMESCREEN-O(P-COL:1)
             WHEN 19 MOVE 'O' TO ROW19 OF GAMESCREEN-O(P-COL:1)
             WHEN 20 MOVE 'O' TO ROW20 OF GAMESCREEN-O(P-COL:1)
           END-EVALUATE.
       RB-EX. EXIT.
      * ---------------------------------------------------------------
       CALC-STATUS SECTION.
       CS.
           MOVE P-ROW TO NB-R.
           MOVE P-COL TO NB-C.
           PERFORM CALC-NEARBY.
           MOVE NEARBY-COUNT TO COUNT-DISP.
           COMPUTE LEFT-COUNT = TOTAL-SAFE - REVEALED-SAFE.
           MOVE LEFT-COUNT TO LEFT-DISP.
           MOVE P-ROW TO ROW-DISP.
           MOVE P-COL TO COL-DISP.
           STRING 'Nearby: '  DELIMITED SIZE
                  COUNT-DISP  DELIMITED SPACE
                  '   Left: ' DELIMITED SIZE
                  LEFT-DISP   DELIMITED SPACE
                  '   R:'     DELIMITED SIZE
                  ROW-DISP    DELIMITED SPACE
                  ' C:'       DELIMITED SIZE
                  COL-DISP    DELIMITED SPACE
               INTO STATLN OF GAMESCREEN-O.
       CS-EX. EXIT.
      * ---------------------------------------------------------------
       CALC-NEARBY SECTION.
       CN.
           MOVE 0 TO NEARBY-COUNT.
           PERFORM VARYING NB-DR FROM -1 BY 1 UNTIL NB-DR > 1
               PERFORM VARYING NB-DC FROM -1 BY 1 UNTIL NB-DC > 1
                   IF NOT (NB-DR = 0 AND NB-DC = 0)
                       COMPUTE NB-NR = NB-R + NB-DR
                       COMPUTE NB-NC = NB-C + NB-DC
                       IF NB-NR >= 1 AND NB-NR <= 20 AND
                          NB-NC >= 1 AND NB-NC <= 40
                           IF MINE-ROW(NB-NR)(NB-NC:1) = 'M'
                               ADD 1 TO NEARBY-COUNT
                           END-IF
                       END-IF
                   END-IF
               END-PERFORM
           END-PERFORM.
       CN-EX. EXIT.
