# Billing Mainframe - SAMPLE COBOL Program

## Overview

The **SAMPLE** program is a batch COBOL billing application that reads billing detail records from a sequential input file and inserts them into a DB2 table (`BILL_TEST`).

## Project Structure

```
billing-mf/
├── COBOL/
│   └── SAMPLE.cbl          # Main COBOL billing program
├── COPYBOOK/
│   └── TEST.cpy             # Input file record layout copybook
├── DCLGEN/
│   └── TESTDCL.cbl          # DB2 DCLGEN for BILL_TEST table
├── JCL/
│   └── RUNSAMP.jcl          # JCL to compile, bind, and run the program
├── TESTDATA/
│   └── BILLIN.dat            # Sample input test data (5 records)
├── TESTSCRIPTS/
│   └── test_sample.sh        # Automated validation test script
├── TESTRESULTS/
│   └── test_results_*.txt    # Generated test result reports
├── DOCS/
│   └── DASHBOARD.md          # Test results dashboard
└── README.md                 # This file
```

## Program Specification

### Input
- **File**: Sequential file assigned to DD name `BILLIN`
- **Record Layout** (Copybook `TEST.cpy`):

| Field                  | PIC Clause   | Description              |
|------------------------|-------------- |--------------------------|
| ACS-DETAIL-ACCOUNT     | 9(15)        | Account number           |
| ACS-DETAIL-ELEMENT-ID  | X(08)        | Billing element ID       |
| ACS-DETAIL-VOLUME      | S9(08)       | Usage volume (signed)    |
| ACS-DETAIL-DATE        | X(10)        | Date in YYYY-MM-DD       |

### Output
- **DB2 Table**: `BILL_TEST`

| Column              | Type       | Description              |
|---------------------|------------|--------------------------|
| TST_DTL_ACCT_NUM    | CHAR(15)   | Account number           |
| TST_DTL_ELEMENT_ID  | CHAR(8)    | Billing element ID       |
| TST_DTL_VOLUME      | INTEGER    | Usage volume             |
| TST_DTL_DATE        | CHAR(10)   | Date in YYYY-MM-DD       |

### Processing Logic
1. Open the input file and validate the file status
2. Read records sequentially from the input file
3. Map input fields to DB2 host variables
4. Execute `INSERT INTO BILL_TEST` for each record
5. Handle SQLCODE: 0 = success, -803 = duplicate key warning, other = error
6. Display execution summary with counts of read, inserted, and error records
7. Set RETURN-CODE: 0 = success, 4 = warnings, 16 = fatal error

### Error Handling
- File open failure: Display error message, set RC=16, abort
- File read failure: Display error message, set RC=16, abort
- DB2 duplicate key (-803): Log warning, continue processing
- DB2 other errors: Log SQLCODE, continue processing, set RC=4

## How to Run

### On z/OS
Submit the JCL:
```
SUBMIT JCL/RUNSAMP.jcl
```

### Run Tests
```bash
bash TESTSCRIPTS/test_sample.sh
```

## COBOL Coding Standards Applied
- Structured paragraph naming: `NNNN-DESCRIPTIVE-NAME`
- Proper `FILE STATUS` checking on all file I/O
- `EVALUATE TRUE` for multi-condition handling
- Meaningful `RETURN-CODE` values (0, 4, 16)
- `WORKING-STORAGE` counters initialized with `VALUE` clauses
- Inline comments and section headers for readability
- `COPY` and `EXEC SQL INCLUDE` for modular design
