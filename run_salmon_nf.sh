nextflow run main.nf\
 --readPathsFile 'data/readPathsFile_BLUEPRINT_SE.tsv'\
 --singleEnd\
 --reverse_stranded\
 --hisat2_index /gpfs/hpc/home/a72094/annotations/GRCh38/hisat2_index_v90/Homo_sapiens.GRCh38.dna.primary_assembly\
 --salmon_index annotation/salmon_index/transcripts_from_original_fa.index\
 -profile tartu_hpc\
 --aligner 'hisat2'\
 --skip_qc\
 --gtf annotation/gtf/gencode.v29.annotation.gtf