      ******************************************************************
      * DCLGEN   : TESTDCL
      * PURPOSE  : DB2 Table declaration for BILL_TEST
      * TABLE    : BILL_TEST
      * AUTHOR   : Billing Team
      * DATE     : 2026-05-06
      ******************************************************************
           EXEC SQL DECLARE BILL_TEST TABLE
           (
             TST_DTL_ACCT_NUM       CHAR(15)   NOT NULL,
             TST_DTL_ELEMENT_ID     CHAR(8)    NOT NULL,
             TST_DTL_VOLUME         INTEGER    NOT NULL,
             TST_DTL_DATE           CHAR(10)   NOT NULL
           ) END-EXEC.

       01  DCLBILL-TEST.
           10  TST-DTL-ACCT-NUM        PIC X(15).
           10  TST-DTL-ELEMENT-ID      PIC X(08).
           10  TST-DTL-VOLUME          PIC S9(09) COMP.
           10  TST-DTL-DATE            PIC X(10).
      ******************************************************************
      * END OF DCLGEN TESTDCL
      ******************************************************************
