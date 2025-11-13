nextflow.enable.dsl=2

include { makeSalmonIndex; salmon_quant; salmon_merge } from '../modules/salmon'

workflow salmonQuant {
    take:
        fasta
        trimmed_reads

    main:
        makeSalmonIndex(fasta)
        salmon_quant(trimmed_reads, makeSalmonIndex.out)
        grouped_salmon_quant = salmon_quant.out.salmon_quantified.groupTuple()
            .flatMap { index, groups, sample_ids, paths ->
                def groupedByGroup = [groups, sample_ids, paths].transpose().groupBy { it[0] }
                return groupedByGroup.collect { group, items ->
                def paired = items.collect { [it[1], it[2]] }
                    tuple(index, group, paired)
            }
        }
        grouped_salmon_quant_for_merge = grouped_salmon_quant
            .map { index, group, pairs ->
                 def paths = pairs.collect { it[1] }
                    tuple(index, group, paths)
        }
        salmon_merge(grouped_salmon_quant_for_merge)
}
