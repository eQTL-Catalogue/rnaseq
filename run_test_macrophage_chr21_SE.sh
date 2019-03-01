nextflow run main.nf\
 -profile tartu_hpc\
 --readPathsFile 'data/readPathsFile_macrophages_SE.tsv'\
 --singleEnd\
 --reverse_stranded\
 --hisat2_index /gpfs/hpc/home/a72094/annotations/GRCh38/hisat2_index_v90/Homo_sapiens.GRCh38.dna.primary_assembly\
 --aligner 'hisat2'\
 --skip_qc\
 --skip_skip_multiqc\
 --saveReference\
 --saveTrimmed\
 --saveAlignedIntermediates\
 --gtf annotation/gtf/gencode.v29.annotation.gtf\
 --fasta annotation/GRCh38/Homo_sapiens.GRCh38.dna.primary_assembly.fa\
 --txrevise_gffs 'annotation/txrevise_gff/*.gff3'\
 # -resume