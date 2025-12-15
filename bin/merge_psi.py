#!/usr/bin/env python3


import argparse
import duckdb
import os

parser = argparse.ArgumentParser()
parser.add_argument("--sample-ids", nargs="+", required=True)
parser.add_argument("--psi-files", nargs="+", required=True)
parser.add_argument("--db", required=True)
args = parser.parse_args()

sample_ids = args.sample_ids
psi_files = args.psi_files
db_path = args.db

if len(sample_ids) != len(psi_files):
    raise ValueError("sample-ids and psi-files must have same length")

con = duckdb.connect(db_path)

con.execute("DROP TABLE IF EXISTS psi_long")
con.execute("""
CREATE TABLE psi_long (
    phenotype_id TEXT,
    sample_id TEXT,
    psi DOUBLE
)
""")

schema = """
    delim='\t',
    header=true,
    auto_detect=false,
    columns={
        'seqid':'VARCHAR',
        'strand':'VARCHAR',
        'gene_name':'VARCHAR',
        'gene_id':'VARCHAR',
        'event_type':'VARCHAR',
        'ref_exon_start':'VARCHAR',
        'ref_exon_end':'VARCHAR',
        'start':'VARCHAR',
        'end':'VARCHAR',
        'is_intron':'BOOLEAN',
        'other_exon_start':'INT',
        'other_exon_end':'INT',
        'is_denovo':'BOOLEAN',
        'ref_exon_denovo':'BOOLEAN',
        'other_exon_denovo':'BOOLEAN',
        'event_denovo':'BOOLEAN',
        'bootstrap_psi_std':'DOUBLE',
        'raw_coverage':'DOUBLE',
        'raw_psi_mean':'DOUBLE',
        'raw_psi_std':'DOUBLE'
    },
    nullstr='',
    ignore_errors=true

"""

for sid, path in zip(sample_ids, psi_files):
    abs_path = os.path.abspath(path)
    print(f"Loading sample {sid}: {abs_path}")

    sql = f"""
    INSERT INTO psi_long
    SELECT
        gene_id || ':' || event_type || ':' || ref_exon_start || '-' || ref_exon_end || ':' ||
        start || '-' || "end" AS phenotype_id,
        '{sid}' AS sample_id,
        raw_psi_mean AS psi
    FROM read_csv('{abs_path}', {schema})
    """

    con.execute(sql)

con.close()
print(f"Done. Created psi_long in {db_path}.")