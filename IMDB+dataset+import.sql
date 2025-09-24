#!/usr/bin/env python3
"""
sql_to_csv.py

Usage:
    # default (no args): reads ./import.sql and writes CSVs into current directory
    python3 sql_to_csv.py

    # or explicitly:
    python3 sql_to_csv.py import.sql .

This script:
 - Scans the SQL file for "INSERT INTO <table> VALUES (...),(...),...;" blocks
 - Parses each tuple robustly (quotes, escaped quotes, commas inside quoted strings, NULL)
 - Writes/appends rows into CSV files: ./<table>.csv
 - Uses known header mappings for your IMDb schema; otherwise falls back to col1..colN
"""

import sys
import os
import re
import csv
import argparse

# ---------------------------
# Configure known table headers
# ---------------------------
HEADERS = {
    "movie": ["id", "title", "year", "date_published", "duration", "country", "worlwide_gross_income", "languages", "production_company"],
    "genre": ["movie_id", "genre"],
    "director_mapping": ["movie_id", "name_id"],
    "role_mapping": ["movie_id", "name_id", "category"],
    "names": ["id", "name", "height", "date_of_birth", "known_for_movies"],
    "ratings": ["movie_id", "avg_rating", "total_votes", "median_rating"],
}

# ---------------------------
# Parsing helpers (robust)
# ---------------------------
def split_top_level_tuples(s):
    tuples = []
    i = 0
    n = len(s)
    while i < n:
        while i < n and s[i] != '(':
            i += 1
        if i >= n:
            break
        i += 1
        start = i
        in_single = False
        prev = ''
        depth = 1
        while i < n:
            ch = s[i]
            if ch == "'" and prev != '\\':
                in_single = not in_single
            elif ch == ')' and not in_single:
                depth -= 1
                if depth == 0:
                    tuples.append(s[start:i])
                    i += 1
                    break
            elif ch == '(' and not in_single:
                depth += 1
            prev = ch
            i += 1
    return tuples

def split_fields(tuple_content):
    fields = []
    cur = []
    in_single = False
    i = 0
    prev = ''
    s = tuple_content
    while i < len(s):
        ch = s[i]
        if ch == "'" and prev != '\\':
            in_single = not in_single
            cur.append(ch)
        elif ch == ',' and not in_single:
            fields.append(''.join(cur).strip())
            cur = []
        else:
            cur.append(ch)
        prev = ch
        i += 1
    if cur:
        fields.append(''.join(cur).strip())
    return fields

def clean_field(f):
    if f is None:
        return ""
    ff = f.strip()
    if ff == '':
        return ''
    if ff.lower() == 'null':
        return ''
    if ff.startswith("'") and ff.endswith("'") and len(ff) >= 2:
        inner = ff[1:-1]
        inner = inner.replace("''", "'")
        inner = inner.replace("\\'", "'")
        inner = inner.replace('\\\\', '\\')
        return inner
    if ff.startswith('"') and ff.endswith('"') and len(ff) >= 2:
        inner = ff[1:-1]
        inner = inner.replace('\\"', '"')
        return inner
    return ff

# ---------------------------
# SQL scanning
# ---------------------------
INSERT_RE = re.compile(
    r"INSERT\s+INTO\s+`?([A-Za-z0-9_]+)`?\s+VALUES\s*(\(.+?\))\s*;",
    flags=re.IGNORECASE | re.DOTALL
)

def extract_inserts(sql_text):
    inserts = []
    for m in INSERT_RE.finditer(sql_text):
        table = m.group(1)
        values_text = m.group(2)
        inserts.append((table, values_text))
    return inserts

# ---------------------------
# CSV writing helpers
# ---------------------------
def ensure_csv_writer(table, out_dir, header):
    path = os.path.join(out_dir, f"{table}.csv")
    exists = os.path.exists(path)
    f = open(path, "a", encoding="utf-8", newline='')
    writer = csv.writer(f, quoting=csv.QUOTE_MINIMAL)
    if not exists:
        writer.writerow(header)
    return f, writer

# ---------------------------
# Main processing
# ---------------------------
def process_sql_file(sql_path, out_dir):
    with open(sql_path, "r", encoding="utf-8") as f:
        sql_text = f.read()

    inserts = extract_inserts(sql_text)
    if not inserts:
        print("No INSERT INTO ... VALUES(...) ; blocks found in file.")
        return

    open_files = {}

    try:
        for table, values_text in inserts:
            header = HEADERS.get(table)
            tuples = split_top_level_tuples(values_text)
            if not tuples:
                print(f"Warning: no tuples parsed for table {table}. Skipping.")
                continue

            if header is None:
                first_fields = split_fields(tuples[0])
                header = [f"col{idx+1}" for idx in range(len(first_fields))]
                HEADERS[table] = header

            if table not in open_files:
                fh, writer = ensure_csv_writer(table, out_dir, header)
                open_files[table] = (fh, writer)
            else:
                fh, writer = open_files[table]

            for t in tuples:
                raw_fields = split_fields(t)
                cleaned = [clean_field(x) for x in raw_fields]
                if len(cleaned) < len(header):
                    cleaned += [''] * (len(header) - len(cleaned))
                elif len(cleaned) > len(header):
                    cleaned = cleaned[:len(header)]
                writer.writerow(cleaned)
    finally:
        for fh, _ in open_files.values():
            fh.close()

    print("Done. CSVs written to:", os.path.abspath(out_dir))

# ---------------------------
# CLI
# ---------------------------
def main():
    parser = argparse.ArgumentParser(description="Convert SQL INSERT ... VALUES(...) blocks into per-table CSV files.")
    parser.add_argument("sql_file", nargs='?', default="import.sql", help="Input SQL file (default: import.sql)")
    parser.add_argument("out_dir", nargs='?', default=".", help="Output directory for CSV files (default: current directory)")
    args = parser.parse_args()

    if not os.path.exists(args.sql_file):
        print("SQL file not found:", args.sql_file)
        sys.exit(1)
    os.makedirs(args.out_dir, exist_ok=True)
    process_sql_file(args.sql_file, args.out_dir)

if __name__ == "__main__":
    main()
