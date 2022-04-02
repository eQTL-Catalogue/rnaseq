#!/bin/bash

#SBATCH --time=30:00:00
#SBATCH -N 1
#SBATCH --ntasks-per-node=1
#SBATCH --mem=4G
#SBATCH --job-name="rnaseq_test"
#SBATCH --partition=amd

module load any/jdk/1.8.0_265
module load nextflow
module load any/singularity/3.7.3
module load squashfs/4.4

nextflow run main.nf -profile test,tartu_hpc -resume


