       IDENTIFICATION DIVISION.
       PROGRAM-ID. RWDMENU.
       AUTHOR. Gemini Assist.
      ******************************************************************
      * This is the main menu program for the CICS Rewards System.
      * It displays a menu of options to the user.
      *
      * Associated BMS: RWDMEN.bms
      * Associated Map: RWDMAP1
      ******************************************************************
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-RESP                  PIC S9(8) COMP.
       01  WS-MSG                   PIC X(80).

      * Copybook for the menu map
       01  RWDMAP1-COPY.
           COPY RWDMEN.

       LINKAGE SECTION.
       01  DFHCOMMAREA              PIC X(1).

       PROCEDURE DIVISION.
       0000-MAIN-PROCEDURE.
      *----------------------------------------------------------------*
      * Check how we were invoked.
      * If EIBCALEN = 0, this is the first time in. Send the map.
      * Otherwise, process the user's response.
      *----------------------------------------------------------------*
           IF EIBCALEN = 0
               PERFORM 1000-SEND-INITIAL-MAP
           ELSE
               PERFORM 2000-PROCESS-USER-INPUT
           END-IF.
           EXEC CICS RETURN END-EXEC.
           GOBACK.

       1000-SEND-INITIAL-MAP.
      *----------------------------------------------------------------*
      * Send the clean menu map to the terminal.
      *----------------------------------------------------------------*
      *    Clear the message field before sending the initial map.
           MOVE SPACES TO MSG1O.
           EXEC CICS SEND MAP('RWDMAP1')
                         MAPSET('RWDMEN')
                         FROM(RWDMAP1O)
                         ERASE
                         CURSOR
           END-EXEC.
           EXIT.

       2000-PROCESS-USER-INPUT.
      *----------------------------------------------------------------*
      * Receive the user's input and decide which program to call.
      *----------------------------------------------------------------*
           EXEC CICS RECEIVE MAP('RWDMAP1')
                             MAPSET('RWDMEN')
                             INTO(RWDMAP1I)
           END-EXEC.

           EVALUATE OPTIONI
               WHEN '1'
      *            Transfer to the View Points program
                   EXEC CICS XCTL PROGRAM('RWDVIEW') END-EXEC
               WHEN '2'
      *            Transfer to the Redeem Points program (not yet created)
                   MOVE 'Redeem Points function is not yet available.'
                     TO MSG1O
                   PERFORM 3000-SEND-ERROR-MAP
               WHEN OTHER
                   MOVE 'Invalid option, please try again.' TO MSG1O
                   PERFORM 3000-SEND-ERROR-MAP
           END-EVALUATE.
           EXIT.

       3000-SEND-ERROR-MAP.
      *----------------------------------------------------------------*
      * Resend the map with an error message.
      *----------------------------------------------------------------*
           EXEC CICS SEND MAP('RWDMAP1')
                         MAPSET('RWDMEN')
                         FROM(RWDMAP1O)
                         CURSOR
           END-EXEC.

           EXIT.
