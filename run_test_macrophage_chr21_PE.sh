#!/bin/bash

#SBATCH --time=05:00:00
#SBATCH -N 1
#SBATCH --ntasks-per-node=1
#SBATCH --mem=4G
#SBATCH --job-name="rnaseq_SE"
#SBATCH --partition=amd

# Load needed system tools (Java 8 is required, one of singularity or anaconda - python 2.7 is needed,
# depending on the method for dependancy management). The exact names of tool modules might depend on HPC.

module load any/jdk/1.8.0_265
module load nextflow
module load any/singularity/3.5.3
module load squashfs/4.4

nextflow run main_dsl2_test.nf\
 -profile eqtl_catalogue\
 --readPathsFile data/readPathsFile_macrophages_PE.tsv\
 --reverse_stranded\
 --skip_multiqc\
 --saveReference\
 --saveTrimmed\
 --saveAlignedIntermediates\
 --saveIndividualQuants\
 --outdir results/test_PE_results2\
 -resume

