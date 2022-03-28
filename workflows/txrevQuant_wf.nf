nextflow.enable.dsl=2

Channel
    .fromPath( params.txrevise_gffs )
    .ifEmpty { exit 1, "TxRevise gff files not found : ${params.txrevise_gffs}" }
    .set { txrevise_gff_ch }

Channel
    .fromPath( params.fasta )
    .ifEmpty { exit 1, "Fasta (reference genome for txrevise) file not found: ${params.fasta}" }
    .set { genome_fasta_ch }

include { salmonQuant } from './salmon_wf'
include { gff_to_fasta } from '../modules/utils'

workflow {
    quant_txrev(trimmed_reads)
}

workflow quant_txrev {
    take:
        trimmed_reads

    main:
        gff_to_fasta(txrevise_gff_ch, genome_fasta_ch.collect())
        salmonQuant(gff_to_fasta.out, trimmed_reads)
}


