# Billing Mainframe - SAMPLE COBOL Program

## Overview

The **SAMPLE** program is a batch COBOL billing application that reads billing detail records from a sequential input file and loads them into a local **SQLite** database (`BILL_TEST` table). The program is designed to follow mainframe COBOL coding standards while being fully runnable on a local machine using GnuCOBOL.

## Project Structure

```
billing-mf/
├── COBOL/
│   └── SAMPLE.cbl              # Main COBOL billing program
├── COPYBOOK/
│   └── TEST.cpy                # Input file record layout copybook
├── DCLGEN/
│   └── TESTDCL.cbl             # DB2 DCLGEN for BILL_TEST table (reference)
├── JCL/
│   └── RUNSAMP.jcl             # JCL to compile/bind/run on z/OS
├── SCRIPTS/
│   ├── run_billing.sh           # Local runner: compile, execute, load to SQLite
│   └── load_to_sqlite.py        # Python script to load COBOL output into SQLite
├── TESTDATA/
│   └── BILLIN.dat               # Sample input test data (5 records)
├── TESTSCRIPTS/
│   └── test_sample.sh           # Automated test script (47 end-to-end tests)
├── DOCS/
│   └── DASHBOARD.md             # Test results dashboard
└── README.md
```

## Prerequisites

- **GnuCOBOL** (`cobc`) - COBOL compiler for local execution
- **Python 3** - For the SQLite database loader
- **SQLite3** - Bundled with Python's standard library

### Install GnuCOBOL

```bash
# Ubuntu/Debian
sudo apt-get install -y gnucobol

# macOS
brew install gnucobol
```

## Quick Start

### Run the Full Pipeline

```bash
bash SCRIPTS/run_billing.sh
```

This will:
1. Compile `SAMPLE.cbl` with GnuCOBOL
2. Execute the program (reads `TESTDATA/BILLIN.dat`, writes `BUILD/BILLOUT`)
3. Load the output into SQLite database (`BUILD/billing.db`)

### Run Tests

```bash
bash TESTSCRIPTS/test_sample.sh
```

Runs 47 end-to-end tests covering:
- Source file existence
- COBOL source structure validation
- Copybook and DCLGEN field validation
- COBOL coding standards compliance
- Compilation with GnuCOBOL
- Program execution and output verification
- SQLite database load and data integrity
- Duplicate record handling

## Program Specification

### Input
- **File**: Sequential file assigned to environment variable `BILLIN`
- **Record Layout** (Copybook `TEST.cpy`):

| Field                  | PIC Clause   | Description              |
|------------------------|-------------- |--------------------------|
| ACS-DETAIL-ACCOUNT     | 9(15)        | Account number           |
| ACS-DETAIL-ELEMENT-ID  | X(08)        | Billing element ID       |
| ACS-DETAIL-VOLUME      | 9(08)        | Usage volume             |
| ACS-DETAIL-DATE        | X(10)        | Date in YYYY-MM-DD       |

### Output
- **Local**: Pipe-delimited output file loaded into SQLite
- **z/OS**: DB2 table `BILL_TEST` (via JCL)

| Column / Field      | Type       | Description              |
|---------------------|------------|--------------------------|
| TST_DTL_ACCT_NUM    | CHAR(15)   | Account number           |
| TST_DTL_ELEMENT_ID  | CHAR(8)    | Billing element ID       |
| TST_DTL_VOLUME      | INTEGER    | Usage volume             |
| TST_DTL_DATE        | CHAR(10)   | Date in YYYY-MM-DD       |

### Processing Logic
1. Open input and output files, validate file status
2. Read records sequentially from the input file
3. Map input fields to output format (pipe-delimited)
4. Write each record to the output file
5. Display execution summary with record counts
6. Python loader inserts records into SQLite `BILL_TEST` table

### Error Handling
- File open failure: Display error, set RC=16, abort
- File read failure: Display error, set RC=16, abort
- Write failure: Log error, continue processing, set RC=4
- SQLite duplicate key: Log warning, continue

## COBOL Coding Standards Applied
- Structured paragraph naming: `NNNN-DESCRIPTIVE-NAME`
- `FILE STATUS` checking on all file I/O
- `EVALUATE TRUE` for multi-condition handling
- Meaningful `RETURN-CODE` values (0=success, 4=warnings, 16=fatal)
- `COPY` for modular copybook design
- Inline comments and section headers
