#!/bin/bash
##########################################################################
# TEST SCRIPT : test_sample.sh
# PURPOSE     : Validate the SAMPLE COBOL billing program end-to-end
#               including compilation, execution, and SQLite database load
# AUTHOR      : Billing Team
# DATE        : 2026-05-06
##########################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
RESULTS_DIR="$PROJECT_ROOT/TESTRESULTS"
BUILD_DIR="$PROJECT_ROOT/BUILD"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULT_FILE="$RESULTS_DIR/test_results_${TIMESTAMP}.txt"

mkdir -p "$RESULTS_DIR" "$BUILD_DIR"

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

for f in "COBOL/SAMPLE.cbl" "COPYBOOK/TEST.cpy" "DCLGEN/TESTDCL.cbl" \
         "JCL/RUNSAMP.jcl" "TESTDATA/BILLIN.dat" \
         "SCRIPTS/run_billing.sh" "SCRIPTS/load_to_sqlite.py"; do
    if [ -f "$PROJECT_ROOT/$f" ]; then
        log_result "$f exists" "PASS"
    else
        log_result "$f exists" "FAIL" "File not found"
    fi
done

##########################################################################
# TEST 2: COBOL Source Structure Validation
##########################################################################
log_header "TEST 2: COBOL Source Structure Validation"

SAMPLE_SRC="$PROJECT_ROOT/COBOL/SAMPLE.cbl"

for div in "IDENTIFICATION DIVISION" "ENVIRONMENT DIVISION" \
           "DATA DIVISION" "PROCEDURE DIVISION"; do
    if grep -q "$div" "$SAMPLE_SRC"; then
        log_result "Contains $div" "PASS"
    else
        log_result "Contains $div" "FAIL" "Division not found"
    fi
done

if grep -q "PROGRAM-ID" "$SAMPLE_SRC"; then
    log_result "Contains PROGRAM-ID" "PASS"
else
    log_result "Contains PROGRAM-ID" "FAIL" "PROGRAM-ID not found"
fi

if grep -q "FILE-CONTROL" "$SAMPLE_SRC"; then
    log_result "Contains FILE-CONTROL" "PASS"
else
    log_result "Contains FILE-CONTROL" "FAIL" "FILE-CONTROL not found"
fi

##########################################################################
# TEST 3: Copybook Record Layout Validation
##########################################################################
log_header "TEST 3: Copybook Record Layout Validation"

COPY_SRC="$PROJECT_ROOT/COPYBOOK/TEST.cpy"

for field in "ACS-BILL-DETAIL-RECORD" "ACS-DETAIL-ACCOUNT" \
             "ACS-DETAIL-ELEMENT-ID" "ACS-DETAIL-VOLUME" "ACS-DETAIL-DATE"; do
    if grep -q "$field" "$COPY_SRC"; then
        log_result "Copybook field $field present" "PASS"
    else
        log_result "Copybook field $field present" "FAIL" "Field not found"
    fi
done

if grep -q 'COPY.*TEST' "$SAMPLE_SRC"; then
    log_result "COPY TEST statement in SAMPLE.cbl" "PASS"
else
    log_result "COPY TEST statement in SAMPLE.cbl" "FAIL" "Not found"
fi

##########################################################################
# TEST 4: DCLGEN Table Declaration Validation
##########################################################################
log_header "TEST 4: DCLGEN Table Declaration Validation"

DCL_SRC="$PROJECT_ROOT/DCLGEN/TESTDCL.cbl"

if grep -q "DECLARE BILL_TEST TABLE" "$DCL_SRC"; then
    log_result "DECLARE BILL_TEST TABLE present" "PASS"
else
    log_result "DECLARE BILL_TEST TABLE present" "FAIL" "Declaration not found"
fi

for field in "TST-DTL-ACCT-NUM" "TST-DTL-ELEMENT-ID" \
             "TST-DTL-VOLUME" "TST-DTL-DATE"; do
    if grep -q "$field" "$DCL_SRC"; then
        log_result "DCLGEN field $field present" "PASS"
    else
        log_result "DCLGEN field $field present" "FAIL" "Field not found"
    fi
done

##########################################################################
# TEST 5: COBOL Coding Standards Checks
##########################################################################
log_header "TEST 5: COBOL Coding Standards Checks"

PARA_COUNT=$(grep -cE "^       [0-9]{4}-" "$SAMPLE_SRC" || true)
if [ "$PARA_COUNT" -ge 3 ]; then
    log_result "Paragraph naming convention (NNNN-NAME)" "PASS"
