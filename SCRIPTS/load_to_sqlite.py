#!/usr/bin/env python3
"""
Load COBOL billing output into a local SQLite database (BILL_TEST table).

Usage:
    python3 load_to_sqlite.py <output_file> [database_file]

The output file is pipe-delimited with fields:
    ACCT_NUM | ELEMENT_ID | VOLUME | DATE
"""

import sqlite3
import sys
import os


DB_DEFAULT = "billing.db"


def create_table(conn):
    """Create the BILL_TEST table matching the DB2 DCLGEN specification."""
    conn.execute("""
        CREATE TABLE IF NOT EXISTS BILL_TEST (
            TST_DTL_ACCT_NUM   CHAR(15) NOT NULL,
            TST_DTL_ELEMENT_ID CHAR(8)  NOT NULL,
            TST_DTL_VOLUME     INTEGER  NOT NULL,
            TST_DTL_DATE       CHAR(10) NOT NULL,
            PRIMARY KEY (TST_DTL_ACCT_NUM, TST_DTL_ELEMENT_ID)
        )
    """)
    conn.commit()


def load_records(conn, output_file):
    """Parse the pipe-delimited COBOL output and insert into BILL_TEST."""
    inserted = 0
    errors = 0
    duplicates = 0

    with open(output_file, "r") as f:
        for line_num, line in enumerate(f, 1):
            line = line.rstrip("\n")
            if not line.strip():
                continue

            parts = line.split("|")
            if len(parts) != 4:
                print(f"WARNING: Line {line_num}: unexpected format: {line!r}")
                errors += 1
                continue

            acct_num = parts[0].strip()
            element_id = parts[1].strip()
            try:
                volume = int(parts[2].strip())
            except ValueError:
                print(f"WARNING: Line {line_num}: invalid volume: {parts[2]!r}")
                errors += 1
                continue
            date_val = parts[3].strip()

            try:
                conn.execute(
                    "INSERT INTO BILL_TEST VALUES (?, ?, ?, ?)",
                    (acct_num, element_id, volume, date_val),
                )
                inserted += 1
            except sqlite3.IntegrityError:
                print(f"WARNING: Duplicate key for account {acct_num}")
                duplicates += 1

    conn.commit()
    return inserted, duplicates, errors


def display_results(conn):
    """Query and display all records in BILL_TEST."""
    print("\n========================================")
    print(" BILL_TEST Table Contents")
    print("========================================")
    print(f"{'ACCT_NUM':<17} {'ELEMENT_ID':<10} {'VOLUME':>10} {'DATE':<12}")
    print("-" * 50)

    cursor = conn.execute(
        "SELECT TST_DTL_ACCT_NUM, TST_DTL_ELEMENT_ID, "
        "TST_DTL_VOLUME, TST_DTL_DATE FROM BILL_TEST"
    )
    rows = cursor.fetchall()
    for row in rows:
        print(f"{row[0]:<17} {row[1]:<10} {row[2]:>10} {row[3]:<12}")

    print("-" * 50)
    print(f"Total records: {len(rows)}")
    return len(rows)


def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <output_file> [database_file]")
        sys.exit(1)

    output_file = sys.argv[1]
    db_file = sys.argv[2] if len(sys.argv) > 2 else DB_DEFAULT

    if not os.path.exists(output_file):
        print(f"ERROR: Output file not found: {output_file}")
        sys.exit(1)

    conn = sqlite3.connect(db_file)
    try:
        create_table(conn)
        inserted, duplicates, errors = load_records(conn, output_file)

        print("\n========================================")
        print(" SQLite Load Summary")
        print("========================================")
        print(f" Database        : {db_file}")
        print(f" Records Inserted: {inserted}")
        print(f" Duplicates      : {duplicates}")
        print(f" Errors          : {errors}")
        print("========================================")

        display_results(conn)
    finally:
        conn.close()

    if errors > 0:
        sys.exit(1)
    sys.exit(0)


if __name__ == "__main__":
    main()
