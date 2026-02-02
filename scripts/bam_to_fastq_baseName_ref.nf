#!/usr/bin/env nextflow
nextflow.enable.dsl = 1
bams = Channel.fromPath(params.bamsPath)
ref = file(params.fasta_ref)


process bam_to_fastq{
    tag "${bam_file.baseName}"
    publishDir "${params.outdir}/bam_to_fastq_results/", mode: 'copy'
    memory '8 GB'
    cpus 2
    container = 'quay.io/eqtlcatalogue/rnaseq:v20.11.1'
    time = '8.h'

    input:
    file bam_file from bams
    file fasta_ref from ref

    output:
    file "${bam_file.baseName}_1.fastq.gz"
    file "${bam_file.baseName}_2.fastq.gz"

    script:
    """
    samtools collate --reference $fasta_ref $bam_file ${bam_file.baseName}.collated
    samtools fastq -F 2816 -c 6 --reference $fasta_ref -1 ${bam_file.baseName}_1.fastq.gz -2 ${bam_file.baseName}_2.fastq.gz ${bam_file.baseName}.collated.bam
    """
}

workflow.onComplete { 
	println ( workflow.success ? "Done!" : "Oops ... something went wrong" )
}






