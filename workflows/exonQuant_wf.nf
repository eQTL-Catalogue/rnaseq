nextflow.enable.dsl=2

Channel
    .fromPath( params.gtf )
    .ifEmpty { exit 1, "GTF annotation file not found: ${params.gtf}" }
    .set { gtf_file }

include { makeDexSeqExonGFF; count_exons; exon_count_merge } from '../modules/exon_quant'

workflow {
    quant_exons(bam_sorted_by_name)
}

workflow quant_exons {
    take:
        bam_sorted_by_name

    main:
        makeDexSeqExonGFF(gtf_file.collect())
        count_exons(bam_sorted_by_name, makeDexSeqExonGFF.out.collect())
        exon_count_merge(count_exons.out.toSortedList())
}


