       IDENTIFICATION DIVISION.
      ******************************************************************
      * PROGRAM  : SAMPLE
      * PURPOSE  : Read billing detail records from an input file
      *            and insert them into the DB2 table BILL_TEST.
      * AUTHOR   : Billing Team
      * DATE     : 2026-05-06
      ******************************************************************
       PROGRAM-ID.    SAMPLE.
       AUTHOR.        BILLING-TEAM.
       DATE-WRITTEN.  2026-05-06.

       ENVIRONMENT DIVISION.

       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-ZOS.
       OBJECT-COMPUTER. IBM-ZOS.

       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT BILLING-INPUT-FILE
               ASSIGN TO BILLIN
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE  IS SEQUENTIAL
               FILE STATUS  IS WS-FILE-STATUS.

       DATA DIVISION.

       FILE SECTION.
       FD  BILLING-INPUT-FILE
           RECORDING MODE IS F
           RECORD CONTAINS 41 CHARACTERS
           BLOCK CONTAINS 0 RECORDS.

           COPY TEST.

       WORKING-STORAGE SECTION.

       01  WS-FILE-STATUS             PIC X(02).
           88  WS-FILE-OK             VALUE '00'.
           88  WS-FILE-EOF            VALUE '10'.

       01  WS-SWITCHES.
           05  WS-EOF-SW              PIC X(01) VALUE 'N'.
               88  WS-EOF                       VALUE 'Y'.
               88  WS-NOT-EOF                   VALUE 'N'.

       01  WS-COUNTERS.
           05  WS-RECORDS-READ        PIC 9(09) VALUE ZEROS.
           05  WS-RECORDS-INSERTED    PIC 9(09) VALUE ZEROS.
           05  WS-RECORDS-ERROR       PIC 9(09) VALUE ZEROS.

       01  WS-DISPLAY-MSG             PIC X(80) VALUE SPACES.

      ******************************************************************
      * DB2 INCLUDE FOR BILL_TEST TABLE
      ******************************************************************
           EXEC SQL INCLUDE TESTDCL  END-EXEC.

      ******************************************************************
      * DB2 COMMUNICATION AREA
      ******************************************************************
           EXEC SQL INCLUDE SQLCA    END-EXEC.

       PROCEDURE DIVISION.

      ******************************************************************
      * 0000-MAIN-PROCESS: Main control paragraph
      ******************************************************************
       0000-MAIN-PROCESS.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-PROCESS-RECORDS
               UNTIL WS-EOF
           PERFORM 3000-TERMINATE
           STOP RUN.

      ******************************************************************
      * 1000-INITIALIZE: Open input file and validate
      ******************************************************************
       1000-INITIALIZE.
           OPEN INPUT BILLING-INPUT-FILE

           IF NOT WS-FILE-OK
               STRING 'ERROR: UNABLE TO OPEN INPUT FILE. STATUS='
                      WS-FILE-STATUS
                      DELIMITED BY SIZE
                      INTO WS-DISPLAY-MSG
               DISPLAY WS-DISPLAY-MSG
               MOVE 16 TO RETURN-CODE
               STOP RUN
           END-IF

           DISPLAY 'SAMPLE: BILLING INPUT FILE OPENED SUCCESSFULLY'

           PERFORM 2100-READ-INPUT-FILE
           .

      ******************************************************************
      * 2000-PROCESS-RECORDS: Process each input record
      ******************************************************************
       2000-PROCESS-RECORDS.
           PERFORM 2200-INSERT-DB2-TABLE
           PERFORM 2100-READ-INPUT-FILE
           .

      ******************************************************************
      * 2100-READ-INPUT-FILE: Read a record from the input file
      ******************************************************************
       2100-READ-INPUT-FILE.
           READ BILLING-INPUT-FILE
               INTO ACS-BILL-DETAIL-RECORD

           EVALUATE TRUE
               WHEN WS-FILE-OK
                   ADD 1 TO WS-RECORDS-READ
               WHEN WS-FILE-EOF
                   SET WS-EOF TO TRUE
               WHEN OTHER
                   STRING 'ERROR: FILE READ FAILED. STATUS='
                          WS-FILE-STATUS
                          DELIMITED BY SIZE
                          INTO WS-DISPLAY-MSG
                   DISPLAY WS-DISPLAY-MSG
                   MOVE 16 TO RETURN-CODE
                   STOP RUN
           END-EVALUATE
           .

      ******************************************************************
      * 2200-INSERT-DB2-TABLE: Insert record into BILL_TEST table
      ******************************************************************
       2200-INSERT-DB2-TABLE.
           MOVE ACS-DETAIL-ACCOUNT    TO TST-DTL-ACCT-NUM
           MOVE ACS-DETAIL-ELEMENT-ID TO TST-DTL-ELEMENT-ID
           MOVE ACS-DETAIL-VOLUME     TO TST-DTL-VOLUME
           MOVE ACS-DETAIL-DATE       TO TST-DTL-DATE

           EXEC SQL
               INSERT INTO BILL_TEST
               (
                   TST_DTL_ACCT_NUM,
                   TST_DTL_ELEMENT_ID,
                   TST_DTL_VOLUME,
                   TST_DTL_DATE
               )
               VALUES
               (
                   :TST-DTL-ACCT-NUM,
                   :TST-DTL-ELEMENT-ID,
                   :TST-DTL-VOLUME,
                   :TST-DTL-DATE
               )
           END-EXEC

           EVALUATE SQLCODE
               WHEN 0
                   ADD 1 TO WS-RECORDS-INSERTED
               WHEN -803
                   DISPLAY 'WARNING: DUPLICATE KEY FOR ACCOUNT '
                           ACS-DETAIL-ACCOUNT
                   ADD 1 TO WS-RECORDS-ERROR
               WHEN OTHER
                   STRING 'ERROR: DB2 INSERT FAILED. SQLCODE='
                          SQLCODE
                          DELIMITED BY SIZE
                          INTO WS-DISPLAY-MSG
                   DISPLAY WS-DISPLAY-MSG
                   ADD 1 TO WS-RECORDS-ERROR
           END-EVALUATE
           .

      ******************************************************************
      * 3000-TERMINATE: Close files and display summary
      ******************************************************************
       3000-TERMINATE.
           CLOSE BILLING-INPUT-FILE

           IF NOT WS-FILE-OK
               IF NOT WS-FILE-EOF
                   STRING 'WARNING: FILE CLOSE STATUS='
                          WS-FILE-STATUS
                          DELIMITED BY SIZE
                          INTO WS-DISPLAY-MSG
                   DISPLAY WS-DISPLAY-MSG
               END-IF
           END-IF

           DISPLAY '****************************************'
           DISPLAY '* SAMPLE PROGRAM - EXECUTION SUMMARY   *'
           DISPLAY '****************************************'
           DISPLAY '* RECORDS READ      : ' WS-RECORDS-READ
           DISPLAY '* RECORDS INSERTED  : ' WS-RECORDS-INSERTED
           DISPLAY '* RECORDS IN ERROR  : ' WS-RECORDS-ERROR
           DISPLAY '****************************************'

           IF WS-RECORDS-ERROR > 0
               MOVE 4 TO RETURN-CODE
           ELSE
               MOVE 0 TO RETURN-CODE
           END-IF
           .
