nextflow.enable.dsl=2

Channel
    .fromPath( params.gtf_fc )
    .ifEmpty { exit 1, "GTF annotation file for featureCounts not found: ${params.gtf_fc}" }
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
        sample_grouped_featureCounts = featureCounts.out.gene_feature_counts.groupTuple()
            .map { grouped ->
                def (group, sample_ids, paths) = grouped
                def paired = [sample_ids, paths].transpose().sort { it[0] }
            tuple(group, paired)
        }
        sample_grouped_featureCounts.view()
        grouped_featureCounts_for_merge = sample_grouped_featureCounts.map { group, samples ->
            def paths = samples.collect { it[1] }
        tuple(group, paths)
        }
        grouped_featureCounts_for_merge.view()
        merge_featureCounts(grouped_featureCounts_for_merge)

    emit:
        gene_feature_counts = featureCounts.out.gene_feature_counts
}


