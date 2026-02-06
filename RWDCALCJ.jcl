//RWDCALCJ JOB 'REWARDS-CALC',CLASS=A,MSGCLASS=X,NOTIFY=&SYSUID
//********************************************************************
//*  JOB TO RUN THE REWARDS POINTS CALCULATION PROGRAM (REWARDSC).   *
//*                                                                  *
//*  THIS JOB MUST RUN AFTER THE CARDDEMO 'COMBTRAN' JOB COMPLETES.  *
//********************************************************************
//STEP010  EXEC PGM=REWARDSC,REGION=0M
//STEPLIB  DD DSN=REWARDS.SYSTEM.LOADLIB,DISP=SHR
//         DD DSN=AWS.M2.CARDDEMO.LOADLIB,DISP=SHR
//********************************************************************
//*  INPUT FILES FROM CARDDEMO SYSTEM                              *
//********************************************************************
//TRANFILE DD DSN=AWS.M2.CARDDEMO.TRANSACT.VSAM.KSDS,DISP=SHR
//TRANTYPE DD DSN=AWS.M2.CARDDEMO.TRANTYPE.VSAM.KSDS,DISP=SHR
//TRANCATG DD DSN=AWS.M2.CARDDEMO.TRANCATG.VSAM.KSDS,DISP=SHR
//CARDXREF DD DSN=AWS.M2.CARDDEMO.CARDXREF.VSAM.KSDS,DISP=SHR
//********************************************************************
//*  NEW REWARDS SYSTEM FILES (INPUT/OUTPUT)                       *
//********************************************************************
//*REWRULES DD DSN=REWARDS.SYSTEM.RULES.VSAM.KSDS,DISP=SHR
//REWBALAN DD DSN=REWARDS.SYSTEM.BALANCE.VSAM.KSDS,DISP=SHR
//REWPOINT DD DSN=REWARDS.SYSTEM.POINTS.VSAM.KSDS,DISP=SHR
//********************************************************************
//*  OUTPUT AND WORK FILES                                         *
//********************************************************************
//SYSOUT   DD SYSOUT=*
//