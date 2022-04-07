nextflow.enable.dsl=2

process gff_to_fasta {
    tag "${txrevise_gff.baseName}"
    publishDir "${params.outdir}/Salmon/salmon_fasta", mode: 'copy', enabled: params.saveReference
    container = 'quay.io/eqtlcatalogue/rnaseq:v20.11.1'

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

process createBigWig {
    tag "${bam.simpleName}"
    publishDir "${params.outdir}/bigwig", mode: 'copy'
    container = 'quay.io/eqtlcatalogue/rnaseq:v20.11.1'

    input:
    tuple file(bam), file(bam_index)

    output:
    path "*.bigwig" 

    script:
    """
    bamCoverage -b $bam -p ${task.cpus} -bs 5 -o ${bam.simpleName}.bigwig
    """
}

process run_mbv {
    tag "${bam.simpleName}"
    publishDir "${params.outdir}/MBV", mode: 'copy'
    container = 'quay.io/eqtlcatalogue/qtltools:v22.03.1'

    input:
    tuple file(bam), file(bam_index)
    path vcf 

    output:
    path "${bam.simpleName}.mbv_output.txt"

    script:
    """
    QTLtools mbv --vcf $vcf --bam $bam --out ${bam.simpleName}.mbv_output.txt
    """
}

process sample_correlation {
    publishDir "${params.outdir}/sample_correlation", mode: 'copy'
    container = 'quay.io/eqtlcatalogue/rnaseq:v20.11.1'

    input:
    path input_files 
    path mdsplot_header
    path heatmap_header

    output:
    path "*.{txt,pdf,csv}" 

    script: // This script is bundled with the pipeline, in nfcore/rnaseq/bin/
    """
    edgeR_heatmap_MDS.r $input_files
    cat $mdsplot_header edgeR_MDS_Aplot_coordinates_mqc.csv >> tmp_file
    mv tmp_file edgeR_MDS_Aplot_coordinates_mqc.csv
    cat $heatmap_header log2CPM_sample_distances_mqc.csv >> tmp_file
    mv tmp_file log2CPM_sample_distances_mqc.csv
    """
}