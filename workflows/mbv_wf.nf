nextflow.enable.dsl=2


include { run_mbv } from '../modules/utils'

workflow generate_mbv {
    take:
        bam_sorted_indexed

    main:
        Channel
            .fromPath(params.mbv_vcf)
            .ifEmpty { exit 1, "VCF file is not found to perform MBV: ${params.mbv_vcf}" }
            .set { mbv_vcf_ch }
        run_mbv(bam_sorted_indexed, mbv_vcf_ch.collect())
}


