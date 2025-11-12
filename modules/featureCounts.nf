nextflow.enable.dsl=2

process featureCounts {
    tag "${sample_id}"
    publishDir "${params.outdir}/featureCounts/biotype_counts", mode: 'copy', pattern: "${sample_id}_biotype_counts*mqc.{txt,tsv}", enabled: params.saveInfoLogs
    publishDir "${params.outdir}/featureCounts/gene_count_summaries", mode: 'copy', pattern: "*_gene.featureCounts.txt.summary", enabled: params.saveInfoLogs
    publishDir "${params.outdir}/featureCounts/gene_counts", mode: 'copy', pattern: "*_gene.featureCounts.txt", enabled: params.saveIndividualQuants
    container = 'quay.io/eqtlcatalogue/rnaseq:v20.11.1'

    input:
    //path bam_featurecounts_sorted
    tuple val(sample_group), val(sample_id), path(bam_featurecounts_sorted)
    path gtf 
    path biotypes_header

    output:
    tuple val(sample_group), val(sample_id), path("${sample_id}_gene.featureCounts.txt"), emit: gene_feature_counts
    path "${sample_id}_gene.featureCounts.txt.summary"
    path "${sample_id}_biotype_counts*mqc.{txt,tsv}"

    script:
    def featureCounts_direction = 0
    def extraAttributes = params.fcExtraAttributes ? "--extraAttributes ${params.fcExtraAttributes}" : ''
    if (params.forward_stranded && !params.unstranded) {
        featureCounts_direction = 1
    } else if (params.reverse_stranded && !params.unstranded){
        featureCounts_direction = 2
    }
    // Can I remove this baseName naming?
    """
    mv $bam_featurecounts_sorted ${sample_id}.bam
    featureCounts -a $gtf -g gene_id --donotsort -o ${sample_id}_gene.featureCounts.txt $extraAttributes -p -s $featureCounts_direction ${sample_id}.bam
    featureCounts -a $gtf -g gene_type --donotsort -o ${sample_id}_biotype.featureCounts.txt -p -s $featureCounts_direction ${sample_id}.bam
    cut -f 1,7 ${sample_id}_biotype.featureCounts.txt | tail -n +3 | cat $biotypes_header - >> ${sample_id}_biotype_counts_mqc.txt
    mqc_features_stat.py ${sample_id}_biotype_counts_mqc.txt -s $sample_id -f rRNA -o ${sample_id}_biotype_counts_gs_mqc.tsv
    """
}

process merge_featureCounts {
    tag "merge ${sample_group} ${input_files.size()} files"
    publishDir "${params.outdir}/featureCounts/${sample_group}", mode: 'copy'
    container = 'quay.io/eqtlcatalogue/rnaseq:v20.11.1'

    input:
    tuple val(sample_group), path(input_files)

    output:
    path "${sample_group}_merged_gene_counts.tsv.gz"

    script:
    """
    paste -d"\t" $input_files > ${sample_group}_merged_raw_all.tsv
    
    csvtk cut -t -f 1 ${sample_group}_merged_raw_all.tsv | \
    csvtk rename -t -f Geneid -n phenotype_id > ${sample_group}_phenotype_ids_column.tsv

    csvtk cut -t -F -f "*.bam" ${sample_group}_merged_raw_all.tsv | sed 's/.bam//g' > ${sample_group}_merged_genes_no_phenotype_id.tsv
    paste -d"\t" ${sample_group}_phenotype_ids_column.tsv ${sample_group}_merged_genes_no_phenotype_id.tsv | gzip -c > ${sample_group}_merged_gene_counts.tsv.gz
    """
}