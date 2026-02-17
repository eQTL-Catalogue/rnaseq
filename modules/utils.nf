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
    tag "${sample_id}"
    publishDir "${params.outdir}/${sample_group}/bigwig", mode: 'copy'
    container = 'quay.io/eqtlcatalogue/rnaseq:v20.11.1'

    input:
    tuple val(sample_group), val(sample_id), file(bam), file(bam_index)

    output:
    tuple val(sample_group), val(sample_id), path("${sample_id}.bigwig")

    script:
    """
    bamCoverage -b $bam -p ${task.cpus} -bs 5 -o ${sample_id}.bigwig
    """
}

process run_mbv {
    tag "${sample_id}"
    publishDir "${params.outdir}/${sample_group}/MBV", mode: 'copy'
    container = 'quay.io/eqtlcatalogue/qtltools:v22.03.1'

    input:
    tuple val(sample_group), val(sample_id), file(bam), file(bam_index)
    path vcf 

    output:
    tuple val(sample_group), val(sample_id), path("${sample_id}.mbv_output.txt")

    script:
    """
    QTLtools mbv --vcf $vcf --bam $bam --out ${sample_id}.mbv_output.txt
    """
}

process sample_correlation {
    publishDir "${params.outdir}/${sample_group}/sample_correlation", mode: 'copy'
    container = 'quay.io/eqtlcatalogue/rnaseq:v20.11.1'

    input:
    tuple val(sample_group), path(input_files)
    path mdsplot_header
    path heatmap_header

    output:
    path "*.{txt,pdf,csv}" 

    script: // This script is bundled with the pipeline, in nfcore/rnaseq/bin/
    """
    edgeR_heatmap_MDS.r ${sample_group} $input_files
    cat $mdsplot_header edgeR_MDS_Aplot_coordinates_mqc_${sample_group}.csv >> tmp_file
    mv tmp_file edgeR_MDS_Aplot_coordinates_mqc_${sample_group}.csv
    cat $heatmap_header log2CPM_sample_distances_mqc_${sample_group}.csv >> tmp_file
    mv tmp_file log2CPM_sample_distances_mqc_${sample_group}.csv
    
    """
}

process collect_lc_junctions_per_group {
    container = 'quay.io/eqtlcatalogue/rnaseq:v20.11.1'

    input:
    tuple val(sample_group), val(junc_files)

    output:
    tuple val(sample_group), path("${sample_group}_junction_files.txt")

    script:
    """
    # Create a file listing all .junc paths for this group
    printf "%s\\n" ${junc_files.join(' ')} > ${sample_group}_junction_files.txt
    """
}