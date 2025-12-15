#!/usr/bin/env python3
"""
Pivot psi_long table inside DuckDB and output final *.tsv.gz.

Input:
    --duckdb psi.duckdb
    --output result.tsv.gz
"""

import argparse
import duckdb

parser = argparse.ArgumentParser()
parser.add_argument("--duckdb", required=True, help="Input DuckDB file from merge step")
parser.add_argument("--output", required=True, help="Output TSV")
parser.add_argument("--memory_limit", default="8", help="DuckDB memory limit (e.g. '8', '20')")
args = parser.parse_args()

memory_limit = f"{float(args.memory_limit) * 0.9:.1f}"

con = duckdb.connect(args.duckdb)
con.execute("SET preserve_insertion_order=FALSE")
con.execute(f"SET memory_limit='{memory_limit}GB'")
con.execute("PRAGMA temp_directory='./duckdb_tmp'")



sample_ids = [row[0] for row in con.execute(
    "SELECT DISTINCT sample_id FROM psi_long"
).fetchall()]


if not sample_ids:
    raise ValueError("No sample_id values found in psi_long")

pivot_cols = ", ".join(f'"{sid}"' for sid in sample_ids)

pivot_sql = f"""
COPY (
    SELECT *
    FROM psi_long
    PIVOT (MAX(psi) FOR sample_id IN ({pivot_cols}))
) TO '{args.output}' (DELIMITER '\t', HEADER, COMPRESSION gzip)
"""

con.execute(pivot_sql)
con.close()

print(f"Pivot complete → {args.output}")