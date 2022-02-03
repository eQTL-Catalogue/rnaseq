nextflow.enable.dsl=2

process gff_to_fasta {
    tag "${txrevise_gff.baseName}"
    publishDir "${params.outdir}/Salmon/salmon_fasta", mode: 'copy', enabled: params.saveReference

    input:
    path txrevise_gff 
    path genome_fasta 

    output:
    path "${txrevise_gff.baseName}.fa" 
    
    script:
    """
    gffread -w ${txrevise_gff.baseName}.fa -g $genome_fasta $txrevise_gff
    """
}

process createBigWig {
    tag "${bam.simpleName}"
    publishDir "${params.outdir}/bigwig", mode: 'copy'

    input:
    tuple file(bam), file(bam_index)

    output:
    path "*.bigwig" 

    script:
    """
    bamCoverage -b $bam -p ${task.cpus} -o ${bam.simpleName}.bigwig
    """
}

process run_mbv {
    tag "${bam.simpleName}"
    publishDir "${params.outdir}/MBV", mode: 'copy'

    input:
    tuple file(bam), file(bam_index)
    path vcf 

    output:
    path "${bam.simpleName}.mbv_output.txt"

    script:
    """
    QTLtools mbv --vcf $vcf --bam $bam --out ${bam.simpleName}.mbv_output.txt
    """
}