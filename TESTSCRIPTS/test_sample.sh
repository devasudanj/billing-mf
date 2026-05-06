#!/bin/bash
##########################################################################
# TEST SCRIPT : test_sample.sh
# PURPOSE     : Validate the SAMPLE COBOL billing program
# AUTHOR      : Billing Team
# DATE        : 2026-05-06
##########################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
RESULTS_DIR="$PROJECT_ROOT/TESTRESULTS"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULT_FILE="$RESULTS_DIR/test_results_${TIMESTAMP}.txt"

mkdir -p "$RESULTS_DIR"

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

##########################################################################
# Utility functions
##########################################################################
log_header() {
    echo "========================================" | tee -a "$RESULT_FILE"
    echo " $1" | tee -a "$RESULT_FILE"
    echo "========================================" | tee -a "$RESULT_FILE"
}

log_result() {
    local test_name="$1"
    local status="$2"
    local detail="$3"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    if [ "$status" = "PASS" ]; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        echo "[PASS] $test_name" | tee -a "$RESULT_FILE"
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        echo "[FAIL] $test_name - $detail" | tee -a "$RESULT_FILE"
    fi
}

##########################################################################
# TEST 1: Verify all source files exist
##########################################################################
log_header "TEST 1: Source File Existence Checks"

# Check SAMPLE.cbl
if [ -f "$PROJECT_ROOT/COBOL/SAMPLE.cbl" ]; then
    log_result "SAMPLE.cbl exists" "PASS"
else
    log_result "SAMPLE.cbl exists" "FAIL" "File not found"
fi

# Check TEST.cpy
if [ -f "$PROJECT_ROOT/COPYBOOK/TEST.cpy" ]; then
    log_result "TEST.cpy exists" "PASS"
else
    log_result "TEST.cpy exists" "FAIL" "File not found"
fi

# Check TESTDCL.cbl
if [ -f "$PROJECT_ROOT/DCLGEN/TESTDCL.cbl" ]; then
    log_result "TESTDCL.cbl exists" "PASS"
else
    log_result "TESTDCL.cbl exists" "FAIL" "File not found"
fi

# Check JCL
if [ -f "$PROJECT_ROOT/JCL/RUNSAMP.jcl" ]; then
    log_result "RUNSAMP.jcl exists" "PASS"
else
    log_result "RUNSAMP.jcl exists" "FAIL" "File not found"
fi

# Check test data
if [ -f "$PROJECT_ROOT/TESTDATA/BILLIN.dat" ]; then
    log_result "BILLIN.dat test data exists" "PASS"
else
    log_result "BILLIN.dat test data exists" "FAIL" "File not found"
fi

##########################################################################
# TEST 2: COBOL Source Structure Validation
##########################################################################
log_header "TEST 2: COBOL Source Structure Validation"

SAMPLE_SRC="$PROJECT_ROOT/COBOL/SAMPLE.cbl"

# Check required divisions
for div in "IDENTIFICATION DIVISION" "ENVIRONMENT DIVISION" "DATA DIVISION" "PROCEDURE DIVISION"; do
    if grep -q "$div" "$SAMPLE_SRC"; then
        log_result "Contains $div" "PASS"
    else
        log_result "Contains $div" "FAIL" "Division not found"
    fi
done

# Check PROGRAM-ID
if grep -q "PROGRAM-ID" "$SAMPLE_SRC"; then
    log_result "Contains PROGRAM-ID" "PASS"
else
    log_result "Contains PROGRAM-ID" "FAIL" "PROGRAM-ID not found"
fi

# Check FILE-CONTROL
if grep -q "FILE-CONTROL" "$SAMPLE_SRC"; then
    log_result "Contains FILE-CONTROL" "PASS"
else
    log_result "Contains FILE-CONTROL" "FAIL" "FILE-CONTROL not found"
fi

##########################################################################
# TEST 3: Copybook Inclusion Validation
##########################################################################
log_header "TEST 3: Copybook and DCLGEN Inclusion"

