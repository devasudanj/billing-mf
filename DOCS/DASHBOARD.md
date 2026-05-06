# SAMPLE Program - Test Results Dashboard

## Latest Test Run

| Metric             | Value                     |
|--------------------|---------------------------|
| **Run Date**       | 2026-05-06                |
| **Total Tests**    | 39                        |
| **Passed**         | 39                        |
| **Failed**         | 0                         |
| **Overall Result** | ALL TESTS PASSED          |

---

## Test Categories

### 1. Source File Existence (5 tests)

| Test                         | Result |
|------------------------------|--------|
| SAMPLE.cbl exists            | PASS   |
| TEST.cpy exists              | PASS   |
| TESTDCL.cbl exists           | PASS   |
| RUNSAMP.jcl exists           | PASS   |
| BILLIN.dat test data exists  | PASS   |

### 2. COBOL Source Structure (6 tests)

| Test                              | Result |
|-----------------------------------|--------|
| Contains IDENTIFICATION DIVISION  | PASS   |
| Contains ENVIRONMENT DIVISION     | PASS   |
| Contains DATA DIVISION            | PASS   |
| Contains PROCEDURE DIVISION       | PASS   |
| Contains PROGRAM-ID               | PASS   |
| Contains FILE-CONTROL             | PASS   |

### 3. Copybook and DCLGEN Inclusion (3 tests)

| Test                              | Result |
|-----------------------------------|--------|
| COPY TEST statement present       | PASS   |
| EXEC SQL INCLUDE TESTDCL present  | PASS   |
| EXEC SQL INCLUDE SQLCA present    | PASS   |

### 4. DB2 SQL Statement Validation (6 tests)

| Test                                    | Result |
|-----------------------------------------|--------|
| INSERT INTO BILL_TEST present           | PASS   |
| Host variable :TST-DTL-ACCT-NUM used    | PASS   |
| Host variable :TST-DTL-ELEMENT-ID used  | PASS   |
| Host variable :TST-DTL-VOLUME used      | PASS   |
| Host variable :TST-DTL-DATE used        | PASS   |
| SQLCODE error handling present          | PASS   |

### 5. Copybook Record Layout (5 tests)

| Test                                        | Result |
|---------------------------------------------|--------|
| Field ACS-BILL-DETAIL-RECORD present        | PASS   |
| Field ACS-DETAIL-ACCOUNT present            | PASS   |
| Field ACS-DETAIL-ELEMENT-ID present         | PASS   |
| Field ACS-DETAIL-VOLUME present             | PASS   |
| Field ACS-DETAIL-DATE present               | PASS   |

### 6. DCLGEN Table Declaration (5 tests)

| Test                                    | Result |
|-----------------------------------------|--------|
| DECLARE BILL_TEST TABLE present         | PASS   |
| DCLGEN field TST-DTL-ACCT-NUM present   | PASS   |
| DCLGEN field TST-DTL-ELEMENT-ID present | PASS   |
| DCLGEN field TST-DTL-VOLUME present     | PASS   |
| DCLGEN field TST-DTL-DATE present       | PASS   |

### 7. Test Data File (2 tests)

| Test                            | Result |
|---------------------------------|--------|
| Test data has 5 records         | PASS   |
| All records are 41 characters   | PASS   |

### 8. COBOL Coding Standards (4 tests)

| Test                                         | Result |
|----------------------------------------------|--------|
| Paragraph naming convention (NNNN-NAME)      | PASS   |
| STOP RUN present                             | PASS   |
| FILE STATUS defined                          | PASS   |
| RETURN-CODE set                              | PASS   |

### 9. JCL Validation (3 tests)

| Test                            | Result |
|---------------------------------|--------|
| JOB card present                | PASS   |
| BILLIN DD statement present     | PASS   |
| BIND step present               | PASS   |

---

## Test Data Summary

| Account Number    | Element ID | Volume   | Date       |
|-------------------|------------|----------|------------|
| 000000000012345   | ELMT0001   | 00001000 | 2026-05-01 |
| 000000000067890   | ELMT0002   | 00002500 | 2026-05-02 |
| 000000000011111   | ELMT0003   | 00000750 | 2026-05-03 |
| 000000000022222   | ELMT0004   | 00010000 | 2026-05-04 |
| 000000000033333   | ELMT0005   | 00005000 | 2026-05-05 |

---

## Expected Program Output (on z/OS execution)

```
SAMPLE: BILLING INPUT FILE OPENED SUCCESSFULLY
****************************************
* SAMPLE PROGRAM - EXECUTION SUMMARY   *
****************************************
* RECORDS READ      : 000000005
* RECORDS INSERTED  : 000000005
* RECORDS IN ERROR  : 000000000
****************************************
```
