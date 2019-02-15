nextflow run main.nf/
 --reads 'data/*{1,2}.fastq.gz'/
 --reverse_stranded/
 --hisat2_index /gpfs/hpchome/a72094/rocket/annotations/GRCh38/hisat2_index_v90/Homo_sapiens.GRCh38.dna.primary_assembly/
 --salmon_index salmon_index/transcripts_from_original_fa.index
 -profile tartu_hpc