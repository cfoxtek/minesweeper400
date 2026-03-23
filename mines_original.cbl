       IDENTIFICATION DIVISION.
      *****************************************************************
      *  MINES FIELD - Simple game for bored AS400 users              *
      *---------------------------------------------------------------*
      *  COMPILER:  Cobol/400                                         *
      *                                                               *
      *  AUTHOR:    Ales Linda   (e-mail: linda@its.cz)               *
      *                                                               *
      *  DESCR.:    Player is moving from the center of bottom row    *
      *             on the screen, using numeric keys 1,2,3,5.        *
      *             On each player's position, the indicator on       *
      *             the top right corner shows number of mines in     *
      *             player's cross neighborhood. The goal is to       *
      *             reach the exit gate placed in the center of top   *
      *             row. Player can get helpful hint by pressing      *
      *             F10=Show mines in neighborhood, or F11=Show/Hide  *
      *             all mines. Pressing Space or Enter will show      *
      *             AS/400 WRKSPLF screen (only replica), in the      *
      *             case when boss is coming.                         *
      *                                                               *
      *  CHARACTERS:  O  ...  player                                  *
      *               ¤  ...  mine                                    *
      *                                                               *
      *  COMPILED:  1999-05-16  (GAMES400/MINES, user CHUCK)          *
      *                                                               *
      *****************************************************************
       PROGRAM-ID. MINES.
       AUTHOR. ALES LINDA.
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-AS400.
       OBJECT-COMPUTER. IBM-AS400.
       SPECIAL-NAMES.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
            SELECT WS ASSIGN TO WORKSTATION-MINESW
                 ORGANIZATION IS TRANSACTION
                 ACCESS  MODE IS SEQUENTIAL
                 CONTROL-AREA IS WS-CONTROL.
       DATA DIVISION.
       FILE SECTION.
       FD  WS.
       01  WS-REC PIC X(1800).
       WORKING-STORAGE SECTION.
       01  MINESW01-O-FORMAT.
           COPY DDS-MINESW01-O OF MINESW.
       01  WS-REC01 REDEFINES MINESW01-O-FORMAT.
           03 WS-OPTION    PIC X.
           03 WS-COUNT     PIC 9.
           03 WS-TABLE.
              05 WS-ROW OCCURS 21.
                 07 WS-CHAR  OCCURS 79  PIC X.
           03 WS-MSG    PIC X(75).
       01  MINESW01-I-FORMAT.
           COPY DDS-MINESW01-I OF MINESW.
       01  MINESW02-O-FORMAT.
           COPY DDS-MINESW02-O OF MINESW.
       01  MINESW02-I-FORMAT.
           COPY DDS-MINESW02-I OF MINESW.

       01  TABLE1.
           03 ROW OCCURS 21.
              05 CHAR  OCCURS 79  PIC X.

       01  INDICATOR-AREA.
           05 IN03        PIC 1 INDIC 03.
              88 CMD3         VALUE B"1".
           05 IN05        PIC 1 INDIC 05.
              88 CMD5         VALUE B"1".
           05 IN10        PIC 1 INDIC 10.
              88 CMD10        VALUE B"1".
           05 IN11        PIC 1 INDIC 11.
              88 CMD11        VALUE B"1".
           05 IN12        PIC 1 INDIC 12.
              88 CMD12        VALUE B"1".
       01  WS-CONTROL.
           05 BEF-TASTEN           PIC XX.
              88 DOPR              VALUE "05".
           05 WKST-ID              PIC X(10) VALUE SPACES.
           05 REC-FMT              PIC X(10) VALUE SPACES.
       77  X           PIC S99.
       77  Y           PIC S99.
       77  R           PIC S99.
       77  S           PIC S99.
       77  ZPRAVA      PIC 9.
       77  SHOW        PIC 9.
       77  POMER1      PIC S999V9999.
       77  POMER2      PIC S999V9999.
       01  POMER3      PIC S999V9999.
       01  POMER3R REDEFINES POMER3.
           03  FILLER   PIC X(6).
           03  CISLO    PIC 9.
       01  TIM.
           03 TIM-HH    PIC 99.
           03 TIM-MM    PIC 99.
           03 TIM-SS    PIC 99.
       PROCEDURE DIVISION.
       MAIN SECTION.
       BEG.
           OPEN I-O WS.
           PERFORM FILL-FIELDS.
       LOOP.
           MOVE SPACE TO VOLBA OF MINESW01-O.
           PERFORM WR-SCREEN.
           IF CMD3 OR CMD12 GO TO ENDING.
           IF CMD5 PERFORM FILL-FIELDS GO TO LOOP.
           IF CMD11 AND SHOW = 0 PERFORM SHOW-MINES
                    VARYING X FROM 2 BY 1 UNTIL X > 20
                    MOVE 1 TO SHOW GO TO LOOP.
           IF CMD11 AND SHOW = 1 PERFORM HIDE-MINES
                    VARYING X FROM 2 BY 1 UNTIL X > 20
                    MOVE 0 TO SHOW GO TO LOOP.
           IF CMD10 PERFORM WAS-CMD10 GO TO LOOP.
           IF VOLBA OF MINESW01-O = " " PERFORM BOSS-KEY GO TO LOOP.
           IF CHAR(R S) = "@" GO TO LOOP.
           IF VOLBA OF MINESW01-O = "1" PERFORM MOV-LEFT GO TO LOOP.
           IF VOLBA OF MINESW01-O = "3" PERFORM MOV-RIGHT GO TO LOOP.
           IF VOLBA OF MINESW01-O = "2" PERFORM MOV-DOWN GO TO LOOP.
           IF VOLBA OF MINESW01-O = "5" PERFORM MOV-UP GO TO LOOP.
       ENDING.
           CLOSE WS.
           STOP RUN.
      * ===============================================================
       FILL-FIELDS SECTION.
       PP. INITIALIZE TABLE1 WS-REC01.
           MOVE ZERO TO ZPRAVA SHOW.
           MOVE 2 TO WS-COUNT.
           MOVE ALL "¤" TO ROW(1) ROW(21) WS-ROW(1) WS-ROW(21).
           MOVE SPACE TO CHAR(1 39) WS-CHAR(1 39).
           MOVE 21 TO R.
           MOVE 39 TO S.
           MOVE "O" TO CHAR(R S) WS-CHAR(R S).
           PERFORM LAYDN-MINES VARYING X FROM 2 BY 1 UNTIL X > 20.
           MOVE SPACE TO CHAR(20 38) CHAR(20 39) CHAR(20 40).
           MOVE SPACE TO CHAR(2 38) CHAR (2 39) CHAR(2 40).
           MOVE SPACE TO CHAR(3 39) CHAR (19 39).
           MOVE "Do not move cursor, use numeric keys 1235 for moving"
                                                       TO WS-MSG.
       PP-EX. EXIT.
      * ---------------------------------------------------------------
       MOV-LEFT SECTION.
       MLE.
           IF S = 1 GO TO MLE-EX.
           MOVE "+" TO CHAR(R S) WS-CHAR(R S).
           SUBTRACT 1 FROM S.
           PERFORM MOVING.
       MLE-EX. EXIT.
      * ---------------------------------------------------------------
       MOV-RIGHT SECTION.
       MRT.
           IF S = 79 GO TO MRT-EX.
           MOVE "+" TO CHAR(R S) WS-CHAR(R S).
           ADD 1 TO S.
           PERFORM MOVING.
       MRT-EX. EXIT.
      * ---------------------------------------------------------------
       MOV-DOWN SECTION.
       MDN.
           IF R = 21 GO TO MDN-EX.
           MOVE "+" TO CHAR(R S) WS-CHAR(R S).
           ADD 1 TO R.
           PERFORM MOVING.
       MDN-EX. EXIT.
      * ---------------------------------------------------------------
       MOV-UP SECTION.
       MUP.
           IF R = 1 GO TO MUP-EX.
           MOVE "+" TO CHAR(R S) WS-CHAR(R S).
           SUBTRACT 1 FROM R.
           PERFORM MOVING.
       MUP-EX. EXIT.
      * ---------------------------------------------------------------
       WAS-CMD10 SECTION.
       WC10.
           MOVE R TO X.
           MOVE S TO Y.
           IF R < 21 ADD 1 TO R
              IF CHAR(R S) = "¤" MOVE CHAR(R S) TO WS-CHAR(R S) END-IF
              SUBTRACT 1 FROM R.
           IF R > 1 SUBTRACT 1 FROM R
              IF CHAR(R S) = "¤" MOVE CHAR(R S) TO WS-CHAR(R S) END-IF
              ADD 1 TO R.
           IF S < 79 ADD 1 TO S
              IF CHAR(R S) = "¤" MOVE CHAR(R S) TO WS-CHAR(R S) END-IF
              SUBTRACT 1 FROM S.
           IF S > 1 SUBTRACT 1 FROM S
              IF CHAR(R S) = "¤" MOVE CHAR(R S) TO WS-CHAR(R S) END-IF
              ADD 1 TO S.
           MOVE X TO R.
           MOVE Y TO S.
      * ---------------------------------------------------------------
       MOVING SECTION.
       MV.
           IF R = 1 AND S = 39 MOVE "@" TO CHAR(R S) WS-CHAR(R S)
               MOVE "YOU WIN] ... SUCCESS] ..." TO WS-MSG
               MOVE 1 TO ZPRAVA GO TO MV-EX.
           IF CHAR(R S) = "¤" MOVE "@" TO CHAR(R S) WS-CHAR(R S)
                  MOVE "BANG] ... PLAYER DIED ..." TO WS-MSG
                  MOVE 1 TO ZPRAVA
            ELSE MOVE "O" TO CHAR(R S) WS-CHAR(R S)
                 PERFORM GET-COUNT.
       MV-EX. EXIT.
      * ---------------------------------------------------------------
       GET-COUNT SECTION.
       GC. MOVE R TO X.
           MOVE S TO Y.
           MOVE ZERO TO WS-COUNT.
           IF R < 21 ADD 1 TO R
                     IF CHAR(R S) = "¤" ADD 1 TO WS-COUNT  END-IF
                     SUBTRACT 1 FROM R.
           IF R > 1 SUBTRACT 1 FROM R
                     IF CHAR(R S) = "¤" ADD 1 TO WS-COUNT  END-IF
                     ADD 1 TO R.
           IF S < 79 ADD 1 TO S
                     IF CHAR(R S) = "¤" ADD 1 TO WS-COUNT  END-IF
                     SUBTRACT 1 FROM S.
           IF S > 1 SUBTRACT 1 FROM S
                     IF CHAR(R S) = "¤" ADD 1 TO WS-COUNT  END-IF
                     ADD 1 TO S.
           MOVE X TO R.
           MOVE Y TO S.
      * ---------------------------------------------------------------
       LAYDN-MINES SECTION.
       LM. MOVE ZERO TO Y.
           ACCEPT TIM FROM TIME.
       LM1.
           ADD 1 TO Y.
           IF Y > 79 GO TO LM-EX.
           COMPUTE POMER1 = (X + TIM-MM + TIM-SS + TIM-HH) / 13.
           COMPUTE POMER2 = (Y + TIM-MM + TIM-SS + TIM-HH) / 17.
           COMPUTE POMER3 = POMER1 / POMER2.
           IF CISLO = 2 OR 9 MOVE "¤" TO CHAR(X Y).
           GO TO LM1.
       LM-EX. EXIT.
      * ---------------------------------------------------------------
       SHOW-MINES SECTION.
       SM. MOVE ZERO TO Y.
       SM1.
           ADD 1 TO Y.
           IF Y > 79 GO TO SM-EX.
           IF CHAR(X Y) = "¤" MOVE CHAR(X Y) TO WS-CHAR(X Y).
           GO TO SM1.
       SM-EX. EXIT.
      * ---------------------------------------------------------------
       HIDE-MINES SECTION.
       HM. MOVE ZERO TO Y.
       HM1.
           ADD 1 TO Y.
           IF Y > 79 GO TO HM-EX.
           IF WS-CHAR(X Y) = "¤" MOVE SPACE TO WS-CHAR(X Y).
           GO TO HM1.
       HM-EX. EXIT.
      * ---------------------------------------------------------------
       WR-SCREEN SECTION.
       WRITE-OBR.
           WRITE WS-REC FROM MINESW01-O-FORMAT FORMAT IS "MINESW01".
       READ-OBR.
           READ WS INTO MINESW01-I-FORMAT.
           MOVE CORR MINESW01-I-INDIC TO INDICATOR-AREA.
           MOVE CORR MINESW01-I TO MINESW01-O.
      * ---------------------------------------------------------------
       BOSS-KEY SECTION.
       WRITE-OB2.
           WRITE WS-REC FROM MINESW02-O-FORMAT FORMAT IS "MINESW02".
           READ WS INTO MINESW02-I-FORMAT.
           MOVE CORR MINESW02-I-INDIC TO INDICATOR-AREA.
           IF CMD3 OR CMD12 GO TO ENDING.
      * ----End of source---------------------------------------------*