else
    log_result "Paragraph naming convention (NNNN-NAME)" "FAIL" \
        "Found $PARA_COUNT paragraphs"
fi

if grep -q "STOP RUN" "$SAMPLE_SRC"; then
    log_result "STOP RUN present" "PASS"
else
    log_result "STOP RUN present" "FAIL" "Not found"
fi

if grep -q "FILE STATUS" "$SAMPLE_SRC"; then
    log_result "FILE STATUS defined" "PASS"
else
    log_result "FILE STATUS defined" "FAIL" "Not found"
fi

if grep -q "RETURN-CODE" "$SAMPLE_SRC"; then
    log_result "RETURN-CODE set" "PASS"
else
    log_result "RETURN-CODE set" "FAIL" "Not found"
fi

##########################################################################
# TEST 6: JCL Validation
##########################################################################
log_header "TEST 6: JCL Validation"

JCL_SRC="$PROJECT_ROOT/JCL/RUNSAMP.jcl"

if grep -q "^//RUNSAMP.*JOB" "$JCL_SRC"; then
    log_result "JOB card present" "PASS"
else
    log_result "JOB card present" "FAIL" "Not found"
fi

if grep -q "BILLIN" "$JCL_SRC"; then
    log_result "BILLIN DD statement present" "PASS"
else
    log_result "BILLIN DD statement present" "FAIL" "Not found"
fi

if grep -q "BIND" "$JCL_SRC"; then
    log_result "BIND step present" "PASS"
else
    log_result "BIND step present" "FAIL" "Not found"
fi

##########################################################################
# TEST 7: Compilation Test (GnuCOBOL)
##########################################################################
log_header "TEST 7: COBOL Compilation"

rm -f "$BUILD_DIR/SAMPLE"

COMPILE_OUTPUT=$(cobc -x -o "$BUILD_DIR/SAMPLE" \
    -I "$PROJECT_ROOT/COPYBOOK" \
    "$PROJECT_ROOT/COBOL/SAMPLE.cbl" 2>&1) || true

if [ -f "$BUILD_DIR/SAMPLE" ]; then
    log_result "COBOL compilation succeeds" "PASS"
else
    log_result "COBOL compilation succeeds" "FAIL" "$COMPILE_OUTPUT"
fi

##########################################################################
# TEST 8: Program Execution Test
##########################################################################
log_header "TEST 8: Program Execution"

rm -f "$BUILD_DIR/BILLOUT" "$BUILD_DIR/billing.db"

export BILLIN="$PROJECT_ROOT/TESTDATA/BILLIN.dat"
export BILLOUT="$BUILD_DIR/BILLOUT"

EXEC_OUTPUT=$(cd "$BUILD_DIR" && ./SAMPLE 2>&1) || true
COBOL_RC=$?

if [ $COBOL_RC -le 4 ]; then
    log_result "Program executes successfully (RC=$COBOL_RC)" "PASS"
else
    log_result "Program executes successfully" "FAIL" "RC=$COBOL_RC"
fi

if echo "$EXEC_OUTPUT" | grep -q "FILES OPENED SUCCESSFULLY"; then
    log_result "Files opened successfully" "PASS"
else
    log_result "Files opened successfully" "FAIL" "Open message not found"
fi

if echo "$EXEC_OUTPUT" | grep -q "RECORDS READ.*000000005"; then
    log_result "All 5 records read" "PASS"
else
    log_result "All 5 records read" "FAIL" "Unexpected count"
fi

if echo "$EXEC_OUTPUT" | grep -q "RECORDS INSERTED.*000000005"; then
    log_result "All 5 records written" "PASS"
else
    log_result "All 5 records written" "FAIL" "Unexpected count"
fi

if echo "$EXEC_OUTPUT" | grep -q "RECORDS IN ERROR.*000000000"; then
    log_result "Zero errors reported" "PASS"
else
    log_result "Zero errors reported" "FAIL" "Errors found"
fi

##########################################################################
# TEST 9: Output File Validation
##########################################################################
log_header "TEST 9: Output File Validation"

if [ -f "$BUILD_DIR/BILLOUT" ]; then
    log_result "Output file BILLOUT created" "PASS"
else
    log_result "Output file BILLOUT created" "FAIL" "File not found"
fi

