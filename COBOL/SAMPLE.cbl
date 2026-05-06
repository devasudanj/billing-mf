       IDENTIFICATION DIVISION.
      ******************************************************************
      * PROGRAM  : SAMPLE
      * PURPOSE  : Read billing detail records from an input file
      *            and write them to an output file for database load.
      * AUTHOR   : Billing Team
      * DATE     : 2026-05-06
      ******************************************************************
       PROGRAM-ID.    SAMPLE.
       AUTHOR.        BILLING-TEAM.
       DATE-WRITTEN.  2026-05-06.

       ENVIRONMENT DIVISION.

       CONFIGURATION SECTION.

       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT BILLING-INPUT-FILE
               ASSIGN TO BILLIN
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS  IS WS-FILE-STATUS.

           SELECT BILLING-OUTPUT-FILE
               ASSIGN TO BILLOUT
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS  IS WS-OUT-STATUS.

       DATA DIVISION.

       FILE SECTION.
       FD  BILLING-INPUT-FILE.

           COPY "TEST.cpy".

       FD  BILLING-OUTPUT-FILE.
       01  OUTPUT-RECORD                PIC X(45).

       WORKING-STORAGE SECTION.

       01  WS-FILE-STATUS              PIC X(02).
           88  WS-FILE-OK              VALUE '00'.
           88  WS-FILE-EOF             VALUE '10'.

       01  WS-OUT-STATUS               PIC X(02).
           88  WS-OUT-OK               VALUE '00'.

       01  WS-SWITCHES.
           05  WS-EOF-SW               PIC X(01) VALUE 'N'.
               88  WS-EOF                        VALUE 'Y'.
               88  WS-NOT-EOF                    VALUE 'N'.

       01  WS-COUNTERS.
           05  WS-RECORDS-READ         PIC 9(09) VALUE ZEROS.
           05  WS-RECORDS-INSERTED     PIC 9(09) VALUE ZEROS.
           05  WS-RECORDS-ERROR        PIC 9(09) VALUE ZEROS.

       01  WS-DISPLAY-MSG              PIC X(80) VALUE SPACES.

       01  WS-OUTPUT-LINE.
           05  WS-OUT-ACCOUNT          PIC X(15).
           05  WS-OUT-SEP1             PIC X(01) VALUE '|'.
           05  WS-OUT-ELEMENT-ID       PIC X(08).
           05  WS-OUT-SEP2             PIC X(01) VALUE '|'.
           05  WS-OUT-VOLUME           PIC -(08)9.
           05  WS-OUT-SEP3             PIC X(01) VALUE '|'.
           05  WS-OUT-DATE             PIC X(10).

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
      * 1000-INITIALIZE: Open input and output files
      ******************************************************************
       1000-INITIALIZE.
           OPEN INPUT  BILLING-INPUT-FILE
           IF NOT WS-FILE-OK
               STRING 'ERROR: UNABLE TO OPEN INPUT FILE. STATUS='
                      WS-FILE-STATUS
                      DELIMITED BY SIZE
                      INTO WS-DISPLAY-MSG
               DISPLAY WS-DISPLAY-MSG
               MOVE 16 TO RETURN-CODE
               STOP RUN
           END-IF

           OPEN OUTPUT BILLING-OUTPUT-FILE
           IF NOT WS-OUT-OK
               STRING 'ERROR: UNABLE TO OPEN OUTPUT FILE. STATUS='
                      WS-OUT-STATUS
                      DELIMITED BY SIZE
                      INTO WS-DISPLAY-MSG
               DISPLAY WS-DISPLAY-MSG
               MOVE 16 TO RETURN-CODE
               STOP RUN
           END-IF

           DISPLAY 'SAMPLE: FILES OPENED SUCCESSFULLY'

           PERFORM 2100-READ-INPUT-FILE
           .

      ******************************************************************
      * 2000-PROCESS-RECORDS: Process each input record
      ******************************************************************
       2000-PROCESS-RECORDS.
           PERFORM 2200-WRITE-OUTPUT-RECORD
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
      * 2200-WRITE-OUTPUT-RECORD: Write record to output file
      ******************************************************************
       2200-WRITE-OUTPUT-RECORD.
           MOVE ACS-DETAIL-ACCOUNT    TO WS-OUT-ACCOUNT
           MOVE ACS-DETAIL-ELEMENT-ID TO WS-OUT-ELEMENT-ID
           MOVE ACS-DETAIL-VOLUME     TO WS-OUT-VOLUME
           MOVE ACS-DETAIL-DATE       TO WS-OUT-DATE

           WRITE OUTPUT-RECORD FROM WS-OUTPUT-LINE

           IF WS-OUT-OK
               ADD 1 TO WS-RECORDS-INSERTED
           ELSE
               STRING 'ERROR: WRITE FAILED. STATUS='
                      WS-OUT-STATUS
                      DELIMITED BY SIZE
                      INTO WS-DISPLAY-MSG
               DISPLAY WS-DISPLAY-MSG
               ADD 1 TO WS-RECORDS-ERROR
           END-IF
           .

      ******************************************************************
      * 3000-TERMINATE: Close files and display summary
      ******************************************************************
       3000-TERMINATE.
           CLOSE BILLING-INPUT-FILE
           CLOSE BILLING-OUTPUT-FILE

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