# Check COPY TEST reference
if grep -q "COPY TEST" "$SAMPLE_SRC"; then
    log_result "COPY TEST statement present" "PASS"
else
    log_result "COPY TEST statement present" "FAIL" "COPY TEST not found"
fi

# Check INCLUDE TESTDCL reference
if grep -q "INCLUDE TESTDCL" "$SAMPLE_SRC"; then
    log_result "EXEC SQL INCLUDE TESTDCL present" "PASS"
else
    log_result "EXEC SQL INCLUDE TESTDCL present" "FAIL" "INCLUDE TESTDCL not found"
fi

# Check INCLUDE SQLCA reference
if grep -q "INCLUDE SQLCA" "$SAMPLE_SRC"; then
    log_result "EXEC SQL INCLUDE SQLCA present" "PASS"
else
    log_result "EXEC SQL INCLUDE SQLCA present" "FAIL" "INCLUDE SQLCA not found"
fi

##########################################################################
# TEST 4: DB2 SQL Validation
##########################################################################
log_header "TEST 4: DB2 SQL Statement Validation"

# Check INSERT INTO BILL_TEST
if grep -q "INSERT INTO BILL_TEST" "$SAMPLE_SRC"; then
    log_result "INSERT INTO BILL_TEST present" "PASS"
else
    log_result "INSERT INTO BILL_TEST present" "FAIL" "INSERT statement not found"
fi

# Check host variable references
for var in ":TST-DTL-ACCT-NUM" ":TST-DTL-ELEMENT-ID" ":TST-DTL-VOLUME" ":TST-DTL-DATE"; do
    if grep -q "$var" "$SAMPLE_SRC"; then
        log_result "Host variable $var used" "PASS"
    else
        log_result "Host variable $var used" "FAIL" "Host variable not found"
    fi
done

# Check SQLCODE evaluation
if grep -q "SQLCODE" "$SAMPLE_SRC"; then
    log_result "SQLCODE error handling present" "PASS"
else
    log_result "SQLCODE error handling present" "FAIL" "SQLCODE not checked"
fi

##########################################################################
# TEST 5: Copybook Record Layout Validation
##########################################################################
log_header "TEST 5: Copybook Record Layout Validation"

COPY_SRC="$PROJECT_ROOT/COPYBOOK/TEST.cpy"

for field in "ACS-BILL-DETAIL-RECORD" "ACS-DETAIL-ACCOUNT" "ACS-DETAIL-ELEMENT-ID" "ACS-DETAIL-VOLUME" "ACS-DETAIL-DATE"; do
    if grep -q "$field" "$COPY_SRC"; then
        log_result "Copybook field $field present" "PASS"
    else
        log_result "Copybook field $field present" "FAIL" "Field not found"
    fi
done

##########################################################################
# TEST 6: DCLGEN Table Declaration Validation
##########################################################################
log_header "TEST 6: DCLGEN Table Declaration Validation"

DCL_SRC="$PROJECT_ROOT/DCLGEN/TESTDCL.cbl"

# Check table declaration
if grep -q "DECLARE BILL_TEST TABLE" "$DCL_SRC"; then
    log_result "DECLARE BILL_TEST TABLE present" "PASS"
else
    log_result "DECLARE BILL_TEST TABLE present" "FAIL" "Declaration not found"
fi

# Check DCLGEN host structure
for field in "TST-DTL-ACCT-NUM" "TST-DTL-ELEMENT-ID" "TST-DTL-VOLUME" "TST-DTL-DATE"; do
    if grep -q "$field" "$DCL_SRC"; then
        log_result "DCLGEN field $field present" "PASS"
    else
        log_result "DCLGEN field $field present" "FAIL" "Field not found"
    fi
done

##########################################################################
# TEST 7: Test Data File Validation
##########################################################################
log_header "TEST 7: Test Data File Validation"

DATA_FILE="$PROJECT_ROOT/TESTDATA/BILLIN.dat"

# Check record count
RECORD_COUNT=$(wc -l < "$DATA_FILE" | tr -d ' ')
if [ "$RECORD_COUNT" -ge 1 ]; then
    log_result "Test data has $RECORD_COUNT records" "PASS"