OUT_LINES=$(wc -l < "$BUILD_DIR/BILLOUT" 2>/dev/null | tr -d ' ')
if [ "$OUT_LINES" = "5" ]; then
    log_result "Output file has 5 records" "PASS"
else
    log_result "Output file has 5 records" "FAIL" "Found $OUT_LINES"
fi

if head -1 "$BUILD_DIR/BILLOUT" | grep -q "000000000012345|ELMT0001|.*1000|2026-05-01"; then
    log_result "First record data correct" "PASS"
else
    log_result "First record data correct" "FAIL" \
        "Got: $(head -1 "$BUILD_DIR/BILLOUT")"
fi

##########################################################################
# TEST 10: SQLite Database Load
##########################################################################
log_header "TEST 10: SQLite Database Load"

DB_FILE="$BUILD_DIR/billing.db"
LOAD_OUTPUT=$(python3 "$PROJECT_ROOT/SCRIPTS/load_to_sqlite.py" \
    "$BUILD_DIR/BILLOUT" "$DB_FILE" 2>&1) || true

if [ -f "$DB_FILE" ]; then
    log_result "SQLite database created" "PASS"
else
    log_result "SQLite database created" "FAIL" "File not found"
fi

if echo "$LOAD_OUTPUT" | grep -q "Records Inserted: 5"; then
    log_result "All 5 records inserted into SQLite" "PASS"
else
    log_result "All 5 records inserted into SQLite" "FAIL" "$LOAD_OUTPUT"
fi

if echo "$LOAD_OUTPUT" | grep -q "Errors          : 0"; then
    log_result "Zero load errors" "PASS"
else
    log_result "Zero load errors" "FAIL" "Errors found"
fi

# Verify database contents with SQL queries
DB_COUNT=$(python3 -c "
import sqlite3
conn = sqlite3.connect('$DB_FILE')
c = conn.execute('SELECT COUNT(*) FROM BILL_TEST')
print(c.fetchone()[0])
conn.close()
" 2>/dev/null)

if [ "$DB_COUNT" = "5" ]; then
    log_result "BILL_TEST has 5 rows" "PASS"
else
    log_result "BILL_TEST has 5 rows" "FAIL" "Found $DB_COUNT"
fi

# Check specific record
DB_REC1=$(python3 -c "
import sqlite3
conn = sqlite3.connect('$DB_FILE')
c = conn.execute(\"SELECT TST_DTL_ACCT_NUM, TST_DTL_ELEMENT_ID, TST_DTL_VOLUME, TST_DTL_DATE FROM BILL_TEST WHERE TST_DTL_ACCT_NUM LIKE '%12345'\")
row = c.fetchone()
if row:
    print(f'{row[0].strip()}|{row[1].strip()}|{row[2]}|{row[3].strip()}')
conn.close()
" 2>/dev/null)

if [ "$DB_REC1" = "000000000012345|ELMT0001|1000|2026-05-01" ]; then
    log_result "Record 1 data verified in database" "PASS"
else
    log_result "Record 1 data verified in database" "FAIL" "Got: $DB_REC1"
fi

# Check record 5
DB_REC5=$(python3 -c "
import sqlite3
conn = sqlite3.connect('$DB_FILE')
c = conn.execute(\"SELECT TST_DTL_ACCT_NUM, TST_DTL_ELEMENT_ID, TST_DTL_VOLUME, TST_DTL_DATE FROM BILL_TEST WHERE TST_DTL_ACCT_NUM LIKE '%33333'\")
row = c.fetchone()
if row:
    print(f'{row[0].strip()}|{row[1].strip()}|{row[2]}|{row[3].strip()}')
conn.close()
" 2>/dev/null)

if [ "$DB_REC5" = "000000000033333|ELMT0005|5000|2026-05-05" ]; then
    log_result "Record 5 data verified in database" "PASS"
else
    log_result "Record 5 data verified in database" "FAIL" "Got: $DB_REC5"
fi

##########################################################################
# TEST 11: Duplicate Record Handling
##########################################################################
log_header "TEST 11: Duplicate Record Handling"

DUP_OUTPUT=$(python3 "$PROJECT_ROOT/SCRIPTS/load_to_sqlite.py" \
    "$BUILD_DIR/BILLOUT" "$DB_FILE" 2>&1) || true

if echo "$DUP_OUTPUT" | grep -q "Duplicates      : 5"; then
    log_result "Duplicate records detected correctly" "PASS"
else
    log_result "Duplicate records detected correctly" "FAIL" "$DUP_OUTPUT"
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
