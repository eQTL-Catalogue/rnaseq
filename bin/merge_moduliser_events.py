#!/usr/bin/env python3

import argparse
import polars as pl

parser = argparse.ArgumentParser()
parser.add_argument("--files", nargs="+", required=True)
parser.add_argument("--event", required=True)
parser.add_argument("--output", required=True)
args = parser.parse_args()

event_files = args.files
event = args.event
output = args.output

def scan_event_file(f:str, cols:list[str]):
    return (
        pl.scan_csv(
            f,
            separator="\t",
            comment_prefix="#",
            has_header=True,
            infer_schema_length=0,
            schema_overrides={c: pl.Utf8 for c in cols},
        )
        .select(cols)
        .drop_nulls("lsv_id")
        .unique()
    )

def get_event_columns(event_name:str):
    if event_name in ['tandem_cassette', 'multi_exon_spanning']:
        cols = ['lsv_id', 'event_id', 'junction_coord', 'spliced_with_coord',
                    'reference_exon_coord', 'junction_name', 'exons_skipped_coords',
                    'num_skipped_exons']
    elif event_name  == 'junctions':
        cols = ['lsv_id', 'junction_coord', 'denovo']
    else:
        cols = ['lsv_id', 'event_id', 'junction_coord', 'spliced_with_coord',
                        'reference_exon_coord', 'junction_name']
    return cols


def main(event_files:list[str], event_name:str, output:str):
    cols = get_event_columns(event_name)
    lazy_scans = [scan_event_file(f, cols) for f in event_files]
    merged_lazy = pl.concat(lazy_scans, how="vertical").unique()
    merged = merged_lazy.collect(streaming=True)
    merged.write_csv(f"{output}", separator="\t")


if __name__ == "__main__":
    main(event_files,event,output)