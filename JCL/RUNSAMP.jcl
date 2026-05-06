//RUNSAMP  JOB (BILLING),'RUN SAMPLE PGM',
//         CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1),
//         NOTIFY=&SYSUID
//*
//********************************************************************
//* JCL     : RUNSAMP
//* PURPOSE : Compile and execute the SAMPLE billing program
//* AUTHOR  : Billing Team
//* DATE    : 2026-05-06
//********************************************************************
//*
//*------------------------------------------------------------------
//* STEP 1: COMPILE THE COBOL PROGRAM WITH DB2 PRECOMPILER
//*------------------------------------------------------------------
//COMPILE  EXEC DSNHCOB2,MEM=SAMPLE,
//         PARM.PC='HOST(COB2)',
//         PARM.COB='LIB,OBJECT,APOST,MAP,XREF',
//         PARM.LKED='LIST,XREF,LET'
//PC.DBRMLIB DD DSN=&SYSUID..BILLING.DBRM(SAMPLE),DISP=SHR
//PC.SYSLIB  DD DSN=&SYSUID..BILLING.COPYBOOK,DISP=SHR
//           DD DSN=&SYSUID..BILLING.DCLGEN,DISP=SHR
//PC.SYSIN   DD DSN=&SYSUID..BILLING.COBOL(SAMPLE),DISP=SHR
//LKED.SYSLMOD DD DSN=&SYSUID..BILLING.LOAD(SAMPLE),DISP=SHR
//*
//*------------------------------------------------------------------
//* STEP 2: BIND THE DB2 PLAN
//*------------------------------------------------------------------
//BIND     EXEC PGM=IKJEFT01
//SYSTSPRT DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSTSIN  DD *
  DSN SYSTEM(DB2P)
  BIND PACKAGE(BILLTST) -
       MEMBER(SAMPLE) -
       ACTION(REPLACE) -
       ISOLATION(CS) -
       VALIDATE(BIND) -
       LIB('&SYSUID..BILLING.DBRM')
  BIND PLAN(SAMPPLAN) -
       PKLIST(BILLTST.*) -
       ACTION(REPLACE) -
       ISOLATION(CS) -
       VALIDATE(BIND)
  END
/*
//*
//*------------------------------------------------------------------
//* STEP 3: EXECUTE THE SAMPLE PROGRAM
//*------------------------------------------------------------------
//RUN      EXEC PGM=IKJEFT01,DYNAMNBR=20,COND=(4,LT)
//STEPLIB  DD DSN=&SYSUID..BILLING.LOAD,DISP=SHR
//         DD DSN=DSNLOAD,DISP=SHR
//BILLIN   DD DSN=&SYSUID..BILLING.TESTDATA(BILLIN),DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//SYSTSIN  DD *
  DSN SYSTEM(DB2P)
  RUN PROGRAM(SAMPLE) -
      PLAN(SAMPPLAN) -
      LIB('&SYSUID..BILLING.LOAD')
  END
/*
//*
