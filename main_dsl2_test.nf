#!/usr/bin/env nextflow
nextflow.enable.dsl=2

workflow {
    include {align_reads} from './workflows/align_wf'
    include {count_features} from './workflows/featureCounts_wf'

    align_reads()
    count_features(align_reads.out.bam_sorted_by_name)

    if (params.run_exon_quant) {
        include {quant_exons} from './workflows/exonQuant_wf'
        quant_exons(align_reads.out.bam_sorted_by_name)
    }

    if (params.run_salmon) {
        include {quant_tx} from './workflows/txQuant_wf'
        quant_tx(align_reads.out.trimmed_reads)
    }

    if (params.run_txrevise) {
        include {quant_txrev} from './workflows/txrevQuant_wf'
        quant_txrev(align_reads.out.trimmed_reads)
    }
}