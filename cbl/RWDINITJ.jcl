//RWDINITJ JOB 'REWARDS-INIT',CLASS=A,MSGCLASS=X,NOTIFY=&SYSUID
//********************************************************************
//*  JOB TO DEFINE THE VSAM FILES FOR THE NEW REWARDS SYSTEM.        *
//*  THIS JOB SHOULD BE RUN ONCE DURING SETUP.                       *
//********************************************************************
//DEFINE   EXEC PGM=IDCAMS,REGION=0M
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DSN=REWARDS.SYSTEM.SYSIN(RWDVDEF),DISP=SHR
//* Alternatively, include SYSIN inline:
//*SYSIN    DD *
/* DEFINE CLUSTER ... commands here */
//