#!/bin/bash

#SBATCH --time=120:00:00
#SBATCH -N 1
#SBATCH --ntasks-per-node=1
#SBATCH --mem=4G
#SBATCH --job-name="lc_test"
#SBATCH --partition=amd

# Load needed system tools (Java 8 is required, one of singularity or anaconda - python 2.7 is needed,
# depending on the method for dependancy management). The exact names of tool modules might depend on HPC.

module load any/jdk/1.8.0_265
module load nextflow
module load any/singularity/3.5.3
module load squashfs/4.4

nextflow run main_dsl2_test.nf\
 -profile tartu_hpc\
 --readPathsFile /gpfs/space/home/kerimov/rnaseq/data/readPathsFile_GEUVADIS_chr21_all.tsv\
 --unstranded\
 --hisat2_index /gpfs/space/projects/genomic_references/annotations/eQTLCatalogue/v0.1/hisat2_index_v96/Homo_sapiens.GRCh38.dna.primary_assembly\
 --aligner 'hisat2'\
 --skip_multiqc\
 --saveReference\
 --saveTrimmed\
 --saveAlignedIntermediates\
 --saveIndividualQuants\
 --run_leafcutter\
 --gtf /gpfs/space/projects/genomic_references/annotations/eQTLCatalogue/v0.1/gencode.v30.annotation.no_chr.gtf\
 --fasta /gpfs/space/projects/genomic_references/annotations/eQTLCatalogue/v0.1/Homo_sapiens.GRCh38.dna.primary_assembly.fa\
 --tx_fasta /gpfs/space/projects/genomic_references/annotations/eQTLCatalogue/v0.1/gencode.v30.transcripts.fa\
 --txrevise_gffs "/gpfs/space/projects/genomic_references/annotations/eQTLCatalogue/v0.1/Homo_sapiens.GRCh38.96.version_1/*.gff3"\
 --fasta /gpfs/space/projects/genomic_references/annotations/eQTLCatalogue/v0.1/Homo_sapiens.GRCh38.dna.primary_assembly.fa\
 -resume
