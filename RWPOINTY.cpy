      ******************************************************************
      * COPYBOOK FOR REWARDS POINTS ACTIVITY VSAM KSDS
      ******************************************************************
       01  RW-POINT-REC.
           05  RW-POINT-KEY.
               10  RW-CUST-ID          PIC 9(09).
               10  RW-TRAN-TS          PIC X(16).
           05  RW-TRAN-ID              PIC X(16).
           05  RW-CARD-NUM             PIC X(16).
           05  RW-POINTS-AMT           PIC S9(09)V99 COMP-3.
           05  RW-POINT-SOURCE         PIC X(10).
           05  FILLER                  PIC X(38).