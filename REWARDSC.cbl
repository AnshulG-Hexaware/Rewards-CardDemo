       IDENTIFICATION DIVISION.
       PROGRAM-ID. REWARDSC.
       AUTHOR. Gemini Code Assist.
      ******************************************************************
      * This program reads the CardDemo transaction file, calculates
      * loyalty points based on defined rules, and updates the
      * customer's points balance.
      *
      * It is designed to run as a downstream batch process after the
      * main CardDemo batch cycle (COMBTRAN job).
      ******************************************************************
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
      *----------------------------------------------------------------*
      *    INPUT FILES FROM CARDDEMO
      *----------------------------------------------------------------*
           SELECT TRANFILE
               ASSIGN TO TRANFILE
               ORGANIZATION IS INDEXED
               ACCESS MODE IS SEQUENTIAL
               RECORD KEY IS TRAN-ID
               FILE STATUS IS FS-TRANFILE.

           SELECT CARDXREF
               ASSIGN TO CARDXREF
               ORGANIZATION IS INDEXED
               ACCESS MODE IS RANDOM
               RECORD KEY IS XREF-CARD-NUM
               FILE STATUS IS FS-CARDXREF.

           SELECT TRANTYPE
               ASSIGN TO TRANTYPE
               ORGANIZATION IS INDEXED
               ACCESS MODE IS RANDOM
               RECORD KEY IS TRAN-TYPE
               FILE STATUS IS FS-TRANTYPE.

           SELECT TRANCATG
               ASSIGN TO TRANCATG
               ORGANIZATION IS INDEXED
               ACCESS MODE IS RANDOM
               RECORD KEY IS TRAN-CAT-KEY
               FILE STATUS IS FS-TRANCATG.

      *----------------------------------------------------------------*
      *    NEW REWARDS SYSTEM FILES
      *----------------------------------------------------------------*
           SELECT REWBALAN
               ASSIGN TO REWBALAN
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS RW-BAL-CUST-ID
               FILE STATUS IS FS-REWBALAN.

           SELECT REWPOINT
               ASSIGN TO REWPOINT
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS RW-POINT-KEY
               FILE STATUS IS FS-REWPOINT.

       DATA DIVISION.
       FILE SECTION.
       FD  TRANFILE.
       01  TRAN-REC                PIC X(350).

       FD  CARDXREF.
       01  XREF-REC                PIC X(50).

       FD  TRANTYPE.
       01  TRANTYPE-REC            PIC X(60).

       FD  TRANCATG.
       01  TRANCATG-REC            PIC X(60).
       FD  REWBALAN.
       01  REWBALAN-REC            PIC X(80).

       FD  REWPOINT.
       01  REWPOINT-REC            PIC X(120).

       WORKING-STORAGE SECTION.
      *----------------------------------------------------------------*
      *    FILE STATUS INDICATORS
      *----------------------------------------------------------------*
       01  FILE-STATUS-CODES.
           05  FS-TRANFILE         PIC X(02).
           05  FS-CARDXREF         PIC X(02).
           05  FS-REWBALAN         PIC X(02).
           05  FS-REWPOINT         PIC X(02).
           05  FS-TRANTYPE         PIC X(02).
           05  FS-TRANCATG         PIC X(02).

       01  WS-FLAGS.
           05  WS-TRANFILE-EOF     PIC X(01) VALUE 'N'.
               88  TRANFILE-IS-AT-END      VALUE 'Y'.

      *----------------------------------------------------------------*
      *    RECORD LAYOUTS FROM COPYBOOKS
      *----------------------------------------------------------------*
       01  WS-TRAN-REC.
           COPY CVTRA05Y.
       01  WS-XREF-REC.
           COPY CVACT03Y.
       01  WS-TRANTYPE-REC.
           COPY CVTRA03Y.
       01  WS-TRANCATG-REC.
           COPY CVTRA04Y.
       01  WS-RW-BAL-REC.
           COPY RWBALANY.
       01  WS-RW-POINT-REC.
           COPY RWPOINTY.

      *----------------------------------------------------------------*
      *    WORKING VARIABLES
      *----------------------------------------------------------------*
       01  WS-CALCULATIONS.
           05  WS-CALC-POINTS      PIC S9(09)V99 COMP-3.
      *    Hardcoded points rate for eligible transactions.
           05  WS-POINTS-RATE      PIC S9(1)V99 VALUE 1.00.

       PROCEDURE DIVISION.
       0000-MAIN-PROCEDURE.
           PERFORM 1000-INITIALIZE.
           PERFORM 2000-PROCESS-TRANSACTIONS UNTIL TRANFILE-IS-AT-END.
           PERFORM 9000-TERMINATE.
           GOBACK.

       1000-INITIALIZE.
           DISPLAY 'REWARDS CALCULATION PROGRAM STARTED.'.
           OPEN INPUT TRANFILE, CARDXREF, TRANTYPE, TRANCATG.
           OPEN I-O REWBALAN, REWPOINT.
           PERFORM 8000-CHECK-FILE-STATUS.
           READ TRANFILE INTO WS-TRAN-REC
               AT END SET TRANFILE-IS-AT-END TO TRUE
           END-READ.

       2000-PROCESS-TRANSACTIONS.
           INITIALIZE WS-CALC-POINTS.

      *    1. Get Customer ID from Card Number
           MOVE TRAN-CARD-NUM OF WS-TRAN-REC TO XREF-CARD-NUM.
           READ CARDXREF INTO WS-XREF-REC
               KEY IS XREF-CARD-NUM
               INVALID KEY
                   DISPLAY 'ERROR: CARDXREF NOT FOUND FOR ' TRAN-CARD-NUM
                   GO TO 2999-GET-NEXT-TRAN
           END-READ.

      *    2. Check if transaction category is eligible for points
           MOVE TRAN-TYPE-CD OF WS-TRAN-REC TO TRAN-TYPE-CD OF
               TRAN-CAT-KEY OF WS-TRANCATG-REC.
           MOVE TRAN-CAT-CD OF WS-TRAN-REC TO TRAN-CAT-CD OF
               TRAN-CAT-KEY OF WS-TRANCATG-REC.
           READ TRANCATG INTO WS-TRANCATG-REC
               KEY IS TRAN-CAT-KEY OF WS-TRANCATG-REC
               INVALID KEY
      *            Category not found, so no points awarded.
                   GO TO 2999-GET-NEXT-TRAN
           END-READ.

      *    3. Calculate Points (only for positive transaction amounts)
           IF TRAN-AMT OF WS-TRAN-REC > 0
      *        Using a fixed rate for all eligible categories.
               COMPUTE WS-CALC-POINTS = TRAN-AMT OF WS-TRAN-REC *
                   WS-POINTS-RATE
           END-IF.

      *    4. If points were earned, write activity and update balance
           IF WS-CALC-POINTS <= 0
               GO TO 2999-GET-NEXT-TRAN
           END-IF.

           MOVE XREF-CUST-ID TO RW-CUST-ID.
           MOVE TRAN-ID OF WS-TRAN-REC TO RW-TRAN-ID.
           MOVE TRAN-ORIG-TS OF WS-TRAN-REC TO RW-TRAN-TS.
           MOVE TRAN-CARD-NUM OF WS-TRAN-REC TO RW-CARD-NUM.
           MOVE WS-CALC-POINTS TO RW-POINTS-AMT.
           MOVE TRAN-DESC OF WS-TRAN-REC TO RW-POINT-DESC.
           MOVE 'EARN' TO RW-POINT-SOURCE.
           WRITE RW-POINT-REC FROM WS-RW-POINT-REC.

           MOVE XREF-CUST-ID TO RW-BAL-CUST-ID.
           READ REWBALAN INTO WS-RW-BAL-REC
               KEY IS RW-BAL-CUST-ID
               INVALID KEY
      *            First time customer is earning points
                   MOVE 0 TO RW-BAL-TOTAL-POINTS
           END-READ.

           ADD WS-CALC-POINTS TO RW-BAL-TOTAL-POINTS.
           MOVE FUNCTION CURRENT-DATE TO RW-BAL-LAST-UPDATE-TS.

           IF FS-REWBALAN = '23' *> Record not found
               WRITE REWBALAN-REC FROM WS-RW-BAL-REC
           ELSE
               REWRITE REWBALAN-REC FROM WS-RW-BAL-REC
           END-IF.

       2999-GET-NEXT-TRAN.
           READ TRANFILE INTO WS-TRAN-REC
               AT END SET TRANFILE-IS-AT-END TO TRUE
           END-READ.

       8000-CHECK-FILE-STATUS.
      *    Add robust file status checking here for production.
           CONTINUE.

       9000-TERMINATE.
           CLOSE TRANFILE, CARDXREF, TRANTYPE, TRANCATG, REWBALAN, REWPOINT.
           DISPLAY 'REWARDS CALCULATION PROGRAM FINISHED.'.