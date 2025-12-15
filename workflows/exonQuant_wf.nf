nextflow.enable.dsl=2

Channel
    .fromPath( params.gtf_fc )
    .ifEmpty { exit 1, "GTF annotation file for featureCounts not found: ${params.gtf_fc}" }
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
        sample_grouped_exonCounts = count_exons.out.exon_counts.groupTuple()
            .map { grouped ->
                def (group, sample_ids, paths) = grouped
                def paired = [sample_ids, paths].transpose().sort { it[0] }
            tuple(group, paired)
        }
        grouped_exonCounts_for_merge = sample_grouped_exonCounts.map { group, samples ->
            def paths = samples.collect { it[1] }
                tuple(group, paths)
        }
        exon_count_merge(grouped_exonCounts_for_merge)
}


