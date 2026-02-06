       IDENTIFICATION DIVISION.
       PROGRAM-ID. RWDRPT.
       AUTHOR. Gemini Code Assist.
      ******************************************************************
      * This program is a placeholder for a future rewards report
      * generator. It reads a rewards balance file (master) and a
      * points activity file (transactional) to produce a formatted
      * report.
      *
      * This program assumes that the REWPOINT file is sorted by
      * customer ID.
      ******************************************************************
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT REWBALAN-FILE ASSIGN TO REWBALAN
               ORGANIZATION IS INDEXED
               ACCESS MODE IS SEQUENTIAL
               RECORD KEY IS RB-CUST-ID
               FILE STATUS IS FS-REWBALAN.

           SELECT REWPOINT-FILE ASSIGN TO REWPOINT
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS FS-REWPOINT.

           SELECT RWDSTATM-FILE ASSIGN TO RWDSTATM
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS FS-RWDSTATM.

       DATA DIVISION.
       FILE SECTION.
       FD  REWBALAN-FILE.
       01  REWBALAN-REC.
           05 RB-CUST-ID         PIC 9(09).
           05 RB-CARD-NUM        PIC X(16).
           05 RB-BALANCE-PTS     PIC S9(9)V99.
           05 RB-LAST-UPDATE-TS  PIC X(26).

       FD  REWPOINT-FILE.
       01  REWPOINT-REC.
           05 RP-CUST-ID         PIC 9(09).
           05 RP-CARD-NUM        PIC X(16).
           05 RP-TRAN-ID         PIC X(16).
           05 RP-TRAN-TS         PIC X(26).
           05 RP-TRAN-DESC       PIC X(50).
           05 RP-POINTS-EARNED   PIC S9(7)V99.

       FD  RWDSTATM-FILE.
       01  RWDSTATM-REC          PIC X(132).

       WORKING-STORAGE SECTION.
       01  WS-FILE-STATUS.
           05 FS-REWBALAN        PIC X(02).
              88 FS-REWBALAN-OK         VALUE '00'.
              88 FS-REWBALAN-EOF        VALUE '10'.
           05 FS-REWPOINT        PIC X(02).
              88 FS-REWPOINT-OK         VALUE '00'.
              88 FS-REWPOINT-EOF        VALUE '10'.
           05 FS-RWDSTATM        PIC X(02).
              88 FS-RWDSTATM-OK         VALUE '00'.

       01  WS-REPORT-LINE        PIC X(132).
       01  WS-CURRENT-CUST-ID    PIC 9(09).
       01  WS-PAGE-COUNT         PIC 9(04) VALUE 0.
       01  WS-LINE-COUNT         PIC 9(02) VALUE 99.
       01  WS-LINES-PER-PAGE     PIC 9(02) VALUE 55.
       01  WS-CUST-POINTS-TOTAL  PIC S9(9)V99 VALUE ZERO.

       01  H1-HEADER-LINE.
           05 FILLER             PIC X(01) VALUE ' '.
           05 FILLER             PIC X(20) VALUE 'REWARDS STATEMENT'.
           05 FILLER             PIC X(89) VALUE SPACES.
           05 FILLER             PIC X(05) VALUE 'PAGE:'.
           05 H1-PAGE-NUM        PIC ZZZ9.
           05 FILLER             PIC X(13) VALUE SPACES.

       01  H2-CUST-HEADER.
           05 FILLER             PIC X(01) VALUE ' '.
           05 FILLER             PIC X(13) VALUE 'CUSTOMER ID: '.
           05 H2-CUST-ID         PIC 9(09).
           05 FILLER             PIC X(10) VALUE SPACES.
           05 FILLER             PIC X(11) VALUE 'CARD NUM: '.
           05 H2-CARD-NUM        PIC X(16).
           05 FILLER             PIC X(10) VALUE SPACES.
           05 FILLER             PIC X(15) VALUE 'TOTAL POINTS: '.
           05 H2-BALANCE-PTS     PIC Z,ZZZ,ZZ9.99.
           05 FILLER             PIC X(36) VALUE SPACES.

       01  H3-DETAIL-HEADER.
           05 FILLER             PIC X(01) VALUE ' '.
           05 FILLER             PIC X(26) VALUE 'TRANSACTION DATE'.
           05 FILLER             PIC X(05) VALUE SPACES.
           05 FILLER             PIC X(50) VALUE 'DESCRIPTION'.
           05 FILLER             PIC X(05) VALUE SPACES.
           05 FILLER             PIC X(15) VALUE 'POINTS EARNED'.
           05 FILLER             PIC X(30) VALUE SPACES.

       01  H4-DETAIL-UNDERLINE.
           05 FILLER             PIC X(01) VALUE ' '.
           05 FILLER             PIC X(26) VALUE ALL '-'.
           05 FILLER             PIC X(05) VALUE SPACES.
           05 FILLER             PIC X(50) VALUE ALL '-'.
           05 FILLER             PIC X(05) VALUE SPACES.
           05 FILLER             PIC X(15) VALUE ALL '-'.
           05 FILLER             PIC X(30) VALUE SPACES.

       01  D1-DETAIL-LINE.
           05 FILLER             PIC X(01) VALUE ' '.
           05 D1-TRAN-TS         PIC X(26).
           05 FILLER             PIC X(05) VALUE SPACES.
           05 D1-TRAN-DESC       PIC X(50).
           05 FILLER             PIC X(05) VALUE SPACES.
           05 D1-POINTS-EARNED   PIC +++,++9.99.
           05 FILLER             PIC X(34) VALUE SPACES.

       01  S1-SUMMARY-LINE.
           05 FILLER             PIC X(83) VALUE SPACES.
           05 FILLER             PIC X(25) VALUE 'TOTAL POINTS THIS PERIOD:'.
           05 S1-TOTAL-POINTS    PIC +++,+++,++9.99.
           05 FILLER             PIC X(10) VALUE SPACES.

       PROCEDURE DIVISION.
       0000-MAIN-PROCEDURE.
           PERFORM 1000-INITIALIZE.
           PERFORM 2000-PROCESS-RECORDS UNTIL FS-REWBALAN-EOF.
           PERFORM 3000-TERMINATE.
           GOBACK.

       1000-INITIALIZE.
           OPEN INPUT REWBALAN-FILE REWPOINT-FILE.
           OPEN OUTPUT RWDSTATM-FILE.
           PERFORM 9100-CHECK-FILE-STATUS.
           READ REWBALAN-FILE.
           READ REWPOINT-FILE.
           PERFORM 9100-CHECK-FILE-STATUS.

       2000-PROCESS-RECORDS.
           MOVE RB-CUST-ID TO WS-CURRENT-CUST-ID.
           INITIALIZE WS-CUST-POINTS-TOTAL.
           PERFORM 2100-PRINT-PAGE-HEADER.
           PERFORM 2200-PRINT-CUST-HEADER.

           PERFORM 2300-PROCESS-POINTS
               UNTIL FS-REWPOINT-EOF OR
                     RP-CUST-ID NOT = WS-CURRENT-CUST-ID.

           MOVE WS-CUST-POINTS-TOTAL TO S1-TOTAL-POINTS.
           WRITE RWDSTATM-REC FROM S1-SUMMARY-LINE
               AFTER ADVANCING 2 LINES.

           WRITE RWDSTATM-REC FROM ' ' AFTER ADVANCING 1 LINE.
           ADD 3 TO WS-LINE-COUNT.

           READ REWBALAN-FILE.

       2100-PRINT-PAGE-HEADER.
           IF WS-LINE-COUNT > WS-LINES-PER-PAGE
               ADD 1 TO WS-PAGE-COUNT
               MOVE WS-PAGE-COUNT TO H1-PAGE-NUM
               WRITE RWDSTATM-REC FROM H1-HEADER-LINE
                   AFTER ADVANCING PAGE
               MOVE 2 TO WS-LINE-COUNT
           END-IF.

       2200-PRINT-CUST-HEADER.
           MOVE RB-CUST-ID TO H2-CUST-ID.
           MOVE RB-CARD-NUM TO H2-CARD-NUM.
           MOVE RB-BALANCE-PTS TO H2-BALANCE-PTS.
           WRITE RWDSTATM-REC FROM H2-CUST-HEADER
               AFTER ADVANCING 2 LINES.
           WRITE RWDSTATM-REC FROM ' ' AFTER ADVANCING 1 LINE.
           WRITE RWDSTATM-REC FROM H3-DETAIL-HEADER
               AFTER ADVANCING 1 LINE.
           WRITE RWDSTATM-REC FROM H4-DETAIL-UNDERLINE
               AFTER ADVANCING 1 LINE.
           ADD 5 TO WS-LINE-COUNT.

       2300-PROCESS-POINTS.
           IF WS-LINE-COUNT > WS-LINES-PER-PAGE
               PERFORM 2100-PRINT-PAGE-HEADER
           END-IF.

           MOVE RP-TRAN-TS TO D1-TRAN-TS.
           MOVE RP-TRAN-DESC TO D1-TRAN-DESC.
           MOVE RP-POINTS-EARNED TO D1-POINTS-EARNED.
           ADD RP-POINTS-EARNED TO WS-CUST-POINTS-TOTAL.
           WRITE RWDSTATM-REC FROM D1-DETAIL-LINE
               AFTER ADVANCING 1 LINE.
           ADD 1 TO WS-LINE-COUNT.

           READ REWPOINT-FILE.

       3000-TERMINATE.
           CLOSE REWBALAN-FILE REWPOINT-FILE RWDSTATM-FILE.

       9100-CHECK-FILE-STATUS.
           IF NOT FS-REWBALAN-OK AND NOT FS-REWBALAN-EOF
               DISPLAY 'ERROR: REWBALAN FILE STATUS ' FS-REWBALAN
               MOVE 16 TO RETURN-CODE
               PERFORM 3000-TERMINATE
               GOBACK
           END-IF.
           IF NOT FS-REWPOINT-OK AND NOT FS-REWPOINT-EOF
               DISPLAY 'ERROR: REWPOINT FILE STATUS ' FS-REWPOINT
               MOVE 16 TO RETURN-CODE
               PERFORM 3000-TERMINATE
               GOBACK
           END-IF.
           IF NOT FS-RWDSTATM-OK
               DISPLAY 'ERROR: RWDSTATM FILE STATUS ' FS-RWDSTATM
               MOVE 16 TO RETURN-CODE
               PERFORM 3000-TERMINATE
               GOBACK
           END-IF.