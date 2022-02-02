nextflow run main_dsl2_test.nf\
 -profile tartu_hpc\
 --readPathsFile /gpfs/space/home/kerimov/rnaseq/data/readPathsFile_macrophages_PE_smoke.tsv\
 --reverse_stranded\
 --hisat2_index /gpfs/space/projects/genomic_references/annotations/eQTLCatalogue/v0.1/hisat2_index_v96/Homo_sapiens.GRCh38.dna.primary_assembly\
 --aligner 'hisat2'\
 --skip_qc\
 --skip_multiqc\
 --skip_stringtie\
 --saveReference\
 --saveTrimmed\
 --saveAlignedIntermediates\
 --gtf /gpfs/space/projects/genomic_references/annotations/eQTLCatalogue/v0.1/gencode.v30.annotation.no_chr.gtf\
 --fasta /gpfs/space/projects/genomic_references/annotations/eQTLCatalogue/v0.1/Homo_sapiens.GRCh38.dna.primary_assembly.fa\
 --tx_fasta /gpfs/space/projects/genomic_references/annotations/eQTLCatalogue/v0.1/gencode.v30.transcripts.fa\
 

