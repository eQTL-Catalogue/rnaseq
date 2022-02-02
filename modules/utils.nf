nextflow.enable.dsl=2

process gff_to_fasta {
    tag "${txrevise_gff.baseName}"
    publishDir "${params.outdir}/Salmon/salmon_fasta", mode: 'copy', enabled: params.saveReference

    input:
    path txrevise_gff 
    path genome_fasta 

    output:
    path "${txrevise_gff.baseName}.fa" 
    
    script:
    """
    gffread -w ${txrevise_gff.baseName}.fa -g $genome_fasta $txrevise_gff
    """
}