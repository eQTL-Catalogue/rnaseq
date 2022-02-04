#!/usr/bin/env nextflow
nextflow.enable.dsl=2

workflow {
    include {align_reads} from './workflows/align_wf'

    align_reads()
    
    if (params.run_ge_quant){
        include {count_features} from './workflows/featureCounts_wf'
        count_features(align_reads.out.bam_sorted_by_name)
    }

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

    if (params.run_leafcutter) {
        include {quant_leafcutter} from './workflows/leafcutter_wf'
        quant_leafcutter(align_reads.out.bam_sorted_indexed)
    }

    if (params.generate_bigwig) {
        include { createBigWig } from './modules/utils'
        createBigWig(align_reads.out.bam_sorted_indexed)
    }

    if (params.run_mbv){
        include { generate_mbv } from './workflows/mbv_wf'
        generate_mbv(align_reads.out.bam_sorted_indexed)
    }

    if (params.run_sample_corr && params.run_ge_quant) { 
        include { sample_correlation } from './modules/utils'
        sample_correlation(count_features.out.gene_feature_counts.collect(),
                            Channel.fromPath("$baseDir/assets/mdsplot_header.txt"),
                            Channel.fromPath("$baseDir/assets/heatmap_header.txt"))
    }
}