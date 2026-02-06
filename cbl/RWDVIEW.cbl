       IDENTIFICATION DIVISION.
       PROGRAM-ID. RWDVIEW.
       AUTHOR. Gemini Assist.
      ******************************************************************
      * This program allows a user to view their rewards points balance.
      * It is invoked from the main rewards menu (RWDMENU).
      *
      * It receives a customer ID, reads the REWBALAN VSAM file,
      * and displays the total points.
      *
      * Associated BMS: RWDVIEW.bms
      * Associated Map: RWDVWM1
      ******************************************************************
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-RESP                  PIC S9(8) COMP.
       01  WS-RESP2                 PIC S9(8) COMP.
       01  WS-MSG                   PIC X(80).

      * File record for REWBALAN KSDS
       01  REWBALAN-REC.
           05 RB-CUST-ID         PIC 9(09).
           05 RB-CARD-NUM        PIC X(16).
           05 RB-BALANCE-PTS     PIC S9(9)V99.
           05 RB-LAST-UPDATE-TS  PIC X(26).

      * Copybook for the view map
       01  RWDVWM1I-COPY.
           COPY RWDVIEW.

       LINKAGE SECTION.
       01  DFHCOMMAREA              PIC X(1).

       PROCEDURE DIVISION.
       0000-MAIN-PROCEDURE.
      *----------------------------------------------------------------*
      * Check how we were invoked.
      * EIBCALEN = 0 means we came from the menu. Send initial map.
      * If user pressed PF3, return to menu.
      * Otherwise, process the screen.
      *----------------------------------------------------------------*
           EVALUATE TRUE
               WHEN EIBCALEN = 0
                   PERFORM 1000-SEND-INITIAL-MAP
               WHEN EIBAID = DFHPF3
                   EXEC CICS XCTL PROGRAM('RWDMENU') END-EXEC
               WHEN OTHER
                   PERFORM 2000-PROCESS-USER-INPUT
           END-EVALUATE.
           EXEC CICS RETURN END-EXEC.
           GOBACK.

       1000-SEND-INITIAL-MAP.
      *----------------------------------------------------------------*
      * Send the clean map asking for a Customer ID.
      *----------------------------------------------------------------*
           MOVE 'Enter Customer ID and press Enter. Press PF3 to exit.'
             TO MSG1O.
           EXEC CICS SEND MAP('RWDVWM1')
                         MAPSET('RWDVIEW')
                         FROM(RWDVWM1O)
                         ERASE
                         CURSOR
           END-EXEC.
           EXIT.

       2000-PROCESS-USER-INPUT.
      *----------------------------------------------------------------*
      * Receive the map, validate input, read the file, and show data.
      *----------------------------------------------------------------*
           EXEC CICS RECEIVE MAP('RWDVWM1')
                             MAPSET('RWDVIEW')
                             INTO(RWDVWM1I)
           END-EXEC.

           IF CUSTIDI IS NUMERIC AND CUSTIDI > 0
               MOVE CUSTIDI TO RB-CUST-ID
               PERFORM 2100-READ-REWARDS-FILE
           ELSE
               MOVE 'Customer ID must be a valid number.' TO MSG1O
               PERFORM 3000-SEND-ERROR-MAP
           END-IF.
           EXIT.

       2100-READ-REWARDS-FILE.
      *----------------------------------------------------------------*
      * Read the REWBALAN VSAM file using the customer ID.
      *----------------------------------------------------------------*
           EXEC CICS READ FILE('REWBALAN')
                          INTO(REWBALAN-REC)
                          RIDFLD(RB-CUST-ID)
                          RESP(WS-RESP)
           END-EXEC.

           EVALUATE WS-RESP
               WHEN DFHRESP(NORMAL)
                   MOVE RB-BALANCE-PTS TO POINTSO
                   MOVE RB-CARD-NUM TO CARDNUMO
                   MOVE 'Customer points balance:' TO MSG1O
                   PERFORM 2200-SEND-DATA-MAP
               WHEN DFHRESP(NOTFND)
                   MOVE 'Customer ID not found.' TO MSG1O
                   PERFORM 3000-SEND-ERROR-MAP
               WHEN OTHER
                   MOVE 'Error reading rewards file.' TO MSG1O
                   PERFORM 3000-SEND-ERROR-MAP
           END-EVALUATE.
           EXIT.

       2200-SEND-DATA-MAP.
      *----------------------------------------------------------------*
      * Resend the map with the retrieved data.
      *----------------------------------------------------------------*
           EXEC CICS SEND MAP('RWDVWM1')
                         MAPSET('RWDVIEW')
                         FROM(RWDVWM1O)
                         CURSOR
           END-EXEC.
           EXIT.

       3000-SEND-ERROR-MAP.
      *----------------------------------------------------------------*
      * Resend the map with an error message.
      *----------------------------------------------------------------*
           EXEC CICS SEND MAP('RWDVWM1')
                         MAPSET('RWDVIEW')
                         FROM(RWDVWM1O)
                         CURSOR
           END-EXEC.

           EXIT.
