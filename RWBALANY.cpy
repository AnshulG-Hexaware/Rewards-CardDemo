      ******************************************************************
      * COPYBOOK FOR REWARDS BALANCE VSAM KSDS
      ******************************************************************
       01  RW-BAL-REC.
           05  RW-BAL-CUST-ID          PIC 9(09).
           05  RW-BAL-TOTAL-POINTS     PIC S9(13)V99 COMP-3.
           05  RW-BAL-LAST-UPDATE-TS   PIC X(26).
           05  FILLER                  PIC X(36).