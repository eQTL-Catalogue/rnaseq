nextflow.enable.dsl=2

include { makeSalmonIndex; salmon_quant; salmon_merge } from '../modules/salmon'

workflow salmonQuant {
    take:
        fasta
        trimmed_reads

    main:
        makeSalmonIndex(fasta)
        salmon_quant(trimmed_reads, makeSalmonIndex.out)
        salmon_merge(salmon_quant.out.salmon_quantified.groupTuple())
}



