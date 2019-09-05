Channel
    .fromPath(params.mbv_vcf)
    .ifEmpty { exit 1, "VCF file is not found to perform MBV: ${params.mbv_vcf}" }
    .set { mbv_vcf_ch }

Channel
    .fromPath(params.bamsDir)
    .ifEmpty { exit 1, "There are no BAM files in directory: ${params.bamsDir}" }
    .set { mbv_bam }


process run_mbv {
    tag "${mbv_bam.simpleName}"
    publishDir "${params.outdir}/MBV", mode: 'copy'

    input:
    file mbv_bam
    file vcf from mbv_vcf_ch.collect()

    output:
    file "${mbv_bam.simpleName}.mbv_output.txt"

    script:
    """
    samtools index $mbv_bam
    QTLtools mbv --vcf $vcf --bam $mbv_bam --out ${mbv_bam.simpleName}.mbv_output.txt
    """
}