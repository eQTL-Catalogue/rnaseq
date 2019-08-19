#!/usr/bin/env nextflow
bams = Channel.fromPath(params.bamsPath)

process bam_to_fastq{
    tag "${bam_file.simpleName}"
    publishDir "${params.outdir}/bam_to_fastq_results/"
    memory '4 GB'
    cpus 2

    input:
    file bam_file from bams

    output:
    file "${bam_file.simpleName}_1.fastq.gz"
    file "${bam_file.simpleName}_2.fastq.gz"

    script:
    """
    samtools collate $bam_file ${bam_file.simpleName}.collated
    samtools fastq -F 2816 -c 6 -1 ${bam_file.simpleName}_1.fastq.gz -2 ${bam_file.simpleName}_2.fastq.gz ${bam_file.simpleName}.collated.bam
    """
}

workflow.onComplete { 
	println ( workflow.success ? "Done!" : "Oops ... something went wrong" )
}






