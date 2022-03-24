nextflow.enable.dsl=2

Channel
    .fromPath(params.tx_fasta)
    .ifEmpty { exit 1, "Transcript fasta file is unreachable: ${params.tx_fasta}" }
    .set { tx_fasta_ch }

include { salmonQuant } from './salmon_wf.nf'

workflow {
    quant_tx(trimmed_reads)
}

workflow quant_tx {
    take:
        trimmed_reads

    main:
        salmonQuant(tx_fasta_ch, trimmed_reads)
}


