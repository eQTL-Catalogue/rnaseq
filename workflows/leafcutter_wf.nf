nextflow.enable.dsl=2

include { bam_to_junc; cluster_introns} from '../modules/leafcutter'
include { collect_lc_junctions_per_group} from '../modules/utils'

workflow quant_leafcutter {
    take:
        bam_sorted_indexed
    
    main:
        bam_to_junc(bam_sorted_indexed)
        grouped_juncs = bam_to_junc.out.junc
            .groupTuple()
            .map { sample_group, sample_ids, paths ->
            tuple(sample_group, paths)
        }
        collect_lc_junctions_per_group(grouped_juncs)
        cluster_introns(collect_lc_junctions_per_group.out)
}

