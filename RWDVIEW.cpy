      *----------------------------------------------------------------*
      *    COPYBOOK RWDVIEW
      *
      *    Generated from BMS Mapset RWDVIEW
      *----------------------------------------------------------------*
       01  RWDVWM1I.
           05 FILLER             PIC X(12).
           05 CUSTIDL            PIC S9(4) COMP.
           05 CUSTIDF            PIC X.
           05 FILLER REDEFINES CUSTIDF.
              10 CUSTIDA         PIC X.
           05 CUSTIDI            PIC X(9).
           05 CARDNUML           PIC S9(4) COMP.
           05 CARDNUMF           PIC X.
           05 FILLER REDEFINES CARDNUMF.
              10 CARDNUMA        PIC X.
           05 CARDNUMI           PIC X(16).
           05 POINTSL            PIC S9(4) COMP.
           05 POINTSF            PIC X.
           05 FILLER REDEFINES POINTSF.
              10 POINTSA         PIC X.
           05 POINTSI            PIC Z,ZZZ,ZZ9.99.
           05 MSG1L              PIC S9(4) COMP.
           05 MSG1F              PIC X.
           05 FILLER REDEFINES MSG1F.
              10 MSG1A           PIC X.
           05 MSG1I              PIC X(80).
       01  RWDVWM1O REDEFINES RWDVWM1I.
           05 FILLER             PIC X(12).
           05 FILLER             PIC S9(4) COMP.
           05 FILLER             PIC X.
           05 CUSTIDC            PIC X.
           05 CUSTIDH            PIC X.
           05 CUSTIDO            PIC X(9).
           05 FILLER             PIC S9(4) COMP.
           05 FILLER             PIC X.
           05 CARDNUMC           PIC X.
           05 CARDNUMH           PIC X.
           05 CARDNUMO           PIC X(16).
           05 FILLER             PIC S9(4) COMP.
           05 FILLER             PIC X.
           05 POINTSC            PIC X.
           05 POINTSH            PIC X.
           05 POINTSO            PIC Z,ZZZ,ZZ9.99.
           05 FILLER             PIC S9(4) COMP.
           05 FILLER             PIC X.
           05 MSG1C              PIC X.
           05 MSG1H              PIC X.
           05 MSG1O              PIC X(80).