else
    log_result "Test data has records" "FAIL" "No records found"
fi

# Check record length (41 chars per record)
BAD_RECORDS=0
while IFS= read -r line; do
    LEN=${#line}
    if [ "$LEN" -ne 41 ]; then
        BAD_RECORDS=$((BAD_RECORDS + 1))
    fi
done < "$DATA_FILE"

if [ "$BAD_RECORDS" -eq 0 ]; then
    log_result "All records are 41 characters" "PASS"
else
    log_result "Record length check" "FAIL" "$BAD_RECORDS records have incorrect length"
fi

##########################################################################
# TEST 8: COBOL Coding Standards Checks
##########################################################################
log_header "TEST 8: COBOL Coding Standards Checks"

# Check paragraph naming convention (numeric prefix)
PARA_COUNT=$(grep -cE "^       [0-9]{4}-" "$SAMPLE_SRC" || true)
if [ "$PARA_COUNT" -ge 3 ]; then
    log_result "Paragraph naming convention (NNNN-NAME)" "PASS"
else
    log_result "Paragraph naming convention (NNNN-NAME)" "FAIL" "Found $PARA_COUNT paragraphs"
fi

# Check for STOP RUN
if grep -q "STOP RUN" "$SAMPLE_SRC"; then
    log_result "STOP RUN present" "PASS"
else
    log_result "STOP RUN present" "FAIL" "STOP RUN not found"
fi

# Check for file status handling
if grep -q "FILE STATUS" "$SAMPLE_SRC"; then
    log_result "FILE STATUS defined" "PASS"
else
    log_result "FILE STATUS defined" "FAIL" "FILE STATUS not found"
fi

# Check for RETURN-CODE usage
if grep -q "RETURN-CODE" "$SAMPLE_SRC"; then
    log_result "RETURN-CODE set" "PASS"
else
    log_result "RETURN-CODE set" "FAIL" "RETURN-CODE not used"
fi

##########################################################################
# TEST 9: JCL Validation
##########################################################################
log_header "TEST 9: JCL Validation"

JCL_SRC="$PROJECT_ROOT/JCL/RUNSAMP.jcl"

# Check for JOB card
if grep -q "^//RUNSAMP.*JOB" "$JCL_SRC"; then
    log_result "JOB card present" "PASS"
else
    log_result "JOB card present" "FAIL" "JOB card not found"
fi

# Check for BILLIN DD
if grep -q "BILLIN" "$JCL_SRC"; then
    log_result "BILLIN DD statement present" "PASS"
else
    log_result "BILLIN DD statement present" "FAIL" "BILLIN DD not found"
fi

# Check for BIND step
if grep -q "BIND" "$JCL_SRC"; then
    log_result "BIND step present" "PASS"
else
    log_result "BIND step present" "FAIL" "BIND step not found"
fi

##########################################################################
# SUMMARY
##########################################################################
log_header "TEST EXECUTION SUMMARY"
echo "" | tee -a "$RESULT_FILE"
echo "Timestamp       : $TIMESTAMP" | tee -a "$RESULT_FILE"
echo "Total Tests     : $TOTAL_TESTS" | tee -a "$RESULT_FILE"
echo "Passed          : $PASSED_TESTS" | tee -a "$RESULT_FILE"
echo "Failed          : $FAILED_TESTS" | tee -a "$RESULT_FILE"
echo "" | tee -a "$RESULT_FILE"

if [ "$FAILED_TESTS" -eq 0 ]; then
    echo "OVERALL RESULT  : ALL TESTS PASSED" | tee -a "$RESULT_FILE"
    echo "" | tee -a "$RESULT_FILE"
    echo "Results saved to: $RESULT_FILE"
    exit 0
else
    echo "OVERALL RESULT  : $FAILED_TESTS TEST(S) FAILED" | tee -a "$RESULT_FILE"
    echo "" | tee -a "$RESULT_FILE"
    echo "Results saved to: $RESULT_FILE"
    exit 1
fi
