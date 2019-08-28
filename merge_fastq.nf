#!/usr/bin/env nextflow

fastq_read_paths = Channel.from(params.readPaths)
// fastq_read_paths.subscribe {  println "Got: $it"  }

process merge_fastq{
    tag "${sample_id}"
    publishDir "${params.outdir}/merged_fastq/$sample_id/", mode: 'copy'
    memory '16 GB'
    cpus 1

    input:
    set read_pair, sample_id, fastq_files from fastq_read_paths

    output:
    file "${sample_id}_${read_pair}.fastq.gz"

    script:
    """
    zcat $fastq_files | gzip > ${sample_id}_${read_pair}.fastq.gz
    """
}

workflow.onComplete { 
	println ( workflow.success ? "Done!" : "Oops ... something went wrong" )
}






