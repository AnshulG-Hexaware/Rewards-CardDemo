      *----------------------------------------------------------------*
      *    COPYBOOK RWDMEN
      *
      *    Generated from BMS Mapset RWDMEN
      *----------------------------------------------------------------*
       01  RWDMAP1I.
           05 FILLER             PIC X(12).
           05 OPTIONL            PIC S9(4) COMP.
           05 OPTIONF            PIC X.
           05 FILLER REDEFINES OPTIONF.
              10 OPTIONA         PIC X.
           05 OPTIONI            PIC X(1).
           05 MSG1L              PIC S9(4) COMP.
           05 MSG1F              PIC X.
           05 FILLER REDEFINES MSG1F.
              10 MSG1A           PIC X.
           05 MSG1I              PIC X(80).
       01  RWDMAP1O REDEFINES RWDMAP1I.
           05 FILLER             PIC X(12).
           05 FILLER             PIC S9(4) COMP.
           05 FILLER             PIC X.
           05 OPTIONC            PIC X.
           05 OPTIONH            PIC X.
           05 OPTIONO            PIC X(1).
           05 FILLER             PIC S9(4) COMP.
           05 FILLER             PIC X.
           05 MSG1C              PIC X.
           05 MSG1H              PIC X.
           05 MSG1O              PIC X(80).