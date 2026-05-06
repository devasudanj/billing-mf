#!/bin/bash
##########################################################################
# SCRIPT  : run_billing.sh
# PURPOSE : Compile and run the SAMPLE COBOL billing program locally,
#           then load the output into a SQLite database.
# AUTHOR  : Billing Team
# DATE    : 2026-05-06
##########################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/BUILD"
DATA_DIR="$PROJECT_ROOT/TESTDATA"
DB_FILE="$PROJECT_ROOT/BUILD/billing.db"

mkdir -p "$BUILD_DIR"

echo "========================================"
echo " SAMPLE Billing Program - Local Runner"
echo "========================================"

##########################################################################
# Step 1: Compile the COBOL program with GnuCOBOL
##########################################################################
echo ""
echo "[STEP 1] Compiling SAMPLE.cbl with GnuCOBOL..."

cobc -x -o "$BUILD_DIR/SAMPLE" \
    -I "$PROJECT_ROOT/COPYBOOK" \
    "$PROJECT_ROOT/COBOL/SAMPLE.cbl"

if [ $? -eq 0 ]; then
    echo "         Compilation SUCCESSFUL"
else
    echo "         Compilation FAILED"
    exit 1
fi

##########################################################################
# Step 2: Run the COBOL program
##########################################################################
echo ""
echo "[STEP 2] Running SAMPLE program..."

# Remove old output/database if they exist
rm -f "$BUILD_DIR/BILLOUT" "$DB_FILE"

# Set environment variables for file assignments
export BILLIN="$DATA_DIR/BILLIN.dat"
export BILLOUT="$BUILD_DIR/BILLOUT"

cd "$BUILD_DIR"
./SAMPLE
COBOL_RC=$?

echo ""
echo "         COBOL Return Code: $COBOL_RC"

if [ $COBOL_RC -gt 4 ]; then
    echo "         Program ended with errors (RC=$COBOL_RC)"
    exit $COBOL_RC
fi

##########################################################################
# Step 3: Load output into SQLite database
##########################################################################
echo ""
echo "[STEP 3] Loading output into SQLite database..."

if [ -f "$BUILD_DIR/BILLOUT" ]; then
    python3 "$SCRIPT_DIR/load_to_sqlite.py" "$BUILD_DIR/BILLOUT" "$DB_FILE"
else
    echo "         ERROR: Output file BILLOUT not found"
    exit 1
fi

##########################################################################
# Done
##########################################################################
echo ""
echo "========================================"
echo " Billing Pipeline Complete"
echo " Database: $DB_FILE"
echo "========================================"
