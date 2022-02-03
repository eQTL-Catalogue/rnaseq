nextflow.enable.dsl=2

Channel
    .fromPath( params.gtf )
    .ifEmpty { exit 1, "GTF annotation file not found: ${params.gtf}" }
    .set { gtf_file }

ch_biotypes_header = Channel.fromPath("$baseDir/assets/biotypes_header.txt")

include { featureCounts; merge_featureCounts } from '../modules/featureCounts'

workflow {
    count_features(bam_sorted_by_name)
}

workflow count_features {
    take:
        bam_sorted_by_name

    main:
        featureCounts(bam_sorted_by_name, gtf_file.collect(), ch_biotypes_header.collect())
        merge_featureCounts(featureCounts.out.gene_feature_counts.toSortedList())

    emit:
        gene_feature_counts = featureCounts.out.gene_feature_counts
}


